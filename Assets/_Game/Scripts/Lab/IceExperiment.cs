using TMPro;
using UnityEngine;
using UnityEngine.UI;
using Underlab.Core;
using Underlab.Defense;

namespace Underlab.Lab
{
    /// <summary>
    /// Thí nghiệm ĐẠN BĂNG: pha dung dịch KCl BÃO HOÀ (hoà tan thu nhiệt => dung dịch lạnh đi).
    /// Người chơi: rót nước (mL ≈ g), cân KCl, đổ vào cốc, KHUẤY đến khi tan hết, bấm HOÀN TẤT.
    /// Độ tan 34.2 g / 100 g nước (20 °C):
    ///   cho thừa  => không tan hết, kết tủa => THẤT BẠI
    ///   cho thiếu => dung dịch chưa bão hoà, không đủ lạnh => THẤT BẠI
    ///   chưa khuấy tan hết đã bấm => THẤT BẠI
    ///   khuấy quá mạnh / rót tràn => đổ hết => THẤT BẠI
    /// Thất bại mất sạch KCl đã đổ vào cốc.
    /// </summary>
    public class IceExperiment : ILabExperiment
    {
        public const string Id = "ice";
        public string Title => "ĐẠN BĂNG";

        public enum Outcome { Ok, Missing, Supersaturated, Unsaturated, NotDissolved }

        public struct Result
        {
            public Outcome outcome;
            public float target, dev, eff, nKCl;
        }

        /// <summary>Chấm điểm (tách riêng để test). waterMl coi như gam (khối lượng riêng nước ≈ 1).</summary>
        public static Result Evaluate(float kclGrams, float waterMl, float dissolvedGrams, LabConfig cfg)
        {
            var r = new Result { nKCl = kclGrams / Chem.KCl };
            if (kclGrams < 0.5f || waterMl < 1f) { r.outcome = Outcome.Missing; return r; }
            r.target = cfg.kclSolubility * waterMl;
            r.dev = Mathf.Abs(kclGrams - r.target) / r.target;
            if (kclGrams > r.target * (1f + cfg.tolerance)) r.outcome = Outcome.Supersaturated;
            else if (r.dev > cfg.tolerance) r.outcome = Outcome.Unsaturated;
            else if (dissolvedGrams < kclGrams * 0.98f) r.outcome = Outcome.NotDissolved;
            else
            {
                r.outcome = Outcome.Ok;
                r.eff = Mathf.Lerp(1f, cfg.efficiencyAtTolerance, r.dev / cfg.tolerance);
            }
            return r;
        }

        /// <summary>Nhiệt độ dung dịch khi đã tan m gam KCl trong w gam nước (thu nhiệt).</summary>
        public static float SolutionTemp(float dissolvedGrams, float waterMl, LabConfig cfg)
        {
            if (waterMl < 1f) return 25f;
            float q = dissolvedGrams / Chem.KCl * cfg.kclDissolveEnthalpy * 1000f;       // J hấp thu
            return 25f - q / ((waterMl + dissolvedGrams) * 4.18f);
        }

        private readonly LabStation station;
        private readonly LabConfig cfg;
        private readonly Turret turret;
        private readonly ScaleWidget scale;
        private readonly BeakerWidget beaker;
        private readonly TextMeshProUGUI tempText, info, result, mastery, autoText;
        private readonly Image dissolveFill;
        private readonly Button doneBtn, autoBtn;
        private float kclIn, dissolved, bulletCarry, autoUntil, autoBullets;

        public IceExperiment(Transform parent, LabStation station, LabConfig cfg, ResourceBank bank, Turret turret)
        {
            this.station = station;
            this.cfg = cfg;
            this.turret = turret;
            scale = new ScaleWidget(parent, new Vector2(30, -70), cfg, bank, ResourceType.KCl, "KCl", Chem.KCl, "icon_ore_kcl");
            beaker = new BeakerWidget(parent, new Vector2(375, -70), cfg);
            beaker.Spilled += why => Fail($"{why}. Mất {kclIn:0.0} g KCl và toàn bộ nước.", true);

            var root = LabUi.Img(parent, "Dissolve", "ui_panel", new Vector2(0, 1), new Vector2(720, -70), new Vector2(530, 420), null, null, true, 2f).transform;
            LabUi.Txt(root, "Title", "HOÀ TAN", 18, LabUi.Teal, TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(18, -14), new Vector2(300, 26));
            LabUi.Btn(root, "Đổ KCl từ cân vào cốc", new Vector2(0, 1), new Vector2(18, -48), new Vector2(250, 44), AddKcl, null, 16);
            info = LabUi.Txt(root, "Info", "", 15, Color.white, TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(280, -48), new Vector2(235, 50));

            LabUi.Txt(root, "DLabel", "Đã tan", 13, LabUi.Dim, TextAlignmentOptions.Left, new Vector2(0, 1), new Vector2(18, -104), new Vector2(120, 18));
            var dFrame = LabUi.Img(root, "DFrame", "ui_bar_frame", new Vector2(0, 1), new Vector2(18, -124), new Vector2(495, 22), null, null, true, 4f);
            dissolveFill = LabUi.Img(dFrame.transform, "DFill", "ui_bar_fill", new Vector2(0, 0.5f), new Vector2(4, 0), new Vector2(487, 12), new Vector2(0, 0.5f), new Color(0.6f, 0.9f, 1f));
            dissolveFill.type = Image.Type.Filled;
            dissolveFill.fillMethod = Image.FillMethod.Horizontal;
            tempText = LabUi.Txt(root, "Temp", "", 22, Color.white, TextAlignmentOptions.Left, new Vector2(0, 1), new Vector2(18, -152), new Vector2(300, 30));

            doneBtn = LabUi.Btn(root, "HOÀN TẤT", new Vector2(0, 1), new Vector2(18, -192), new Vector2(170, 52), Finish, null, 20);
            autoBtn = LabUi.Btn(root, "TỰ ĐỘNG", new Vector2(0, 1), new Vector2(198, -192), new Vector2(140, 52), StartAuto, null, 16);
            mastery = LabUi.Txt(root, "Mastery", "", 14, LabUi.Gold, TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(348, -192), new Vector2(170, 40));
            autoText = LabUi.Txt(root, "AutoText", "", 13, LabUi.Dim, TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(198, -248), new Vector2(160, 20));
            result = LabUi.Txt(root, "Result", "", 15, Color.white, TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(18, -272), new Vector2(495, 140));

            LabUi.Txt(parent, "Notebook",
                "<color=#F2D35B>ĐỀ:</color> Pha dung dịch KCl <b>BÃO HOÀ</b> ở 20 °C để làm lạnh (hoà tan KCl là quá trình <b>thu nhiệt</b>).\n" +
                $"Dữ kiện: độ tan KCl = 34.2 g / 100 g nước · K = 39.1, Cl = 35.45 g/mol · nước: 1 mL ≈ 1 g · sai số ±{cfg.tolerance * 100:0}%\n" +
                $"Sản phẩm: mỗi mol KCl hoà tan đúng → {cfg.iceBulletsPerMolKCl:0.#} viên đạn băng. Thừa (kết tủa), thiếu (không đủ lạnh), chưa tan hết, tràn cốc → mất sạch.",
                15, Color.white, TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(30, -500), new Vector2(1220, 90));
            RefreshMastery();
        }

        public void Tick(float dt)
        {
            scale.Tick(dt);
            float maxDissolve = cfg.kclSolubility * beaker.WaterMl;
            float undissolved = Mathf.Max(0f, kclIn - dissolved);
            beaker.Tick(dt, kclIn > 0 ? undissolved / kclIn : 0f);

            // Tan theo tốc độ khuấy; không vượt quá độ tan
            float s = beaker.StirSpeed;
            float factor = s < 0.2f ? 0.03f : s < cfg.stirGood.x ? s / cfg.stirGood.x * 0.6f : 1f;
            if (kclIn > 0f)
                dissolved = Mathf.Min(Mathf.Min(kclIn, maxDissolve), dissolved + kclIn / cfg.dissolveSeconds * factor * dt);

            float t = SolutionTemp(dissolved, beaker.WaterMl, cfg);
            dissolveFill.fillAmount = kclIn > 0 ? dissolved / kclIn : 0f;
            tempText.text = $"Nhiệt kế: {t:0.0} °C";
            info.text = $"Trong cốc: {kclIn:0.0} g KCl\nCòn chưa tan: {undissolved:0.0} g";

            bool busy = Time.time < autoUntil;
            doneBtn.interactable = !busy;
            autoBtn.gameObject.SetActive(station.Mastery(Id) >= cfg.masteryRuns);
            autoBtn.interactable = !busy;
            if (busy) autoText.text = $"Đang chạy… {autoUntil - Time.time:0.0}s";
            else if (autoBullets > 0f)
            {
                Give(autoBullets, $"<color=#6BE04F>TỰ ĐỘNG XONG</color> (hiệu suất {cfg.autoEfficiency * 100:0}%)");
                autoBullets = 0f;
                autoText.text = "";
            }
        }

        public void OnClose() => scale.ReturnToBank();

        private void AddKcl()
        {
            float g = scale.TakeAll();
            if (g <= 0f) { result.text = "<color=#F2D35B>Cân đang trống.</color>"; return; }
            kclIn += g;
            result.text = $"Đã đổ {g:0.00} g KCl vào cốc. Khuấy cho tan.";
        }

        private void Finish()
        {
            var r = Evaluate(kclIn, beaker.WaterMl, dissolved, cfg);
            float water = beaker.WaterMl;
            switch (r.outcome)
            {
                case Outcome.Missing:
                    result.text = "<color=#F2D35B>Cần có cả nước và KCl trong cốc.</color>";
                    return;
                case Outcome.Supersaturated:
                    Fail($"<b>Quá bão hoà</b>: {water:0} g nước chỉ hoà tan tối đa {r.target:0.0} g KCl, bạn cho {kclIn:0.0} g " +
                         $"(thừa {r.dev * 100:0}%) → {kclIn - r.target:0.0} g kết tủa dưới đáy. Mất sạch KCl.", false);
                    break;
                case Outcome.Unsaturated:
                    Fail($"<b>Chưa bão hoà</b>: cần ≈ {r.target:0.0} g KCl cho {water:0} g nước, bạn cho {kclIn:0.0} g " +
                         $"(thiếu {r.dev * 100:0}%) → dung dịch không đủ lạnh để nạp đạn. Mất sạch KCl.", false);
                    break;
                case Outcome.NotDissolved:
                    Fail($"<b>Chưa tan hết</b> ({dissolved / kclIn * 100:0}%) — phải khuấy đến khi tinh thể tan hết rồi mới hoàn tất. Mất sạch KCl.", false);
                    break;
                default:
                    float tEnd = SolutionTemp(dissolved, water, cfg);
                    station.AddMastery(Id);
                    RefreshMastery();
                    Give(r.nKCl * cfg.iceBulletsPerMolKCl * r.eff,
                        $"<color=#6BE04F>THÀNH CÔNG!</color> Dung dịch KCl bão hoà, nhiệt độ tụt còn {tEnd:0.0} °C <color=#ffffff99>(thu nhiệt)</color>\n" +
                        $"{kclIn:0.0} g KCl / {water:0} g nước (cần {r.target:0.0} g, lệch {r.dev * 100:0.0}%) → hiệu suất {r.eff * 100:0}%");
                    break;
            }
            kclIn = 0f;
            dissolved = 0f;
            beaker.TakeAll();
        }

        private void StartAuto()
        {
            float n = Mathf.Floor(scale.TrayGrams / Chem.KCl + 0.0001f);
            if (n < 1f) { result.text = "<color=#F2D35B>Tự động: cần ít nhất 1 mol KCl trên khay.</color>"; return; }
            scale.ConsumeTray(n * Chem.KCl);
            autoBullets = n * cfg.iceBulletsPerMolKCl * cfg.autoEfficiency;
            autoUntil = Time.time + n * cfg.autoSecondsPerMol;
            result.text = $"Quy trình tự động: pha {n:0} mol KCl…";
        }

        private void Give(float bullets, string header)
        {
            bullets += bulletCarry;
            int whole = Mathf.FloorToInt(bullets + 0.0001f);
            bulletCarry = bullets - whole;
            turret.Ammunition[(int)AmmoType.Ice] += whole;
            result.text = $"{header}\n→ <color=#F2D35B>+{whole} đạn băng</color>";
            station.Flash(true);
        }

        private void Fail(string why, bool spilled)
        {
            result.text = $"<color=#FF5A4A>THẤT BẠI.</color> {why}";
            kclIn = 0f;
            dissolved = 0f;
            if (!spilled) beaker.TakeAll();
            station.Flash(false);
        }

        private void RefreshMastery()
        {
            int n = station.Mastery(Id);
            mastery.text = n >= cfg.masteryRuns ? "» Đã mở QUY TRÌNH TỰ ĐỘNG" : $"Làm đúng {n}/{cfg.masteryRuns} lần\n→ mở quy trình tự động";
        }
    }
}
