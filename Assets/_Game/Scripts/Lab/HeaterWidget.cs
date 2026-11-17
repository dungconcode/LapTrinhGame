using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Underlab.Lab
{
    /// <summary>
    /// Lò nung có núm chỉnh lửa + nhiệt kế.
    ///   Nhấn giữ núm, kéo lên = to lửa, kéo xuống = nhỏ lửa.
    ///   Nhiệt độ đuổi theo mức lửa CÓ ĐỘ TRỄ (vài giây) => phải chỉnh trước, không chờ thấy mới chỉnh.
    ///   Phản ứng toả nhiệt cộng thêm nhiệt (extraHeat) => đang phản ứng phải giảm lửa.
    /// Vùng xanh trên nhiệt kế = vùng tốt; vạch đỏ = giới hạn hỏng.
    /// </summary>
    public class HeaterWidget
    {
        public float Temp { get; private set; } = 25f;
        public float Power { get; private set; }

        private readonly LabConfig cfg;
        private readonly RectTransform knob;
        private readonly Image knobImg, tempFill;
        private readonly TextMeshProUGUI tempText, powerText;
        private readonly float scaleMax;
        private bool dragging;
        private float dragY, dragPower;

        public HeaterWidget(Transform parent, Vector2 pos, LabConfig cfg, Vector2 good, Vector2 fail, float scaleMax = 700f)
        {
            this.cfg = cfg;
            this.scaleMax = scaleMax;
            var root = LabUi.Rect(parent, "Heater", new Vector2(0, 1), pos, new Vector2(300, 120));
            knobImg = LabUi.Img(root, "Knob", "ui_wave_timer", new Vector2(0, 1), new Vector2(0, 0), new Vector2(70, 70));
            knob = knobImg.rectTransform;
            knob.pivot = new Vector2(0.5f, 0.5f);
            knob.anchoredPosition = new Vector2(35, -35);
            powerText = LabUi.Txt(root, "Power", "", 13, LabUi.Dim, TextAlignmentOptions.Top,
                new Vector2(0, 1), new Vector2(-10, -72), new Vector2(90, 34));

            var frame = LabUi.Img(root, "TFrame", "ui_bar_frame", new Vector2(0, 1), new Vector2(84, -10), new Vector2(210, 24), null, null, true, 4f);
            tempFill = LabUi.Img(frame.transform, "TFill", "ui_bar_fill", new Vector2(0, 0.5f), new Vector2(4, 0), new Vector2(202, 14), new Vector2(0, 0.5f));
            tempFill.type = Image.Type.Filled;
            tempFill.fillMethod = Image.FillMethod.Horizontal;
            float x0 = 4 + 202 * good.x / scaleMax, x1 = 4 + 202 * good.y / scaleMax;
            LabUi.Img(frame.transform, "Good", null, new Vector2(0, 0.5f), new Vector2(x0, 0), new Vector2(x1 - x0, 22), new Vector2(0, 0.5f), new Color(0.45f, 0.95f, 0.5f, 0.35f));
            foreach (float f in new[] { fail.x, fail.y })
                LabUi.Img(frame.transform, "Fail", null, new Vector2(0, 0.5f), new Vector2(4 + 202 * f / scaleMax, 0), new Vector2(2, 24), new Vector2(0.5f, 0.5f), LabUi.Red);
            tempText = LabUi.Txt(root, "Temp", "", 22, Color.white, TextAlignmentOptions.Left,
                new Vector2(0, 1), new Vector2(84, -40), new Vector2(210, 30));
            LabUi.Txt(root, "Hint", "Giữ núm: kéo lên = to lửa", 12, LabUi.Dim, TextAlignmentOptions.Left,
                new Vector2(0, 1), new Vector2(84, -72), new Vector2(210, 18));
        }

        public void Tick(float dt, float extraHeatPerSecond)
        {
            if (LabUi.LeftDown && LabUi.Over(knob)) { dragging = true; dragY = LabUi.MousePos.y; dragPower = Power; }
            if (dragging)
            {
                if (!LabUi.LeftHeld) dragging = false;
                else Power = Mathf.Clamp01(dragPower + (LabUi.MousePos.y - dragY) / 220f);
            }
            float target = 25f + Power * cfg.heaterMaxRise;
            float k = 1f - Mathf.Exp(-dt / Mathf.Max(0.1f, cfg.heaterTimeConstant));
            Temp = Mathf.Lerp(Temp, target, k) + extraHeatPerSecond * dt;

            knob.localEulerAngles = new Vector3(0, 0, -Power * 270f);
            powerText.text = $"Lửa {Power * 100:0}%";
            tempFill.fillAmount = Mathf.Clamp01(Temp / scaleMax);
            tempFill.color = Color.Lerp(LabUi.Teal, LabUi.Red, Mathf.Clamp01(Temp / scaleMax));
            tempText.text = $"{Temp:0} °C";
        }

        public void Off()
        {
            Power = 0f;
            dragging = false;
        }
    }
}
