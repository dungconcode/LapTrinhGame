using TMPro;
using UnityEngine;
using UnityEngine.UI;
using Underlab.Core;
using Underlab.Defense;

namespace Underlab.Lab
{
    /// <summary>
    /// Khay chất rắn + cân điện tử.
    ///   [+]/[-]: lấy quặng từ kho ra khay (1 cục = 1 mol) / trả lại.
    ///   Click đống chất trên khay: xúc 1 thìa lên cân (lượng ngẫu nhiên). Shift + click: gõ nhẹ vài hạt.
    ///   Chuột phải vào cân: hất bớt về khay.
    /// Cân đọc trễ và nhảy số khi vừa thay đổi => phải chờ số đứng yên mới biết chính xác.
    /// </summary>
    public class ScaleWidget
    {
        public float Grams { get; private set; }          // khối lượng thật trên cân
        public float TrayGrams { get; private set; }
        public float MolarMass { get; }

        private readonly LabConfig cfg;
        private readonly ResourceBank bank;
        private readonly ResourceType resource;
        private readonly string symbol;
        private readonly RectTransform pile, pan;
        private readonly TextMeshProUGUI trayText, readout;
        private readonly Image pileImg;
        private float shown, settleUntil;

        public ScaleWidget(Transform parent, Vector2 pos, LabConfig cfg, ResourceBank bank, ResourceType resource,
                           string symbol, float molarMass, string oreIcon)
        {
            this.cfg = cfg;
            this.bank = bank;
            this.resource = resource;
            this.symbol = symbol;
            MolarMass = molarMass;

            var root = LabUi.Img(parent, "Scale_" + symbol, "ui_panel", new Vector2(0, 1), pos, new Vector2(330, 420), null, null, true, 2f).transform;
            LabUi.Txt(root, "Title", $"CÂN CHẤT RẮN — {Chem.F(symbol)}", 18, LabUi.Teal, TextAlignmentOptions.TopLeft,
                new Vector2(0, 1), new Vector2(18, -14), new Vector2(300, 26));

            // Khay
            LabUi.Txt(root, "TrayLabel", "Khay (lấy từ kho):", 15, LabUi.Dim, TextAlignmentOptions.TopLeft,
                new Vector2(0, 1), new Vector2(18, -48), new Vector2(200, 22));
            LabUi.Btn(root, "−", new Vector2(0, 1), new Vector2(18, -72), new Vector2(44, 36), Unload);
            LabUi.Btn(root, "+", new Vector2(0, 1), new Vector2(68, -72), new Vector2(44, 36), Load);
            trayText = LabUi.Txt(root, "Tray", "", 15, Color.white, TextAlignmentOptions.Left,
                new Vector2(0, 1), new Vector2(122, -72), new Vector2(200, 36));

            pileImg = LabUi.Img(root, "Pile", oreIcon, new Vector2(0, 1), new Vector2(18, -120), new Vector2(110, 110));
            pile = pileImg.rectTransform;
            LabUi.Txt(root, "PileHint", "Click: xúc 1 thìa\nShift+click: gõ nhẹ\nChuột phải vào cân: hất bớt", 13, LabUi.Dim,
                TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(140, -126), new Vector2(180, 70));

            // Cân
            var panImg = LabUi.Img(root, "Pan", "ui_upgrade_node", new Vector2(0, 1), new Vector2(105, -246), new Vector2(120, 70), null, new Color(0.8f, 0.8f, 0.9f));
            pan = panImg.rectTransform;
            var body = LabUi.Img(root, "ScaleBody", "ui_bar_frame", new Vector2(0, 1), new Vector2(40, -320), new Vector2(250, 70), null, null, true, 2f);
            readout = LabUi.Txt(body.transform, "Readout", "0.00 g", 34, LabUi.Green, TextAlignmentOptions.Center,
                new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(250, 70), new Vector2(0.5f, 0.5f));
            LabUi.Btn(root, "Đổ bỏ", new Vector2(0, 1), new Vector2(110, -396), new Vector2(110, 30), Discard, null, 14);
            RefreshTray();
        }

        public void Tick(float dt)
        {
            if (LabUi.LeftDown && LabUi.Over(pile) && TrayGrams > 0.001f)
            {
                var r = LabUi.Shift ? cfg.tapGrams : cfg.scoopGrams;
                Move(Random.Range(r.x, r.y));
            }
            if (LabUi.RightDown && LabUi.Over(pan) && Grams > 0f)
                Move(-Mathf.Min(Grams, Random.Range(cfg.scoopGrams.x, cfg.scoopGrams.y)));

            // Số trên cân đuổi theo giá trị thật, rung nhẹ khi chưa ổn định
            float k = cfg.scaleLag > 0 ? 1f - Mathf.Exp(-dt / cfg.scaleLag) : 1f;
            shown = Mathf.Lerp(shown, Grams, k);
            float jitter = Time.time < settleUntil ? Random.Range(-0.08f, 0.08f) : 0f;
            readout.text = $"{Mathf.Max(0f, shown + jitter):0.00} g";
            readout.color = Time.time < settleUntil ? LabUi.Gold : LabUi.Green;
            pileImg.color = TrayGrams > 0.001f ? Color.white : new Color(1, 1, 1, 0.25f);
        }

        /// <summary>Lấy hết chất trên cân ra (phản ứng dùng hết / thất bại mất hết).</summary>
        public float TakeAll()
        {
            float g = Grams;
            Grams = 0f;
            settleUntil = Time.time + 0.6f;
            return g;
        }

        /// <summary>Quy trình tự động lấy thẳng từ khay (không qua cân).</summary>
        public void ConsumeTray(float grams)
        {
            TrayGrams = Mathf.Max(0f, TrayGrams - grams);
            RefreshTray();
        }

        /// <summary>Đóng phòng thí nghiệm: trả chất trên cân về khay, khay về kho (phần lẻ không đủ 1 cục bị bỏ).</summary>
        public int ReturnToBank()
        {
            TrayGrams += Grams;
            Grams = shown = 0f;
            float perOre = MolarMass * cfg.molPerOre;
            int ores = Mathf.FloorToInt(TrayGrams / perOre + 0.0001f);
            if (ores > 0) GameEvents.RaiseResourcesDeposited(resource, ores);
            TrayGrams = 0f;
            RefreshTray();
            return ores;
        }

        private void Move(float g)
        {
            g = g > 0 ? Mathf.Min(g, TrayGrams) : g;
            TrayGrams -= g;
            Grams = Mathf.Max(0f, Grams + g);
            settleUntil = Time.time + 0.6f;
            RefreshTray();
        }

        private void Load()
        {
            if (!bank.Spend(resource, 1)) return;
            TrayGrams += MolarMass * cfg.molPerOre;
            RefreshTray();
        }

        private void Unload()
        {
            float perOre = MolarMass * cfg.molPerOre;
            if (TrayGrams + 0.001f < perOre) return;
            TrayGrams -= perOre;
            GameEvents.RaiseResourcesDeposited(resource, 1);
            RefreshTray();
        }

        private void Discard()
        {
            TrayGrams += 0f;
            Grams = 0f;
            settleUntil = Time.time + 0.6f;
        }

        private void RefreshTray() =>
            trayText.text = $"{TrayGrams:0.0} g {Chem.F(symbol)}  (kho còn {bank.Balance(resource)})";
    }
}
