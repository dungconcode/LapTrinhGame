using Underlab.Core;
using Underlab.Defense;
using Underlab.Game;
using Underlab.Art;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Underlab.UI
{
    public class DefenseHud : MonoBehaviour
    {
        public GameManager game;
        public BaseHealth baseHealth;
        public ResourceBank bank;
        public DefenseShop shop;
        public Turret turret;
        private Vector2 scroll;
        private TextMeshProUGUI status;
        private TMP_FontAsset font;
        private GameObject canvasRoot;
        private void Awake()
        {
            canvasRoot = new GameObject("Defense HUD", typeof(Canvas), typeof(CanvasScaler));
            canvasRoot.transform.SetParent(transform);
            canvasRoot.GetComponent<Canvas>().renderMode = RenderMode.ScreenSpaceOverlay;
            var scaler = canvasRoot.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize; scaler.referenceResolution = new Vector2(1280, 720); scaler.matchWidthOrHeight = .5f;
            var label = new GameObject("Base and Bank", typeof(RectTransform), typeof(TextMeshProUGUI));
            label.transform.SetParent(canvasRoot.transform, false);
            status = label.GetComponent<TextMeshProUGUI>();
            font = TMP_FontAsset.CreateFontAsset(Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf"));
            status.font = font; status.fontSize = 20; status.raycastTarget = false;
            status.color = new Color(.65f, 1, 1);
            var rect = status.rectTransform; rect.anchorMin = rect.anchorMax = new Vector2(0, 0); rect.pivot = Vector2.zero;
            rect.anchoredPosition = new Vector2(20, 20); rect.sizeDelta = new Vector2(600, 90);
        }
        private void LateUpdate()
        {
            canvasRoot.SetActive(game.Started);
            status.text = $"BASE {baseHealth.Current}/{baseHealth.Maximum} | WAVE {Mathf.Min(game.Wave + 1, game.config.waves.Length)}/{game.config.waves.Length} | {game.Phase}\nFe {bank.Balance(ResourceType.Iron)}   S {bank.Balance(ResourceType.Sulfur)}   Mg {bank.Balance(ResourceType.Magnesium)}   KCl {bank.Balance(ResourceType.KCl)}\nE: cửa hàng tại base · Esc: tạm dừng";
        }
        private void OnDestroy() { if (font) Destroy(font); }
        private void OnGUI()
        {
            float scale = Mathf.Min(Screen.width / 1280f, Screen.height / 720f);
            GUI.matrix = Matrix4x4.TRS(Vector3.zero, Quaternion.identity, Vector3.one * scale);
            if (!game.Started)
            {
                GUI.Box(new Rect(390, 180, 500, 300), "UNDERLAB");
                GUI.Label(new Rect(420, 230, 440, 100), "Đào quặng • Trở về base • Sống qua 10 wave\nA/D di chuyển · Space bay · W/S khoan\nGần pháo: chuột trái để vào · Q thoát pháo\nTrong pháo: chuột trái bắn · 1–4 đổi đạn · E shop khi đi bộ");
                if (GUI.Button(new Rect(520, 370, 240, 55), "BẮT ĐẦU")) game.StartRun();
                return;
            }
            for (int i = 0; i < 4; i++)
            {
                GUI.enabled = !game.Paused;
                if (GUI.Button(new Rect(650 + i * 150, 650, 145, 45), $"{i + 1}: {(AmmoType)i} {(i == 0 ? "∞" : turret.Ammunition[i].ToString())}{((int)turret.Selected == i ? " ✓" : "")}")) turret.Select(i);
            }
            GUI.enabled = true;
            if (!game.Paused && (turret.IsMounted || turret.CanMount))
                GUI.Box(new Rect(410, 580, 460, 40), turret.IsMounted ? "ĐANG TRONG PHÁO · Chuột trái bắn · Q để thoát" : "CHUỘT TRÁI để vào pháo");
            if (!shop.Open && !game.Paused && turret.IsMounted)
            {
                var sprite = ArtDatabase.GetSprite("ui_crosshair");
                if (sprite != null)
                {
                    var point = Event.current.mousePosition;
                    var uv = sprite.textureRect;
                    GUI.DrawTextureWithTexCoords(new Rect(point.x - 16, point.y - 16, 32, 32), sprite.texture,
                        new Rect(uv.x / sprite.texture.width, uv.y / sprite.texture.height, uv.width / sprite.texture.width, uv.height / sprite.texture.height));
                }
            }
            foreach (var enemy in game.spawner.pool.Enemies)
                if (enemy.gameObject.activeSelf && enemy.Kind == EnemyKind.Boss)
                    GUI.Box(new Rect(350, 120, 580, 30), $"BOSS {enemy.Health:0}/{enemy.Maximum:0}");
            if (game.Paused || game.Phase == GamePhase.Victory || game.Phase == GamePhase.GameOver)
            {
                GUI.Box(new Rect(440, 220, 400, 240), game.Paused ? "TẠM DỪNG" : game.Phase == GamePhase.Victory ? "CHIẾN THẮNG" : "BASE ĐÃ BỊ PHÁ HỦY");
                if (game.Paused && GUI.Button(new Rect(500, 280, 280, 50), "TIẾP TỤC")) game.TogglePause();
                if (GUI.Button(new Rect(500, 350, 280, 50), "CHƠI LẠI")) game.Restart();
                return;
            }
            if (!shop.Open || !shop.Available) return;
            GUI.Box(new Rect(700, 140, 560, 550), "NÂNG CẤP & CHẾ TẠO");
            scroll = GUI.BeginScrollView(new Rect(715, 175, 530, 490), scroll, new Rect(0, 0, 500, shop.upgrades.Length * 42 + 140));
            int y = 0;
            foreach (var def in shop.upgrades)
            {
                GUI.Label(new Rect(0, y, 150, 36), def.displayName);
                for (int level = 0; level < (def.repeatable ? 1 : shop.MaxLevel(def)); level++)
                {
                    bool current = def.repeatable || level == shop.Level(def.id);
                    GUI.enabled = current && shop.CanBuy(def);
                    int cost = def.repeatable ? shop.Price(def) : def.ironCosts[level];
                    string text = !def.repeatable && level < shop.Level(def.id) ? "✓" : $"{cost} Fe";
                    if (GUI.Button(new Rect(150 + level * 66, y, 62, 36), new GUIContent(text, $"{def.displayName} · cấp {level + 1} · giá {cost} sắt"))) shop.Buy(def);
                }
                y += 42;
            }
            GUI.enabled = true;
            for (int i = 1; i < 4; i++)
            {
                var ammo = turret.pool.config.ammo[i];
                if (GUI.Button(new Rect(0, y, 490, 36), $"Chế {(AmmoType)i}: {ammo.craftCost} {(i == 1 ? "S" : i == 2 ? "Mg" : "KCl")} → {ammo.craftYield} viên")) turret.Craft(i);
                y += 42;
            }
            GUI.EndScrollView();
            if (!string.IsNullOrEmpty(GUI.tooltip)) GUI.Label(new Rect(700, 695, 560, 25), GUI.tooltip);
        }
    }
}
