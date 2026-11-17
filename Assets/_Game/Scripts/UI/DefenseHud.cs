using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.UI;
using UnityEngine.UI;
using Underlab.Art;
using Underlab.Core;
using Underlab.Defense;
using Underlab.Game;

namespace Underlab.UI
{
    /// <summary>
    /// HUD phòng thủ + shop + menu/tạm dừng/thắng/thua — uGUI, dùng bộ UI SVG (ui_*, icon_*).
    /// Tự dựng toàn bộ lúc Awake; tên field public giữ nguyên để prefab DefenseRoot không mất tham chiếu.
    /// Khung tham chiếu 1280x720 (Turret bỏ qua click ở 110px dưới cùng => thanh đạn nằm trong dải đó).
    /// </summary>
    public class DefenseHud : MonoBehaviour
    {
        public GameManager game;
        public BaseHealth baseHealth;
        public ResourceBank bank;
        public DefenseShop shop;
        public Turret turret;

        private static readonly Color Teal = new Color(0.25f, 0.88f, 0.82f);
        private static readonly Color Gold = new Color(0.95f, 0.83f, 0.36f);
        private static readonly Color Red = new Color(1f, 0.35f, 0.29f);
        private static readonly Color Dim = new Color(0.03f, 0.02f, 0.08f, 0.78f);
        private static readonly string[] AmmoIcons = { "icon_ammo_normal", "icon_ammo_acid", "icon_ammo_fire", "icon_ammo_ice" };
        private static readonly string[] AmmoNames = { "Thường", "Axit", "Lửa", "Băng" };
        private static readonly string[] OreIcons = { "icon_ore_iron", "icon_ore_sulfur", "icon_ore_mg", "icon_ore_kcl" };
        private static readonly string[] OreShort = { "Fe", "S", "Mg", "KCl" };

        private RectTransform root;
        private bool warnedBank;
        private GameObject hudGroup, menuGroup, overlayGroup, shopGroup, bossGroup, hintGroup;
        private TextMeshProUGUI waveText, hpText, hintText, bossText, overlayTitle;
        private Image hpFill, bossFill, crosshair, overlayBg;
        private readonly TextMeshProUGUI[] bankTexts = new TextMeshProUGUI[4];
        private readonly Image[] ammoSlots = new Image[4];
        private readonly TextMeshProUGUI[] ammoCounts = new TextMeshProUGUI[4];
        private Button resumeButton;
        private readonly List<ShopRow> shopRows = new List<ShopRow>();
        private readonly List<CraftRow> craftRows = new List<CraftRow>();

        private class ShopRow
        {
            public UpgradeDef def;
            public Image[] pips;
            public TextMeshProUGUI price;
            public Button buy;
        }

        private class CraftRow
        {
            public int ammo;
            public TextMeshProUGUI have;
            public Button craft;
        }

        // =====================================================================

        private void Awake()
        {
            EnsureEventSystem();
            var canvasGo = new GameObject("Defense HUD", typeof(RectTransform), typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            canvasGo.transform.SetParent(transform, false);
            var canvas = canvasGo.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 30; // trên MiningHud (10) và WaveAlert (20)
            var scaler = canvasGo.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1280, 720);
            scaler.matchWidthOrHeight = 0.5f;
            root = (RectTransform)canvasGo.transform;

            hudGroup = Group("HUD");
            BuildBasePanel();
            BuildAmmoBar();
            BuildHint();
            BuildBossBar();
            crosshair = Img(hudGroup.transform, "Crosshair", "ui_crosshair", new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(40, 40));
            crosshair.raycastTarget = false;

            shopGroup = Group("Shop");
            BuildShop();

            overlayGroup = Group("Overlay");
            BuildOverlay();

            menuGroup = Group("Menu");
            BuildMenu();
        }

        private void LateUpdate()
        {
            bool started = game.Started;
            bool ended = game.Phase == GamePhase.Victory || game.Phase == GamePhase.GameOver;
            menuGroup.SetActive(!started);
            hudGroup.SetActive(started);
            overlayGroup.SetActive(started && (game.Paused || ended));
            shopGroup.SetActive(started && !game.Paused && !ended && shop.Open && shop.Available);

            if (!started)
            {
                var k = Keyboard.current;
                if (k != null && (k.enterKey.wasPressedThisFrame || k.numpadEnterKey.wasPressedThisFrame)) game.StartRun();
                return;
            }

            RefreshBase();
            RefreshAmmo();
            RefreshHint(ended);
            RefreshBoss();
            RefreshCrosshair(ended);
            if (overlayGroup.activeSelf) RefreshOverlay();
            if (shopGroup.activeSelf) RefreshShop();
        }

        // ============================== HUD ==================================

        private void BuildBasePanel()
        {
            var panel = Img(hudGroup.transform, "BasePanel", "ui_panel", new Vector2(0, 0), new Vector2(12, 12), new Vector2(372, 96), new Vector2(0, 0));
            panel.type = Image.Type.Sliced;
            panel.pixelsPerUnitMultiplier = 3f; // viền 9-slice nhỏ lại cho hợp panel thấp
            var p = panel.transform;
            Txt(p, "Title", "BASE", 18, Teal, TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(16, -10), new Vector2(120, 24));
            waveText = Txt(p, "Wave", "WAVE 1/10", 18, Color.white, TextAlignmentOptions.TopRight, new Vector2(1, 1), new Vector2(-16, -10), new Vector2(200, 24), new Vector2(1, 1));

            var frame = Img(p, "HpFrame", "ui_bar_frame", new Vector2(0, 1), new Vector2(14, -36), new Vector2(344, 24));
            frame.type = Image.Type.Sliced;
            frame.pixelsPerUnitMultiplier = 2f;
            hpFill = Img(frame.transform, "HpFill", "ui_bar_fill", new Vector2(0, 0.5f), new Vector2(5, 0), new Vector2(334, 14), new Vector2(0, 0.5f));
            hpFill.type = Image.Type.Filled;
            hpFill.fillMethod = Image.FillMethod.Horizontal;
            hpText = Txt(frame.transform, "HpText", "500/500", 15, Color.white, TextAlignmentOptions.Center, new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(344, 24), new Vector2(0.5f, 0.5f));

            for (int i = 0; i < 4; i++)
            {
                var pos = new Vector2(16 + i * 88, -66);
                Img(p, OreIcons[i], OreIcons[i], new Vector2(0, 1), pos, new Vector2(24, 24));
                bankTexts[i] = Txt(p, OreShort[i], "0", 17, Color.white, TextAlignmentOptions.Left, new Vector2(0, 1), pos + new Vector2(28, 0), new Vector2(56, 24));
            }
        }

        private void BuildAmmoBar()
        {
            const float size = 70f, gap = 8f;
            var bar = new GameObject("AmmoBar", typeof(RectTransform));
            bar.transform.SetParent(hudGroup.transform, false);
            Place((RectTransform)bar.transform, new Vector2(0.5f, 0), new Vector2(0, 14), new Vector2(4 * size + 3 * gap, size), new Vector2(0.5f, 0));
            for (int i = 0; i < 4; i++)
            {
                int index = i;
                var slot = Img(bar.transform, "Slot" + i, "ui_ammo_slot", new Vector2(0, 0), new Vector2(i * (size + gap), 0), new Vector2(size, size), new Vector2(0, 0));
                ammoSlots[i] = slot;
                var btn = slot.gameObject.AddComponent<Button>();
                btn.targetGraphic = slot;
                btn.onClick.AddListener(() => turret.Select(index));
                var icon = Img(slot.transform, "Icon", AmmoIcons[i], new Vector2(0.5f, 0.5f), new Vector2(0, 3), new Vector2(38, 38), new Vector2(0.5f, 0.5f));
                icon.raycastTarget = false;
                Txt(slot.transform, "Key", (i + 1).ToString(), 14, Gold, TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(9, -6), new Vector2(20, 18));
                ammoCounts[i] = Txt(slot.transform, "Count", "∞", 15, Color.white, TextAlignmentOptions.BottomRight, new Vector2(1, 0), new Vector2(-8, 5), new Vector2(50, 20), new Vector2(1, 0));
            }
        }

        private void BuildHint()
        {
            var panel = Img(hudGroup.transform, "Hint", "ui_panel", new Vector2(0.5f, 0), new Vector2(0, 92), new Vector2(460, 34), new Vector2(0.5f, 0));
            panel.type = Image.Type.Sliced;
            panel.pixelsPerUnitMultiplier = 4f;
            panel.raycastTarget = false;
            hintGroup = panel.gameObject;
            hintText = Txt(panel.transform, "Text", "", 16, Color.white, TextAlignmentOptions.Center, new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(450, 30), new Vector2(0.5f, 0.5f));
        }

        private void BuildBossBar()
        {
            var frame = Img(hudGroup.transform, "BossBar", "ui_bar_frame", new Vector2(0.5f, 1), new Vector2(0, -16), new Vector2(560, 30), new Vector2(0.5f, 1));
            frame.type = Image.Type.Sliced;
            frame.pixelsPerUnitMultiplier = 2f;
            bossGroup = frame.gameObject;
            bossFill = Img(frame.transform, "Fill", "ui_bar_fill", new Vector2(0, 0.5f), new Vector2(6, 0), new Vector2(548, 18), new Vector2(0, 0.5f));
            bossFill.type = Image.Type.Filled;
            bossFill.fillMethod = Image.FillMethod.Horizontal;
            bossFill.color = new Color(0.7f, 0.35f, 1f);
            bossText = Txt(frame.transform, "Text", "BOSS", 16, Color.white, TextAlignmentOptions.Center, new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(560, 30), new Vector2(0.5f, 0.5f));
        }

        private void RefreshBase()
        {
            int total = game.config.waves.Length;
            waveText.text = $"WAVE {Mathf.Min(game.Wave + 1, total)}/{total}";
            float t = baseHealth.Maximum > 0 ? (float)baseHealth.Current / baseHealth.Maximum : 0f;
            hpFill.fillAmount = t;
            hpFill.color = t > 0.5f ? Color.Lerp(Gold, new Color(0.4f, 0.9f, 0.5f), (t - 0.5f) * 2f) : Color.Lerp(Red, Gold, t * 2f);
            hpText.text = $"{baseHealth.Current}/{baseHealth.Maximum}";
            if (bank == null)
            {
                if (!warnedBank) Debug.LogError("[DefenseHud] Thiếu tham chiếu ResourceBank", this);
                warnedBank = true;
                bank = FindFirstObjectByType<ResourceBank>();
                if (bank == null) return;
            }
            for (int i = 0; i < 4; i++)
            {
                if (bankTexts[i] == null) { if (!warnedBank) Debug.LogError($"[DefenseHud] bankTexts[{i}] null", this); warnedBank = true; continue; }
                bankTexts[i].text = bank.Balance((ResourceType)i).ToString();
            }
        }

        private void RefreshAmmo()
        {
            var normal = ArtDatabase.GetSprite("ui_ammo_slot");
            var selected = ArtDatabase.GetSprite("ui_ammo_slot_selected");
            for (int i = 0; i < 4; i++)
            {
                bool sel = (int)turret.Selected == i;
                ammoSlots[i].sprite = sel ? selected : normal;
                ammoSlots[i].rectTransform.localScale = Vector3.one * (sel ? 1.08f : 1f);
                int n = turret.Ammunition[i];
                ammoCounts[i].text = i == 0 ? "∞" : n.ToString();
                ammoCounts[i].color = i != 0 && n == 0 ? Red : Color.white;
            }
        }

        private void RefreshHint(bool ended)
        {
            string text = null;
            if (!game.Paused && !ended)
            {
                if (turret.IsMounted) text = "ĐANG TRONG PHÁO  ·  chuột trái: bắn  ·  1–4: đạn  ·  Q: ra";
                else if (turret.CanMount) text = "CHUỘT TRÁI để vào pháo";
                else if (shop.Available && !shop.Open) text = "E: cửa hàng nâng cấp   ·   T: phòng thí nghiệm";
            }
            hintGroup.SetActive(text != null);
            if (text != null) hintText.text = text;
        }

        private void RefreshBoss()
        {
            Enemy boss = null;
            foreach (var e in game.spawner.pool.Enemies)
                if (e.gameObject.activeSelf && e.Kind == EnemyKind.Boss) { boss = e; break; }
            bossGroup.SetActive(boss != null);
            if (boss == null) return;
            bossFill.fillAmount = boss.Maximum > 0 ? (float)boss.Health / boss.Maximum : 0f;
            bossText.text = $"NỮ HOÀNG  {boss.Health:0}/{boss.Maximum:0}";
        }

        private void RefreshCrosshair(bool ended)
        {
            bool show = turret.IsMounted && !shop.Open && !game.Paused && !ended && Mouse.current != null;
            crosshair.gameObject.SetActive(show);
            if (!show) return;
            RectTransformUtility.ScreenPointToLocalPointInRectangle(root, Mouse.current.position.ReadValue(), null, out var local);
            crosshair.rectTransform.anchoredPosition = local;
        }

        // ============================== SHOP =================================

        private void BuildShop()
        {
            var panel = Img(shopGroup.transform, "ShopPanel", "ui_panel", new Vector2(1, 0.5f), new Vector2(-16, 10), new Vector2(520, 560), new Vector2(1, 0.5f));
            panel.type = Image.Type.Sliced;
            var p = panel.transform;
            Txt(p, "Title", "NÂNG CẤP & CHẾ TẠO", 22, Teal, TextAlignmentOptions.TopLeft, new Vector2(0, 1), new Vector2(26, -20), new Vector2(360, 30));
            Txt(p, "Close", "E: đóng", 15, new Color(1, 1, 1, 0.6f), TextAlignmentOptions.TopRight, new Vector2(1, 1), new Vector2(-26, -24), new Vector2(120, 22), new Vector2(1, 1));

            // Vùng cuộn
            var view = new GameObject("Viewport", typeof(RectTransform), typeof(RectMask2D), typeof(Image));
            view.transform.SetParent(p, false);
            var viewRt = (RectTransform)view.transform;
            Place(viewRt, new Vector2(0, 1), new Vector2(20, -60), new Vector2(480, 480));
            view.GetComponent<Image>().color = new Color(0, 0, 0, 0.001f); // nhận cuộn chuột
            var content = new GameObject("Content", typeof(RectTransform), typeof(VerticalLayoutGroup), typeof(ContentSizeFitter));
            content.transform.SetParent(view.transform, false);
            var contentRt = (RectTransform)content.transform;
            contentRt.anchorMin = new Vector2(0, 1);
            contentRt.anchorMax = new Vector2(1, 1);
            contentRt.pivot = new Vector2(0.5f, 1);
            contentRt.sizeDelta = Vector2.zero;
            var layout = content.GetComponent<VerticalLayoutGroup>();
            layout.spacing = 6;
            layout.childControlHeight = false;
            layout.childForceExpandHeight = false;
            layout.childControlWidth = true;
            content.GetComponent<ContentSizeFitter>().verticalFit = ContentSizeFitter.FitMode.PreferredSize;
            var scroll = view.AddComponent<ScrollRect>();
            scroll.viewport = viewRt;
            scroll.content = contentRt;
            scroll.horizontal = false;
            scroll.movementType = ScrollRect.MovementType.Clamped;
            scroll.scrollSensitivity = 30f;

            if (shop.upgrades != null)
                foreach (var def in shop.upgrades)
                    if (def != null) shopRows.Add(BuildShopRow(content.transform, def));

            Section(content.transform, "ĐẠN ĐẶC BIỆT (làm thí nghiệm)");
            for (int i = 1; i < 4; i++) craftRows.Add(BuildCraftRow(content.transform, i));
        }

        private ShopRow BuildShopRow(Transform parent, UpgradeDef def)
        {
            var row = Row(parent, def.id);
            Img(row, "Icon", UpgradeIcon(def.id), new Vector2(0, 0.5f), new Vector2(4, 0), new Vector2(36, 36), new Vector2(0, 0.5f));
            Txt(row, "Name", def.displayName, 17, Color.white, TextAlignmentOptions.Left, new Vector2(0, 0.5f), new Vector2(48, 0), new Vector2(170, 30), new Vector2(0, 0.5f));

            var r = new ShopRow { def = def };
            int pipCount = def.repeatable ? 0 : Mathf.Max(1, shop.MaxLevel(def));
            r.pips = new Image[pipCount];
            for (int i = 0; i < pipCount; i++)
            {
                var pip = Img(row, "Pip" + i, "ui_bar_fill", new Vector2(0, 0.5f), new Vector2(222 + i * 18, 0), new Vector2(14, 14), new Vector2(0, 0.5f));
                r.pips[i] = pip;
            }

            var btnImg = Img(row, "Buy", "ui_button", new Vector2(1, 0.5f), new Vector2(-4, 0), new Vector2(118, 36), new Vector2(1, 0.5f));
            btnImg.type = Image.Type.Sliced;
            btnImg.pixelsPerUnitMultiplier = 2.5f;
            r.buy = MakeButton(btnImg);
            r.buy.onClick.AddListener(() => shop.Buy(def));
            r.price = Txt(btnImg.transform, "Price", "", 16, Color.white, TextAlignmentOptions.Center, new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(118, 36), new Vector2(0.5f, 0.5f));
            return r;
        }

        /// <summary>Đạn đặc biệt chỉ làm được bằng thí nghiệm => dòng hướng dẫn thay cho nút chế.</summary>
        private CraftRow BuildCraftRow(Transform parent, int ammo)
        {
            var row = Row(parent, "craft" + ammo);
            Img(row, "Icon", AmmoIcons[ammo], new Vector2(0, 0.5f), new Vector2(4, 0), new Vector2(36, 36), new Vector2(0, 0.5f));
            Txt(row, "Lab", $"Đạn {AmmoNames[ammo]}: tự làm thí nghiệm ở <color=#3FE0D0>PHÒNG THÍ NGHIỆM (phím T)</color>", 15, Color.white,
                TextAlignmentOptions.Left, new Vector2(0, 0.5f), new Vector2(48, 0), new Vector2(420, 30), new Vector2(0, 0.5f));
            return new CraftRow { ammo = ammo, have = null, craft = null };
        }

        private void RefreshShop()
        {
            foreach (var r in shopRows)
            {
                int level = shop.Level(r.def.id);
                int max = shop.MaxLevel(r.def);
                for (int i = 0; i < r.pips.Length; i++)
                    r.pips[i].color = i < level ? Teal : new Color(1, 1, 1, 0.15f);
                bool maxed = !r.def.repeatable && level >= max;
                r.buy.interactable = !maxed && shop.CanBuy(r.def);
                r.price.text = maxed ? "TỐI ĐA" : $"{shop.Price(r.def)} Fe";
                r.price.color = maxed ? Teal : r.buy.interactable ? Color.white : Red;
            }
            foreach (var c in craftRows)
            {
                if (c.craft == null) continue;
                var cfg = turret.pool.config.ammo[c.ammo];
                c.have.text = $"có {turret.Ammunition[c.ammo]}";
                c.craft.interactable = shop.Available && bank.Balance((ResourceType)c.ammo) >= cfg.craftCost;
            }
        }

        private static string UpgradeIcon(string id)
        {
            switch (id)
            {
                case UpgradeIds.Drill: return "icon_up_drill";
                case UpgradeIds.Move: return "icon_up_move";
                case UpgradeIds.Carry: return "icon_up_carry";
                case UpgradeIds.Jetpack: return "icon_up_jetpack";
                case UpgradeIds.Lift: return "icon_lift";
                case UpgradeIds.Blast: return "icon_blast";
                case "turret_damage": return "icon_up_turret_dmg";
                case "turret_rotate": return "icon_up_turret_rot";
                case "base_hp": return "icon_up_base_hp";
                case "repair": return "icon_repair";
                default: return "icon_up_drill";
            }
        }

        // ========================= MENU / OVERLAY ============================

        private void BuildMenu()
        {
            Stretch(Img(menuGroup.transform, "Dim", null, Vector2.zero, Vector2.zero, Vector2.zero)).color = new Color(0.04f, 0.03f, 0.1f, 1f);
            var bg = Stretch(Img(menuGroup.transform, "Background", "ui_bg_mainmenu", Vector2.zero, Vector2.zero, Vector2.zero));
            bg.color = new Color(1, 1, 1, 0.55f);
            bg.preserveAspect = false;
            var logo = Img(menuGroup.transform, "Logo", "ui_logo", new Vector2(0.5f, 1), new Vector2(0, -40), new Vector2(480, 240), new Vector2(0.5f, 1));
            logo.preserveAspect = true;

            var panel = Img(menuGroup.transform, "Controls", "ui_panel", new Vector2(0.5f, 0.5f), new Vector2(0, -60), new Vector2(560, 210), new Vector2(0.5f, 0.5f));
            panel.type = Image.Type.Sliced;
            panel.pixelsPerUnitMultiplier = 1.5f;
            Txt(panel.transform, "Text",
                "<color=#3FE0D0>Đào quặng · Về base · Sống qua 10 wave</color>\n" +
                "A/D: đi   ·   Space: bay   ·   W/S: khoan\n" +
                "E: cửa hàng ở base   ·   Esc: tạm dừng\n" +
                "Gần pháo: chuột trái để vào  ·  1–4: đạn  ·  Q: ra",
                18, Color.white, TextAlignmentOptions.Center, new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(520, 180), new Vector2(0.5f, 0.5f));

            BigButton(menuGroup.transform, "BẮT ĐẦU", new Vector2(0, 90), () => game.StartRun());
            Txt(menuGroup.transform, "EnterHint", "(hoặc Enter)", 14, new Color(1, 1, 1, 0.5f), TextAlignmentOptions.Center,
                new Vector2(0.5f, 0), new Vector2(0, 66), new Vector2(200, 20), new Vector2(0.5f, 0));
        }

        private void BuildOverlay()
        {
            Stretch(Img(overlayGroup.transform, "Dim", null, Vector2.zero, Vector2.zero, Vector2.zero)).color = Dim;
            overlayBg = Stretch(Img(overlayGroup.transform, "EndArt", null, Vector2.zero, Vector2.zero, Vector2.zero));
            overlayBg.color = new Color(1, 1, 1, 0.5f);

            var panel = Img(overlayGroup.transform, "Panel", "ui_panel", new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(440, 300), new Vector2(0.5f, 0.5f));
            panel.type = Image.Type.Sliced;
            overlayTitle = Txt(panel.transform, "Title", "TẠM DỪNG", 32, Teal, TextAlignmentOptions.Center, new Vector2(0.5f, 1), new Vector2(0, -34), new Vector2(400, 44), new Vector2(0.5f, 1));
            resumeButton = BigButton(panel.transform, "TIẾP TỤC", new Vector2(0, 112), () => game.TogglePause(), new Vector2(0.5f, 0));
            BigButton(panel.transform, "CHƠI LẠI", new Vector2(0, 36), () => game.Restart(), new Vector2(0.5f, 0));
        }

        private void RefreshOverlay()
        {
            bool win = game.Phase == GamePhase.Victory, lose = game.Phase == GamePhase.GameOver;
            overlayTitle.text = win ? "CHIẾN THẮNG!" : lose ? "BASE ĐÃ BỊ PHÁ HỦY" : "TẠM DỪNG";
            overlayTitle.color = win ? Gold : lose ? Red : Teal;
            resumeButton.gameObject.SetActive(game.Paused && !win && !lose);
            var art = win ? ArtDatabase.GetSprite("ui_screen_victory") : lose ? ArtDatabase.GetSprite("ui_screen_gameover") : null;
            overlayBg.sprite = art;
            overlayBg.enabled = art != null;
        }

        // ============================== HELPERS ==============================

        private static void EnsureEventSystem()
        {
            if (FindFirstObjectByType<EventSystem>() != null) return;
            var es = new GameObject("EventSystem", typeof(EventSystem), typeof(InputSystemUIInputModule));
            es.GetComponent<InputSystemUIInputModule>().AssignDefaultActions(); // tạo bằng code => phải gán action UI mặc định
        }

        private GameObject Group(string name)
        {
            var go = new GameObject(name, typeof(RectTransform));
            go.transform.SetParent(root, false);
            Stretch((RectTransform)go.transform);
            return go;
        }

        private static void Place(RectTransform rt, Vector2 anchor, Vector2 pos, Vector2 size, Vector2? pivot = null)
        {
            rt.anchorMin = rt.anchorMax = anchor;
            rt.pivot = pivot ?? new Vector2(0, 1);
            rt.anchoredPosition = pos;
            rt.sizeDelta = size;
        }

        private static void Stretch(RectTransform rt)
        {
            rt.anchorMin = Vector2.zero;
            rt.anchorMax = Vector2.one;
            rt.offsetMin = rt.offsetMax = Vector2.zero;
        }

        private static Image Stretch(Image img)
        {
            Stretch(img.rectTransform);
            return img;
        }

        private static Image Img(Transform parent, string name, string artId, Vector2 anchor, Vector2 pos, Vector2 size, Vector2? pivot = null)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Image));
            go.transform.SetParent(parent, false);
            Place((RectTransform)go.transform, anchor, pos, size, pivot);
            var img = go.GetComponent<Image>();
            if (artId != null) img.sprite = ArtDatabase.GetSprite(artId);
            img.raycastTarget = false;
            return img;
        }

        private static TextMeshProUGUI Txt(Transform parent, string name, string text, float size, Color color,
                                           TextAlignmentOptions align, Vector2 anchor, Vector2 pos, Vector2 box, Vector2? pivot = null)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(TextMeshProUGUI));
            go.transform.SetParent(parent, false);
            Place((RectTransform)go.transform, anchor, pos, box, pivot);
            var t = go.GetComponent<TextMeshProUGUI>();
            t.font = GameFonts.MainTMP;
            t.fontSize = size;
            t.color = color;
            t.alignment = align;
            t.text = text;
            t.raycastTarget = false;
            t.richText = true;
            return t;
        }

        private static Button MakeButton(Image img)
        {
            img.raycastTarget = true;
            var b = img.gameObject.AddComponent<Button>();
            b.targetGraphic = img;
            var c = b.colors;
            c.normalColor = Color.white;
            c.highlightedColor = new Color(1.15f, 1.15f, 1.15f);
            c.pressedColor = new Color(0.75f, 0.75f, 0.8f);
            c.disabledColor = new Color(0.45f, 0.45f, 0.5f, 0.8f);
            c.colorMultiplier = 1.2f;
            b.colors = c;
            return b;
        }

        private static Button BigButton(Transform parent, string label, Vector2 pos, UnityEngine.Events.UnityAction onClick, Vector2? anchor = null)
        {
            var a = anchor ?? new Vector2(0.5f, 0);
            var img = Img(parent, label, "ui_button", a, pos, new Vector2(260, 62), new Vector2(0.5f, 0));
            img.type = Image.Type.Sliced;
            img.pixelsPerUnitMultiplier = 1.5f;
            var b = MakeButton(img);
            b.onClick.AddListener(onClick);
            Txt(img.transform, "Label", label, 24, Color.white, TextAlignmentOptions.Center, new Vector2(0.5f, 0.5f), new Vector2(0, 2), new Vector2(260, 62), new Vector2(0.5f, 0.5f));
            return b;
        }

        private static Transform Row(Transform parent, string name)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(LayoutElement));
            go.transform.SetParent(parent, false);
            ((RectTransform)go.transform).sizeDelta = new Vector2(0, 46);
            go.GetComponent<LayoutElement>().preferredHeight = 46;
            var bg = go.AddComponent<Image>();
            bg.color = new Color(1, 1, 1, 0.04f);
            bg.raycastTarget = false;
            return go.transform;
        }

        private static void Section(Transform parent, string title)
        {
            var go = new GameObject("Section", typeof(RectTransform), typeof(LayoutElement));
            go.transform.SetParent(parent, false);
            go.GetComponent<LayoutElement>().preferredHeight = 34;
            Txt(go.transform, "Title", title, 16, Gold, TextAlignmentOptions.BottomLeft, new Vector2(0, 0), new Vector2(4, 2), new Vector2(400, 28), new Vector2(0, 0));
        }
    }
}
