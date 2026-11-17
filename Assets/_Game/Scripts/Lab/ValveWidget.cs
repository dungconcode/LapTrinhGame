using System;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Underlab.Lab
{
    /// <summary>
    /// Bình khí + van + ống đo khí.
    ///   Nhấn giữ núm van rồi kéo LÊN để mở, kéo XUỐNG để khoá (nhả chuột van giữ nguyên độ mở).
    ///   Lưu lượng ~ (độ mở)² => mở nhẹ chảy rất chậm, mở to chảy rất nhanh.
    ///   Khoá van rồi khí vẫn chảy thêm một chút (quán tính) => phải khoá TRƯỚC khi đủ.
    ///   Mở quá to quá lâu => áp suất vượt => xì khí => thất bại.
    /// </summary>
    public class ValveWidget
    {
        public float Dispensed { get; private set; }   // lít đã nạp vào ống đo
        public float Open { get; private set; }

        /// <summary>Gọi khi xì khí (quá áp). Tham số = số lít mất.</summary>
        public event Action<float> OverPressure;

        private readonly LabConfig cfg;
        private readonly Func<float> getStock;
        private readonly Action<float> useStock;
        private readonly string gas;
        private readonly RectTransform knob;
        private readonly TextMeshProUGUI stockText, flowText, meterText, openText;
        private readonly Image pressureFill, meterFill, knobImg;
        private readonly float meterMax;
        private float flow, overTimer;
        private bool dragging;
        private float dragStartY, dragStartOpen;

        public ValveWidget(Transform parent, Vector2 pos, LabConfig cfg, string gas, Func<float> getStock,
                           Action<float> useStock, float meterMax = 60f)
        {
            this.cfg = cfg;
            this.gas = gas;
            this.getStock = getStock;
            this.useStock = useStock;
            this.meterMax = meterMax;

            var root = LabUi.Img(parent, "Valve_" + gas, "ui_panel", new Vector2(0, 1), pos, new Vector2(330, 420), null, null, true, 2f).transform;
            LabUi.Txt(root, "Title", $"BÌNH KHÍ {Chem.F(gas)}", 18, LabUi.Teal, TextAlignmentOptions.TopLeft,
                new Vector2(0, 1), new Vector2(18, -14), new Vector2(300, 26));

            // Bình
            LabUi.Img(root, "Tank", "ui_depth_meter", new Vector2(0, 1), new Vector2(22, -50), new Vector2(60, 300), null, new Color(0.6f, 0.85f, 1f));
            stockText = LabUi.Txt(root, "Stock", "", 14, LabUi.Dim, TextAlignmentOptions.TopLeft,
                new Vector2(0, 1), new Vector2(18, -356), new Vector2(140, 40));

            // Núm van
            knobImg = LabUi.Img(root, "Knob", "ui_wave_timer", new Vector2(0, 1), new Vector2(150, -60), new Vector2(90, 90));
            knob = knobImg.rectTransform;
            knob.pivot = new Vector2(0.5f, 0.5f);
            knob.anchoredPosition = new Vector2(195, -105);
            openText = LabUi.Txt(root, "Open", "", 15, Color.white, TextAlignmentOptions.Top,
                new Vector2(0, 1), new Vector2(135, -155), new Vector2(120, 22));
            LabUi.Txt(root, "KnobHint", "Giữ núm, kéo lên = mở\nkéo xuống = khoá", 13, LabUi.Dim, TextAlignmentOptions.Top,
                new Vector2(0, 1), new Vector2(115, -178), new Vector2(160, 40));

            // Áp suất
            LabUi.Txt(root, "PLabel", "Áp suất", 13, LabUi.Dim, TextAlignmentOptions.Left,
                new Vector2(0, 1), new Vector2(110, -224), new Vector2(80, 20));
            var pFrame = LabUi.Img(root, "PFrame", "ui_bar_frame", new Vector2(0, 1), new Vector2(110, -246), new Vector2(200, 20), null, null, true, 4f);
            pressureFill = LabUi.Img(pFrame.transform, "PFill", "ui_bar_fill", new Vector2(0, 0.5f), new Vector2(4, 0), new Vector2(192, 12), new Vector2(0, 0.5f));
            pressureFill.type = Image.Type.Filled;
            pressureFill.fillMethod = Image.FillMethod.Horizontal;
            LabUi.Img(pFrame.transform, "RedZone", null, new Vector2(0, 0.5f), new Vector2(4 + 192 * cfg.overPressureOpen * cfg.overPressureOpen, 0),
                new Vector2(2, 20), new Vector2(0, 0.5f), LabUi.Red);
            flowText = LabUi.Txt(root, "Flow", "", 14, Color.white, TextAlignmentOptions.Left,
                new Vector2(0, 1), new Vector2(110, -270), new Vector2(200, 20));

            // Ống đo khí (vạch mỗi 5 L, không có vạch mục tiêu)
            LabUi.Txt(root, "MLabel", $"Ống đo khí (0–{meterMax:0} L)", 13, LabUi.Dim, TextAlignmentOptions.Left,
                new Vector2(0, 1), new Vector2(110, -298), new Vector2(200, 20));
            var mFrame = LabUi.Img(root, "MFrame", "ui_bar_frame", new Vector2(0, 1), new Vector2(110, -320), new Vector2(200, 26), null, null, true, 4f);
            meterFill = LabUi.Img(mFrame.transform, "MFill", "ui_bar_fill", new Vector2(0, 0.5f), new Vector2(4, 0), new Vector2(192, 16), new Vector2(0, 0.5f), new Color(0.6f, 0.85f, 1f));
            meterFill.type = Image.Type.Filled;
            meterFill.fillMethod = Image.FillMethod.Horizontal;
            for (float v = 5; v < meterMax; v += 5)
                LabUi.Img(mFrame.transform, "Tick", null, new Vector2(0, 0.5f), new Vector2(4 + 192 * v / meterMax, 0),
                    new Vector2(v % 10 == 0 ? 2 : 1, v % 10 == 0 ? 22 : 14), new Vector2(0.5f, 0.5f), new Color(1, 1, 1, 0.6f));
            meterText = LabUi.Txt(root, "Meter", "", 22, LabUi.Green, TextAlignmentOptions.Left,
                new Vector2(0, 1), new Vector2(110, -350), new Vector2(200, 30));
            LabUi.Btn(root, "Xả bỏ khí", new Vector2(0, 1), new Vector2(200, -386), new Vector2(110, 28), Vent, null, 14);
        }

        public void Tick(float dt)
        {
            // Kéo núm
            if (LabUi.LeftDown && LabUi.Over(knob))
            {
                dragging = true;
                dragStartY = LabUi.MousePos.y;
                dragStartOpen = Open;
            }
            if (dragging)
            {
                if (!LabUi.LeftHeld) dragging = false;
                else Open = Mathf.Clamp01(dragStartOpen + (LabUi.MousePos.y - dragStartY) / 220f);
            }

            // Lưu lượng có quán tính
            float target = cfg.maxFlow * Open * Open;
            float k = cfg.valveInertia > 0 ? 1f - Mathf.Exp(-dt / cfg.valveInertia) : 1f;
            flow = Mathf.Lerp(flow, target, k);
            if (Open <= 0.001f && flow < 0.02f) flow = 0f;
            float amount = Mathf.Min(flow * dt, getStock());
            if (amount > 0f)
            {
                useStock(amount);
                Dispensed += amount;
            }
            if (getStock() <= 0.001f) flow = 0f;

            // Quá áp
            if (Open > cfg.overPressureOpen && flow > 0.1f) overTimer += dt; else overTimer = 0f;
            if (overTimer >= cfg.overPressureSeconds)
            {
                float lost = Dispensed;
                Dispensed = 0f;
                Open = 0f;
                flow = 0f;
                overTimer = 0f;
                dragging = false;
                OverPressure?.Invoke(lost);
            }

            // Hiển thị
            knob.localEulerAngles = new Vector3(0, 0, -Open * 270f);
            knobImg.color = Open > cfg.overPressureOpen ? LabUi.Red : Color.white;
            openText.text = $"Mở {Open * 100f:0}%";
            float p = Open * Open;
            pressureFill.fillAmount = p;
            pressureFill.color = Open > cfg.overPressureOpen ? LabUi.Red : Color.Lerp(LabUi.Green, LabUi.Gold, p);
            flowText.text = $"Lưu lượng: {flow:0.0} L/s";
            meterFill.fillAmount = Mathf.Clamp01(Dispensed / meterMax);
            meterText.text = $"{Dispensed:0.0} L";
            stockText.text = $"Còn {getStock():0.0} L";
        }

        /// <summary>Lấy hết khí trong ống đo (phản ứng dùng / thất bại mất).</summary>
        public float TakeAll()
        {
            float v = Dispensed;
            Dispensed = 0f;
            return v;
        }

        public void CloseValve()
        {
            Open = 0f;
            dragging = false;
        }

        private void Vent()
        {
            Dispensed = 0f;
        }
    }
}
