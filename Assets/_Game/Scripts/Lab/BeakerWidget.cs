using System;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Underlab.Lab
{
    /// <summary>
    /// Bình nước cất + cốc có chia vạch + khuấy.
    ///   RÓT: nhấn giữ bình nước rồi kéo SANG PHẢI để nghiêng; nghiêng càng nhiều chảy càng nhanh (~ góc²);
    ///        nhả ra bình dựng lại nhưng nước còn chảy thêm một chút (quán tính). Tràn cốc => thất bại.
    ///   KHUẤY: nhấn giữ trong cốc rồi vẽ vòng tròn. Tốc độ hiển thị vòng/giây; quá nhanh => sóng tràn.
    ///   Cốc chỉ có vạch 50 mL và số đọc làm tròn 5 mL (như đọc vạch thật).
    /// </summary>
    public class BeakerWidget
    {
        public float WaterMl { get; private set; }
        public float StirSpeed { get; private set; }     // vòng/giây
        public bool Stirring { get; private set; }

        public event Action<string> Spilled;

        private readonly LabConfig cfg;
        private readonly RectTransform bottle, beaker;
        private readonly Image waterFill, crystals, bottleImg;
        private readonly TextMeshProUGUI reading, stirText;
        private readonly Image stirFill;
        private float tilt, flow, spillTimer, startX, lastAngle;
        private bool pouring;

        public BeakerWidget(Transform parent, Vector2 pos, LabConfig cfg)
        {
            this.cfg = cfg;
            var root = LabUi.Img(parent, "Beaker", "ui_panel", new Vector2(0, 1), pos, new Vector2(330, 420), null, null, true, 2f).transform;
            LabUi.Txt(root, "Title", "NƯỚC CẤT & CỐC", 18, LabUi.Teal, TextAlignmentOptions.TopLeft,
                new Vector2(0, 1), new Vector2(18, -14), new Vector2(300, 26));

            bottleImg = LabUi.Img(root, "Bottle", "ui_ammo_slot", new Vector2(0, 1), new Vector2(22, -50), new Vector2(70, 110), null, new Color(0.55f, 0.8f, 1f));
            bottle = bottleImg.rectTransform;
            bottle.pivot = new Vector2(0.5f, 0.5f);
            bottle.anchoredPosition = new Vector2(57, -105);
            LabUi.Txt(root, "BottleLabel", "H<sub>2</sub>O", 18, Color.white, TextAlignmentOptions.Center,
                new Vector2(0, 1), new Vector2(22, -95), new Vector2(70, 22));
            LabUi.Txt(root, "PourHint", "Giữ bình, kéo SANG PHẢI để rót\nGiữ trong cốc, vẽ vòng tròn để khuấy", 13, LabUi.Dim,
                TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(105, -54), new Vector2(215, 50));

            // Cốc
            var frame = LabUi.Img(root, "Glass", "ui_panel", new Vector2(0, 1), new Vector2(90, -168), new Vector2(150, 200), null, new Color(0.8f, 0.9f, 1f, 0.5f), true, 4f);
            beaker = frame.rectTransform;
            waterFill = LabUi.Img(frame.transform, "Water", "ui_bar_fill", new Vector2(0, 0), new Vector2(6, 6), new Vector2(138, 188), new Vector2(0, 0), new Color(0.45f, 0.75f, 1f, 0.7f));
            waterFill.type = Image.Type.Filled;
            waterFill.fillMethod = Image.FillMethod.Vertical;
            waterFill.fillAmount = 0f;
            crystals = LabUi.Img(frame.transform, "Crystals", "icon_ore_kcl", new Vector2(0.5f, 0), new Vector2(0, 8), new Vector2(60, 40), new Vector2(0.5f, 0));
            crystals.enabled = false;
            for (float v = 50; v <= cfg.beakerCapacity; v += 50)
            {
                float y = 6 + 188 * v / cfg.beakerCapacity;
                LabUi.Img(frame.transform, "Tick", null, new Vector2(0, 0), new Vector2(150, y), new Vector2(v % 100 == 0 ? 16 : 9, 2), new Vector2(1, 0.5f), Color.white);
                if (v % 100 == 0)
                    LabUi.Txt(frame.transform, "TickLabel", $"{v:0}", 12, Color.white, TextAlignmentOptions.Left,
                        new Vector2(0, 0), new Vector2(154, y + 8), new Vector2(40, 16));
            }
            reading = LabUi.Txt(root, "Reading", "", 18, LabUi.Green, TextAlignmentOptions.Left,
                new Vector2(0, 1), new Vector2(18, -374), new Vector2(160, 26));

            // Tốc độ khuấy
            var sFrame = LabUi.Img(root, "StirFrame", "ui_bar_frame", new Vector2(0, 1), new Vector2(180, -378), new Vector2(130, 18), null, null, true, 4f);
            stirFill = LabUi.Img(sFrame.transform, "StirFill", "ui_bar_fill", new Vector2(0, 0.5f), new Vector2(3, 0), new Vector2(124, 10), new Vector2(0, 0.5f));
            stirFill.type = Image.Type.Filled;
            stirFill.fillMethod = Image.FillMethod.Horizontal;
            float gx0 = 3 + 124 * cfg.stirGood.x / cfg.stirSpill, gx1 = 3 + 124 * cfg.stirGood.y / cfg.stirSpill;
            LabUi.Img(sFrame.transform, "Good", null, new Vector2(0, 0.5f), new Vector2(gx0, 0), new Vector2(gx1 - gx0, 4), new Vector2(0, 0.5f), new Color(0.45f, 0.95f, 0.5f, 0.5f));
            stirText = LabUi.Txt(root, "StirText", "", 12, LabUi.Dim, TextAlignmentOptions.Left,
                new Vector2(0, 1), new Vector2(180, -398), new Vector2(140, 16));
        }

        /// <summary>undissolvedFrac: phần chất rắn chưa tan (0..1) để vẽ tinh thể dưới đáy.</summary>
        public void Tick(float dt, float undissolvedFrac)
        {
            // ---- Rót
            if (LabUi.LeftDown && LabUi.Over(bottle)) { pouring = true; startX = LabUi.MousePos.x; }
            if (pouring && !LabUi.LeftHeld) pouring = false;
            float targetTilt = pouring ? Mathf.Clamp01((LabUi.MousePos.x - startX) / 160f) : 0f;
            tilt = Mathf.MoveTowards(tilt, targetTilt, dt * (pouring ? 6f : 3f));
            bottle.localEulerAngles = new Vector3(0, 0, -tilt * 110f);
            float k = cfg.pourInertia > 0 ? 1f - Mathf.Exp(-dt / cfg.pourInertia) : 1f;
            flow = Mathf.Lerp(flow, cfg.maxPour * tilt * tilt, k);
            if (tilt <= 0.001f && flow < 0.3f) flow = 0f;
            WaterMl += flow * dt;
            if (WaterMl > cfg.beakerCapacity)
            {
                Reset();
                Spilled?.Invoke("Rót tràn quá miệng cốc");
                return;
            }

            // ---- Khuấy
            if (LabUi.LeftDown && LabUi.Over(beaker)) { Stirring = true; lastAngle = AngleAroundBeaker(); }
            if (Stirring && !LabUi.LeftHeld) Stirring = false;
            float speed = 0f;
            if (Stirring && dt > 0f)
            {
                float a = AngleAroundBeaker();
                speed = Mathf.Abs(Mathf.DeltaAngle(lastAngle, a)) / 360f / dt;
                lastAngle = a;
            }
            StirSpeed = Mathf.Lerp(StirSpeed, speed, 1f - Mathf.Exp(-dt / 0.25f));
            if (StirSpeed > cfg.stirSpill && WaterMl > 1f) spillTimer += dt; else spillTimer = 0f;
            if (spillTimer > cfg.stirSpillSeconds)
            {
                Reset();
                Spilled?.Invoke("Khuấy quá mạnh → dung dịch sóng tràn khỏi cốc");
                return;
            }

            // ---- Hiển thị
            waterFill.fillAmount = Mathf.Clamp01(WaterMl / cfg.beakerCapacity);
            crystals.enabled = undissolvedFrac > 0.01f;
            crystals.color = new Color(1, 1, 1, Mathf.Clamp01(undissolvedFrac * 1.5f));
            reading.text = $"≈ {Mathf.Round(WaterMl / 5f) * 5f:0} mL";
            stirFill.fillAmount = Mathf.Clamp01(StirSpeed / cfg.stirSpill);
            stirFill.color = StirSpeed > cfg.stirGood.y ? LabUi.Red : StirSpeed >= cfg.stirGood.x ? LabUi.Green : LabUi.Gold;
            stirText.text = $"Khuấy {StirSpeed:0.0} vòng/s";
        }

        public float TakeAll()
        {
            float w = WaterMl;
            Reset();
            return w;
        }

        private void Reset()
        {
            WaterMl = 0f;
            flow = 0f;
            tilt = 0f;
            pouring = Stirring = false;
            spillTimer = 0f;
            StirSpeed = 0f;
        }

        private float AngleAroundBeaker()
        {
            RectTransformUtility.ScreenPointToLocalPointInRectangle(beaker, LabUi.MousePos, null, out var local);
            var c = beaker.rect.center;
            return Mathf.Atan2(local.y - c.y, local.x - c.x) * Mathf.Rad2Deg;
        }
    }
}
