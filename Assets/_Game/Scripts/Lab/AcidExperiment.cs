using TMPro;
using UnityEngine;
using UnityEngine.UI;
using Underlab.Core;
using Underlab.Defense;

namespace Underlab.Lab
{
    /// <summary>
    /// Thí nghiệm ĐẠN AXIT — quy trình tiếp xúc sản xuất H<sub>2</sub>SO<sub>4</sub> (3 bước):
    ///   B1  S + O<sub>2</sub> → SO<sub>2</sub>                 (lò đốt, tỉ lệ 1 : 1)
    ///   B2  2SO<sub>2</sub> + O<sub>2</sub> → 2SO<sub>3</sub>             (tháp tiếp xúc: xúc tác V<sub>2</sub>O<sub>5</sub>, giữ 400–500 °C đủ 5 s, toả nhiệt)
    ///   B3  SO<sub>3</sub> hấp thụ bằng H<sub>2</sub>SO<sub>4</sub> đặc → oleum, rồi RÓT AXIT VÀO NƯỚC để pha loãng
    /// Bẫy kiến thức: hấp thụ SO<sub>3</sub> bằng nước => sương mù axit; rót nước vào axit => sôi bắn.
    /// Mỗi bước sai => mất sạch nguyên liệu của bước đó. SO<sub>2</sub>/SO<sub>3</sub> trung gian giữ lại giữa các lần mở phòng.
    /// </summary>
    public class AcidExperiment : ILabExperiment
    {
        public const string Id = "acid";
        public string Title => "ĐẠN AXIT";

        public struct Ratio
        {
            public bool ok, noGas;
            public float n, needMol, needL, dev, eff;
        }

        /// <summary>Chấm tỉ lệ khí: có `mol` chất phản ứng, cần mol·k mol O<sub>2</sub> (k = 1 cho đốt S, 0.5 cho SO<sub>2</sub> → SO<sub>3</sub>).</summary>
        public static Ratio Evaluate(float mol, float o2Liters, float k, LabConfig cfg)
        {
            var r = new Ratio { n = mol, needMol = mol * k };
            r.needL = r.needMol * cfg.gasMolarVolume;
            r.noGas = o2Liters < 0.05f;
            r.dev = r.needL > 0 ? Mathf.Abs(o2Liters - r.needL) / r.needL : 1f;
            r.ok = !r.noGas && r.dev <= cfg.tolerance;
            r.eff = r.ok ? Mathf.Lerp(1f, cfg.efficiencyAtTolerance, r.dev / cfg.tolerance) : 0f;
            return r;
        }

        private readonly LabStation station;
        private readonly LabConfig cfg;
        private readonly Turret turret;
        private readonly ScaleWidget scale;
        private readonly ValveWidget valve;
        private readonly HeaterWidget heater;
        private readonly GameObject[] stepPanels = new GameObject[3];
        private readonly Button[] stepBtns = new Button[3];
        private readonly TextMeshProUGUI stock, result, mastery, catalystText, contactState, absorbState;
        private readonly Button catalystBtn, startBtn, intoWater, intoAcid, acidIntoWater, waterIntoAcid;
        private readonly Image holdFill;
        private int step;
        private float so2, so3, oleum, bulletCarry;
        private bool catalyst, running;
        private float contactEff, holdTime, runO2;

        public AcidExperiment(Transform parent, LabStation station, LabConfig cfg, ResourceBank bank, Turret turret)
        {
            this.station = station;
            this.cfg = cfg;
            this.turret = turret;
            scale = new ScaleWidget(parent, new Vector2(30, -70), cfg, bank, ResourceType.Sulfur, "S", Chem.S, "icon_ore_sulfur");
            valve = new ValveWidget(parent, new Vector2(375, -70), cfg, "O2", () => station.O2Liters, v => station.O2Liters -= v);
            valve.OverPressure += lost => Fail($"Mở van quá to → xì khí. Mất {lost:0.0} L O<sub>2</sub>.");

            var root = LabUi.Img(parent, "Process", "ui_panel", new Vector2(0, 1), new Vector2(720, -70), new Vector2(530, 420), null, null, true, 2f).transform;
            string[] names = { "1. Đốt S", "2. Tháp tiếp xúc", "3. Hấp thụ" };
            for (int i = 0; i < 3; i++)
            {
                int idx = i;
                stepBtns[i] = LabUi.Btn(root, names[i], new Vector2(0, 1), new Vector2(14 + i * 170, -12), new Vector2(162, 38), () => SetStep(idx), null, 15);
                stepPanels[i] = LabUi.Rect(root, "Step" + i, new Vector2(0, 1), new Vector2(0, -56), new Vector2(530, 250)).gameObject;
            }
            stock = LabUi.Txt(root, "Stock", "", 14, LabUi.Dim, TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(18, -300), new Vector2(495, 22));
            mastery = LabUi.Txt(root, "Mastery", "", 13, LabUi.Gold, TextAlignmentOptions.TopRight, new Vector2(1, 1), new Vector2(-18, -300), new Vector2(220, 22), new Vector2(1, 1));
            result = LabUi.Txt(root, "Result", "", 14, Color.white, TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(18, -322), new Vector2(495, 95));

            // ---- Bước 1
            var p1 = stepPanels[0].transform;
            LabUi.Txt(p1, "T", "Cân S ở cột trái, nạp O<sub>2</sub> ở cột giữa, rồi đốt:\nS + O<sub>2</sub> → SO<sub>2</sub>", 16, Color.white,
                TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(18, -6), new Vector2(495, 50));
            LabUi.Btn(p1, "ĐỐT LƯU HUỲNH", new Vector2(0, 1), new Vector2(18, -66), new Vector2(220, 52), BurnSulfur, null, 18);

            // ---- Bước 2
            var p2 = stepPanels[1].transform;
            LabUi.Txt(p2, "T", "Nạp O<sub>2</sub> cho toàn bộ SO<sub>2</sub>:  __SO<sub>2</sub> + __O<sub>2</sub> → __SO<sub>3</sub>", 15, Color.white,
                TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(18, -6), new Vector2(495, 24));
            catalystBtn = LabUi.Btn(p2, "Lắp xúc tác V<sub>2</sub>O<sub>5</sub>", new Vector2(0, 1), new Vector2(18, -34), new Vector2(200, 36), () => catalyst = !catalyst, null, 14);
            catalystText = LabUi.Txt(p2, "Cat", "", 14, Color.white, TextAlignmentOptions.Left, new Vector2(0, 1), new Vector2(228, -34), new Vector2(280, 36));
            heater = new HeaterWidget(p2, new Vector2(18, -78), cfg, cfg.contactTemp, cfg.contactFail);
            startBtn = LabUi.Btn(p2, "BẮT ĐẦU PHẢN ỨNG", new Vector2(0, 1), new Vector2(330, -78), new Vector2(180, 44), StartContact, null, 15);
            var hFrame = LabUi.Img(p2, "HoldFrame", "ui_bar_frame", new Vector2(0, 1), new Vector2(330, -128), new Vector2(180, 18), null, null, true, 4f);
            holdFill = LabUi.Img(hFrame.transform, "Hold", "ui_bar_fill", new Vector2(0, 0.5f), new Vector2(3, 0), new Vector2(174, 10), new Vector2(0, 0.5f), LabUi.Green);
            holdFill.type = Image.Type.Filled;
            holdFill.fillMethod = Image.FillMethod.Horizontal;
            contactState = LabUi.Txt(p2, "State", "", 13, LabUi.Dim, TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(330, -150), new Vector2(185, 40));

            // ---- Bước 3
            var p3 = stepPanels[2].transform;
            absorbState = LabUi.Txt(p3, "T", "", 15, Color.white, TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(18, -6), new Vector2(495, 44));
            intoWater = LabUi.Btn(p3, "Dẫn SO<sub>3</sub> vào NƯỚC", new Vector2(0, 1), new Vector2(18, -56), new Vector2(235, 46), AbsorbWater, null, 15);
            intoAcid = LabUi.Btn(p3, "Dẫn SO<sub>3</sub> vào H<sub>2</sub>SO<sub>4</sub> đặc 98%", new Vector2(0, 1), new Vector2(263, -56), new Vector2(250, 46), AbsorbAcid, null, 14);
            acidIntoWater = LabUi.Btn(p3, "Rót OLEUM vào NƯỚC", new Vector2(0, 1), new Vector2(18, -118), new Vector2(235, 46), DiluteCorrect, null, 15);
            waterIntoAcid = LabUi.Btn(p3, "Rót NƯỚC vào OLEUM", new Vector2(0, 1), new Vector2(263, -118), new Vector2(250, 46), DiluteWrong, null, 15);

            LabUi.Txt(parent, "Notebook",
                "<color=#F2D35B>ĐỀ:</color> Sản xuất H<sub>2</sub>SO<sub>4</sub> theo <b>phương pháp tiếp xúc</b>: S → SO<sub>2</sub> → SO<sub>3</sub> → H<sub>2</sub>SO<sub>4</sub>. Tự cân bằng các phương trình.\n" +
                $"Dữ kiện: S = 32.06 g/mol · 1 mol khí ≈ {cfg.gasMolarVolume} L · tháp tiếp xúc cần xúc tác V<sub>2</sub>O<sub>5</sub>, {cfg.contactTemp.x:0}–{cfg.contactTemp.y:0} °C · sai số ±{cfg.tolerance * 100:0}%\n" +
                $"Sản phẩm: mỗi mol H<sub>2</sub>SO<sub>4</sub> → {cfg.acidBulletsPerMolH2SO4:0.#} viên đạn axit. Sai bước nào mất sạch nguyên liệu bước đó. <i>Nhớ quy tắc an toàn khi pha axit!</i>",
                15, Color.white, TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(30, -500), new Vector2(1220, 90));
            SetStep(0);
        }

        public void Tick(float dt)
        {
            scale.Tick(dt);
            valve.Tick(dt);
            heater.Tick(dt, running ? cfg.contactExoHeat : 0f);

            if (running) TickContact(dt);

            stock.text = $"Bình trung gian:  SO<sub>2</sub> {so2:0.000} mol   ·   SO<sub>3</sub> {so3:0.000} mol" + (oleum > 0 ? $"   ·   oleum {oleum:0.000} mol" : "");
            catalystText.text = catalyst ? "<color=#6BE04F>Đã lắp V<sub>2</sub>O<sub>5</sub></color>" : "<color=#ffffff88>Chưa lắp xúc tác</color>";
            LabUi.SetLabel(catalystBtn, catalyst ? "Tháo xúc tác" : "Lắp xúc tác V<sub>2</sub>O<sub>5</sub>");
            startBtn.interactable = !running;
            bool hasSo3 = so3 > 0.0001f, hasOleum = oleum > 0.0001f;
            intoWater.interactable = intoAcid.interactable = hasSo3 && !hasOleum;
            acidIntoWater.gameObject.SetActive(hasOleum);
            waterIntoAcid.gameObject.SetActive(hasOleum);
            absorbState.text = hasOleum
                ? $"Đã có {oleum:0.000} mol oleum (H<sub>2</sub>SO<sub>4</sub>·SO<sub>3</sub>). Pha loãng thế nào?"
                : hasSo3 ? $"Có {so3:0.000} mol SO<sub>3</sub>. Hấp thụ SO<sub>3</sub> bằng gì?" : "Chưa có SO<sub>3</sub> — làm bước 2 trước.";
            for (int i = 0; i < 3; i++) stepBtns[i].image.color = i == step ? new Color(1.2f, 1.2f, 0.8f) : Color.white;
            int n = station.Mastery(Id);
            mastery.text = n >= cfg.masteryRuns ? "» Thành thạo quy trình" : $"Làm trọn {n}/{cfg.masteryRuns} lần";
        }

        public void OnClose()
        {
            valve.CloseValve();
            heater.Off();
            if (running) Fail("Rời phòng khi tháp đang phản ứng → SO<sub>2</sub> thoát ra ngoài.");
            scale.ReturnToBank();
        }

        private void SetStep(int i)
        {
            step = i;
            for (int k = 0; k < 3; k++) stepPanels[k].SetActive(k == i);
        }

        // ---------------- Bước 1
        private void BurnSulfur()
        {
            float m = scale.Grams;
            if (m < 0.5f) { result.text = "<color=#F2D35B>Chưa có S trên cân.</color>"; return; }
            float v = valve.Dispensed;
            var r = Evaluate(m / Chem.S, v, 1f, cfg);
            scale.TakeAll();
            valve.TakeAll();
            valve.CloseValve();
            if (r.noGas) { Fail($"Không có O<sub>2</sub> → lưu huỳnh không cháy. Mất {m:0.0} g S."); return; }
            if (!r.ok)
            {
                Fail($"Sai tỉ lệ ({(v > r.needL ? "thừa" : "thiếu")} O<sub>2</sub> {r.dev * 100:0}%). {m:0.00} g S = {r.n:0.000} mol cần " +
                     $"{r.needMol:0.000} mol O<sub>2</sub> = {r.needL:0.00} L; bạn nạp {v:0.00} L. Mất sạch S và O<sub>2</sub>.");
                return;
            }
            so2 += r.n * r.eff;
            Ok($"Bước 1 xong: S + O<sub>2</sub> → SO<sub>2</sub> (ngọn lửa xanh lam). +{r.n * r.eff:0.000} mol SO<sub>2</sub> (hiệu suất {r.eff * 100:0}%). Sang bước 2.");
            SetStep(1);
        }

        // ---------------- Bước 2
        private void StartContact()
        {
            if (so2 < 0.0001f) { result.text = "<color=#F2D35B>Chưa có SO<sub>2</sub> — làm bước 1 trước.</color>"; return; }
            float v = valve.Dispensed;
            var r = Evaluate(so2, v, 0.5f, cfg);
            valve.TakeAll();
            valve.CloseValve();
            if (!catalyst)
            {
                float lost = so2;
                so2 = 0f;
                Fail($"Không có xúc tác V<sub>2</sub>O<sub>5</sub> → phản ứng 2SO<sub>2</sub> + O<sub>2</sub> gần như không xảy ra, khí thoát ra ống khói. Mất {lost:0.000} mol SO<sub>2</sub> và {v:0.0} L O<sub>2</sub>.");
                return;
            }
            if (!r.ok)
            {
                float lost = so2;
                so2 = 0f;
                Fail($"Sai tỉ lệ ({(r.noGas ? "không có" : v > r.needL ? "thừa" : "thiếu")} O<sub>2</sub>). {lost:0.000} mol SO<sub>2</sub> cần {r.needMol:0.000} mol O<sub>2</sub> = {r.needL:0.00} L; " +
                     $"bạn nạp {v:0.00} L. Mất sạch SO<sub>2</sub> và O<sub>2</sub>.");
                return;
            }
            running = true;
            holdTime = 0f;
            contactEff = r.eff;
            runO2 = v;
            result.text = $"Tháp đang phản ứng… giữ nhiệt {cfg.contactTemp.x:0}–{cfg.contactTemp.y:0} °C đủ {cfg.contactHoldSeconds:0} giây. Phản ứng <b>toả nhiệt</b> — coi chừng quá nóng!";
        }

        private void TickContact(float dt)
        {
            float t = heater.Temp;
            if (t > cfg.contactFail.y || (holdTime > 0.5f && t < cfg.contactFail.x))
            {
                running = false;
                float lost = so2;
                so2 = 0f;
                Fail(t > cfg.contactFail.y
                    ? $"Quá nóng ({t:0} °C) → cân bằng 2SO<sub>2</sub> + O<sub>2</sub> → 2SO<sub>3</sub> chuyển dịch về phía SO<sub>2</sub> và xúc tác hỏng. Mất {lost:0.000} mol SO<sub>2</sub>."
                    : $"Tháp nguội xuống {t:0} °C → xúc tác ngừng hoạt động, phản ứng dừng. Mất {lost:0.000} mol SO<sub>2</sub>.");
                return;
            }
            bool inWindow = t >= cfg.contactTemp.x && t <= cfg.contactTemp.y;
            if (inWindow) holdTime += dt;
            holdFill.fillAmount = Mathf.Clamp01(holdTime / cfg.contactHoldSeconds);
            contactState.text = inWindow ? "<color=#6BE04F>Đang chuyển hoá…</color>" : t < cfg.contactTemp.x ? "Chưa đủ nóng" : "Quá nóng! giảm lửa";
            if (holdTime >= cfg.contactHoldSeconds)
            {
                running = false;
                float made = so2 * contactEff;
                so3 += made;
                so2 = 0f;
                holdFill.fillAmount = 0f;
                Ok($"Bước 2 xong: 2SO<sub>2</sub> + O<sub>2</sub> → 2SO<sub>3</sub> (xúc tác V<sub>2</sub>O<sub>5</sub>, toả nhiệt). +{made:0.000} mol SO<sub>3</sub> (hiệu suất {contactEff * 100:0}%). Sang bước 3.");
                SetStep(2);
            }
        }

        // ---------------- Bước 3
        private void AbsorbWater()
        {
            float lost = so3;
            so3 = 0f;
            Fail($"Hấp thụ SO<sub>3</sub> trực tiếp bằng nước toả nhiệt rất mạnh → tạo <b>sương mù axit</b> bay mất, không thu được. Mất {lost:0.000} mol SO<sub>3</sub>.\n" +
                 "<i>Trong công nghiệp người ta hấp thụ SO<sub>3</sub> bằng H<sub>2</sub>SO<sub>4</sub> đặc tạo oleum rồi mới pha loãng.</i>");
        }

        private void AbsorbAcid()
        {
            oleum += so3;
            Ok($"SO<sub>3</sub> được hấp thụ bằng H<sub>2</sub>SO<sub>4</sub> đặc → <b>oleum</b> H<sub>2</sub>SO<sub>4</sub>·nSO<sub>3</sub>. Giờ pha loãng oleum bằng nước.");
            so3 = 0f;
        }

        private void DiluteCorrect()
        {
            float n = oleum;
            oleum = 0f;
            station.AddMastery(Id);
            float bullets = n * cfg.acidBulletsPerMolH2SO4 + bulletCarry;
            int whole = Mathf.FloorToInt(bullets + 0.0001f);
            bulletCarry = bullets - whole;
            turret.Ammunition[(int)AmmoType.Acid] += whole;
            Ok($"<color=#6BE04F>THÀNH CÔNG!</color> Rót từ từ axit vào nước (đúng quy tắc an toàn) → H<sub>2</sub>SO<sub>4</sub> loãng, {n:0.000} mol.\n" +
               $"→ <color=#F2D35B>+{whole} đạn axit</color>");
        }

        private void DiluteWrong()
        {
            float lost = oleum;
            oleum = 0f;
            Fail($"Rót NƯỚC vào axit đặc → nước sôi tức thì, axit <b>bắn tung toé</b>! Mất {lost:0.000} mol oleum.\n<i>Quy tắc: luôn rót AXIT vào NƯỚC, từ từ.</i>");
        }

        private void Ok(string msg)
        {
            result.text = msg;
            station.Flash(true);
        }

        private void Fail(string why)
        {
            running = false;
            result.text = $"<color=#FF5A4A>THẤT BẠI.</color> {why}";
            station.Flash(false);
        }
    }
}
