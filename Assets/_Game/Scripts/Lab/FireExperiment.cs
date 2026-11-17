using System;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
using Underlab.Art;
using Underlab.Core;
using Underlab.Defense;

namespace Underlab.Lab
{
    /// <summary>
    /// Thí nghiệm ĐẠN LỬA: đốt magie trong oxi.   2Mg + O₂ → 2MgO   (toả nhiệt mạnh)
    /// Người chơi: cân Mg (tự đổi mol → gam), mở van nạp O₂ (tự đổi mol → lít), châm lửa.
    /// Lệch tỉ lệ > tolerance => thất bại, MẤT SẠCH Mg trên cân và O₂ trong ống đo.
    /// Trên màn hình chỉ ghi phương trình CHƯA cân bằng — cân bằng là việc của người chơi.
    /// </summary>
    public class FireExperiment : ILabExperiment
    {
        public const string Id = "fire";
        public string Title => "ĐẠN LỬA";

        private readonly LabStation station;
        private readonly LabConfig cfg;
        private readonly Turret turret;
        private readonly ScaleWidget scale;
        private readonly ValveWidget valve;
        private readonly TextMeshProUGUI tempText, result, mastery, autoText;
        private readonly Image tempFill, flame;
        private readonly Button igniteBtn, autoBtn;
        private float temp = 25f, flameUntil, autoUntil, autoBullets, bulletCarry;

        public FireExperiment(Transform parent, LabStation station, LabConfig cfg, ResourceBank bank, Turret turret)
        {
            this.station = station;
            this.cfg = cfg;
            this.turret = turret;

            scale = new ScaleWidget(parent, new Vector2(30, -70), cfg, bank, ResourceType.Magnesium, "Mg", Chem.Mg, "icon_ore_mg");
            valve = new ValveWidget(parent, new Vector2(375, -70), cfg, "O2",
                () => station.O2Liters, v => station.O2Liters -= v);
            valve.OverPressure += lost => Fail($"Mở van quá to → áp suất vượt mức, ống đo bị xì.\nMất {lost:0.0} L {Chem.F("O2")}.", false);

            // Lò đốt
            var root = LabUi.Img(parent, "Furnace", "ui_panel", new Vector2(0, 1), new Vector2(720, -70), new Vector2(530, 420), null, null, true, 2f).transform;
            LabUi.Txt(root, "Title", "LÒ ĐỐT", 18, LabUi.Teal, TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(18, -14), new Vector2(300, 26));
            LabUi.Img(root, "Chamber", "ui_ammo_slot", new Vector2(0, 1), new Vector2(24, -48), new Vector2(150, 150), null, new Color(0.5f, 0.45f, 0.55f));
            flame = LabUi.Img(root, "Flame", "fx_status_burn", new Vector2(0, 1), new Vector2(49, -66), new Vector2(100, 100));
            flame.enabled = false;

            // Nhiệt kế
            LabUi.Txt(root, "TLabel", "Nhiệt kế", 13, LabUi.Dim, TextAlignmentOptions.Left, new Vector2(0, 1), new Vector2(190, -48), new Vector2(120, 20));
            var tFrame = LabUi.Img(root, "TFrame", "ui_bar_frame", new Vector2(0, 1), new Vector2(190, -70), new Vector2(310, 24), null, null, true, 4f);
            tempFill = LabUi.Img(tFrame.transform, "TFill", "ui_bar_fill", new Vector2(0, 0.5f), new Vector2(4, 0), new Vector2(302, 14), new Vector2(0, 0.5f));
            tempFill.type = Image.Type.Filled;
            tempFill.fillMethod = Image.FillMethod.Horizontal;
            tempText = LabUi.Txt(root, "Temp", "25 °C", 22, Color.white, TextAlignmentOptions.Left, new Vector2(0, 1), new Vector2(190, -100), new Vector2(200, 30));

            igniteBtn = LabUi.Btn(root, "CHÂM LỬA", new Vector2(0, 1), new Vector2(190, -142), new Vector2(170, 52), Ignite, null, 20);
            autoBtn = LabUi.Btn(root, "TỰ ĐỘNG", new Vector2(0, 1), new Vector2(370, -142), new Vector2(140, 52), StartAuto, null, 16);
            autoText = LabUi.Txt(root, "AutoText", "", 13, LabUi.Dim, TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(370, -198), new Vector2(150, 40));
            mastery = LabUi.Txt(root, "Mastery", "", 14, LabUi.Gold, TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(190, -200), new Vector2(180, 40));

            result = LabUi.Txt(root, "Result", "", 15, Color.white, TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(18, -240), new Vector2(495, 170));

            // Sổ ghi chép (đề bài) — phương trình CHƯA cân bằng
            LabUi.Txt(parent, "Notebook",
                $"<color=#F2D35B>ĐỀ:</color> Đốt cháy magie trong khí oxi:   {Chem.F("Mg")} + {Chem.F("O2")} → {Chem.F("MgO")}   <color=#ffffff99>(chưa cân bằng)</color>\n" +
                $"Dữ kiện: Mg = 24.3 g/mol · O = 16 g/mol · 1 mol khí ≈ {cfg.gasMolarVolume} L (25 °C, 1 bar) · sai số cho phép ±{cfg.tolerance * 100:0}%\n" +
                $"Sản phẩm: mỗi mol Mg cháy đúng → {cfg.fireBulletsPerMolMg:0.#} viên đạn lửa (nhân hiệu suất). Sai → mất sạch Mg trên cân và {Chem.F("O2")} đã nạp.",
                15, Color.white, TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(30, -500), new Vector2(1220, 90));
            RefreshMastery();
        }

        public void Tick(float dt)
        {
            scale.Tick(dt);
            valve.Tick(dt);

            // Nhiệt độ nguội dần về 25 °C
            temp = Mathf.Lerp(temp, 25f, 1f - Mathf.Exp(-dt / 2.5f));
            tempFill.fillAmount = Mathf.Clamp01(temp / 3200f);
            tempFill.color = Color.Lerp(LabUi.Teal, LabUi.Red, Mathf.Clamp01(temp / 2000f));
            tempText.text = $"{temp:0} °C";
            flame.enabled = Time.time < flameUntil;
            if (flame.enabled) flame.rectTransform.localScale = Vector3.one * (0.9f + 0.15f * Mathf.Sin(Time.time * 30f));

            bool busy = Time.time < autoUntil;
            igniteBtn.interactable = !busy;
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

        public void OnClose()
        {
            valve.CloseValve();
            scale.ReturnToBank();
        }

        /// <summary>Kết quả chấm 1 lần đốt (tách riêng để test được, không cần UI).</summary>
        public struct Result
        {
            public bool ok, noOxygen;
            public float nMg, needMol, needL, dev, eff;
        }

        /// <summary>Chấm điểm: m gam Mg đốt với v lít O₂.   2Mg + O₂ → 2MgO</summary>
        public static Result Evaluate(float grams, float liters, LabConfig cfg)
        {
            var r = new Result { nMg = grams / Chem.Mg };
            r.needMol = r.nMg / 2f;
            r.needL = r.needMol * cfg.gasMolarVolume;
            r.noOxygen = liters < 0.05f;
            r.dev = r.needL > 0 ? Mathf.Abs(liters - r.needL) / r.needL : 1f;
            r.ok = !r.noOxygen && r.dev <= cfg.tolerance;
            r.eff = r.ok ? Mathf.Lerp(1f, cfg.efficiencyAtTolerance, r.dev / cfg.tolerance) : 0f;
            return r;
        }

        private void Ignite()
        {
            float m = scale.Grams;
            float v = valve.Dispensed;
            if (m < 0.5f)
            {
                result.text = "<color=#F2D35B>Chưa có Mg trên cân.</color>";
                return;
            }
            var r = Evaluate(m, v, cfg);
            scale.TakeAll();
            valve.TakeAll();
            valve.CloseValve();

            if (r.noOxygen)
            {
                Fail($"Không có {Chem.F("O2")} trong lò → Mg chỉ nóng đỏ rồi bị oxi hoá bề mặt, không cháy.\nMất {m:0.0} g Mg.", true);
                return;
            }
            if (!r.ok)
            {
                string side = v > r.needL ? "THỪA" : "THIẾU";
                Fail($"Sai tỉ lệ ({side} {Chem.F("O2")} {r.dev * 100:0}%).\n" +
                     $"{m:0.00} g Mg = {r.nMg:0.000} mol → theo 2Mg + {Chem.F("O2")} → 2MgO cần {r.needMol:0.000} mol {Chem.F("O2")} = {r.needL:0.00} L.\n" +
                     $"Bạn nạp {v:0.00} L. Mất sạch {m:0.0} g Mg và {v:0.0} L {Chem.F("O2")}.", true);
                return;
            }

            temp = 3000f;
            flameUntil = Time.time + 1.6f;
            station.AddMastery(Id);
            RefreshMastery();
            Give(r.nMg * cfg.fireBulletsPerMolMg * r.eff,
                $"<color=#6BE04F>THÀNH CÔNG!</color>  2Mg + {Chem.F("O2")} → 2MgO  <color=#ffffff99>(toả nhiệt — ngọn lửa trắng chói ~3000 °C)</color>\n" +
                $"{r.nMg:0.000} mol Mg + {v:0.00} L {Chem.F("O2")} (cần {r.needL:0.00} L, lệch {r.dev * 100:0.0}%) → hiệu suất {r.eff * 100:0}%");
        }

        private void StartAuto()
        {
            float nMg = Mathf.Floor(scale.TrayGrams / Chem.Mg + 0.0001f);
            if (nMg < 1f) { result.text = "<color=#F2D35B>Tự động: cần ít nhất 1 mol Mg trên khay.</color>"; return; }
            float needL = nMg / 2f * cfg.gasMolarVolume;
            if (station.O2Liters < needL) { result.text = $"<color=#F2D35B>Tự động: bình chỉ còn {station.O2Liters:0.0} L {Chem.F("O2")}, cần {needL:0.0} L.</color>"; return; }
            station.O2Liters -= needL;
            scale.ConsumeTray(nMg * Chem.Mg);
            autoBullets = nMg * cfg.fireBulletsPerMolMg * cfg.autoEfficiency;
            autoUntil = Time.time + nMg * cfg.autoSecondsPerMol;
            result.text = $"Quy trình tự động: đốt {nMg:0} mol Mg với {needL:0.0} L {Chem.F("O2")}…";
        }

        private void Give(float bullets, string header)
        {
            bullets += bulletCarry;
            int whole = Mathf.FloorToInt(bullets + 0.0001f);
            bulletCarry = bullets - whole;
            turret.Ammunition[(int)AmmoType.Fire] += whole;
            result.text = $"{header}\n→ <color=#F2D35B>+{whole} đạn lửa</color>" +
                          (bulletCarry > 0.01f ? $"  <color=#ffffff99>(dư {bulletCarry:0.00} viên, cộng vào lần sau)</color>" : "");
            station.Flash(true);
        }

        private void Fail(string why, bool smoke)
        {
            if (smoke) temp = 600f;
            result.text = $"<color=#FF5A4A>THẤT BẠI.</color> {why}";
            station.Flash(false);
        }

        private void RefreshMastery()
        {
            int n = station.Mastery(Id);
            mastery.text = n >= cfg.masteryRuns
                ? "» Đã mở QUY TRÌNH TỰ ĐỘNG"
                : $"Làm đúng {n}/{cfg.masteryRuns} lần\n→ mở quy trình tự động";
        }
    }
}
