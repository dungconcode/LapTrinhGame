using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.UI;
using Underlab.Defense;
using Underlab.Mining;
using Underlab.Player;

namespace Underlab.Lab
{
    /// <summary>
    /// PHÒNG THÍ NGHIỆM ở base. Bấm T khi đứng ở base trong pha đào để mở/đóng.
    /// Đạn đặc biệt chỉ có được bằng cách tự làm thí nghiệm ở đây (xem FireExperiment...).
    /// Khi mở: khoá di chuyển/khoan của thợ mỏ và khoá pháo; thời gian vẫn trôi (áp lực pha đào).
    /// Tự tìm ResourceBank / Turret / DefenseShop trong scene — chỉ cần gắn component này vào 1 object.
    /// </summary>
    public class LabStation : MonoBehaviour
    {
        [SerializeField] private LabConfig config;

        public static bool IsOpen { get; private set; }
        public float O2Liters { get; set; }

        private ResourceBank bank;
        private Turret turret;
        private DefenseShop shop;
        private PlayerController player;
        private Drill drill;
        private GameObject canvasGo;
        private Image flashImg;
        private float flashUntil;
        private FireExperiment fire;
        private TextMeshProUGUI o2Text;
        private readonly Dictionary<string, int> mastery = new Dictionary<string, int>();

        public int Mastery(string id) => mastery.TryGetValue(id, out var n) ? n : 0;
        public void AddMastery(string id) => mastery[id] = Mastery(id) + 1;

        private void Awake()
        {
            if (config == null) config = ScriptableObject.CreateInstance<LabConfig>();
            O2Liters = config.o2Capacity * 0.5f;
            IsOpen = false;
        }

        private void Start()
        {
            bank = FindFirstObjectByType<ResourceBank>();
            turret = FindFirstObjectByType<Turret>();
            shop = FindFirstObjectByType<DefenseShop>();
            player = FindFirstObjectByType<PlayerController>(FindObjectsInactive.Include);
            if (player) drill = player.GetComponent<Drill>();
            if (bank == null || turret == null || shop == null)
                Debug.LogWarning("[Lab] Thiếu ResourceBank/Turret/DefenseShop trong scene — phòng thí nghiệm tắt.", this);
        }

        private void OnDisable()
        {
            if (IsOpen) SetOpen(false);
        }

        private void Update()
        {
            // Bình O₂ của base tự nạp dần (tạm thời, sau thay bằng điện phân nước)
            O2Liters = Mathf.Min(config.o2Capacity, O2Liters + config.o2RegenPerSecond * Time.deltaTime);
            if (bank == null || turret == null || shop == null) return;

            bool available = shop.Available && !turret.IsMounted;
            var k = Keyboard.current;
            if (k != null && k.tKey.wasPressedThisFrame && (available || IsOpen)) SetOpen(!IsOpen);
            if (IsOpen && !shop.Available) SetOpen(false);   // rời base / wave tới => đóng
            if (!IsOpen) return;

            fire.Tick(Time.deltaTime);
            o2Text.text = $"Bình O<sub>2</sub> của base: {O2Liters:0.0}/{config.o2Capacity:0} L  <color=#ffffff88>(+{config.o2RegenPerSecond:0.0} L/s)</color>";
            flashImg.enabled = Time.time < flashUntil;
            if (flashImg.enabled)
            {
                var c = flashImg.color;
                c.a = Mathf.Clamp01((flashUntil - Time.time) / 0.4f) * 0.35f;
                flashImg.color = c;
            }
        }

        public void SetOpen(bool open)
        {
            if (open == IsOpen) return;
            if (open && canvasGo == null) Build();
            IsOpen = open;
            canvasGo.SetActive(open);
            if (open) shop.Open = false;
            else fire.OnClose();
            if (player) player.enabled = !open;
            if (drill) drill.enabled = !open;
            if (player && open) player.Body.linearVelocity = Vector2.zero;
        }

        /// <summary>Nháy màn hình xanh (thành công) / đỏ (thất bại).</summary>
        public void Flash(bool success)
        {
            flashImg.color = success ? new Color(0.4f, 1f, 0.5f, 0.35f) : new Color(1f, 0.25f, 0.2f, 0.35f);
            flashUntil = Time.time + 0.4f;
        }

        private void Build()
        {
            canvasGo = new GameObject("Lab UI", typeof(RectTransform), typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            canvasGo.transform.SetParent(transform, false);
            var canvas = canvasGo.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 40;
            var scaler = canvasGo.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1280, 720);
            scaler.matchWidthOrHeight = 0.5f;

            var dim = LabUi.Img(canvasGo.transform, "Dim", null, Vector2.zero, Vector2.zero, Vector2.zero, null, new Color(0.03f, 0.02f, 0.08f, 0.92f));
            dim.rectTransform.anchorMin = Vector2.zero;
            dim.rectTransform.anchorMax = Vector2.one;
            dim.rectTransform.offsetMin = dim.rectTransform.offsetMax = Vector2.zero;
            dim.raycastTarget = true; // chặn click xuyên xuống game

            var root = LabUi.Rect(canvasGo.transform, "Root", new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(1280, 720), new Vector2(0.5f, 0.5f));
            LabUi.Txt(root, "Header", "PHÒNG THÍ NGHIỆM — <color=#E07A3F>ĐẠN LỬA</color>", 26, LabUi.Teal, TMPro.TextAlignmentOptions.TopLeft,
                new Vector2(0, 1), new Vector2(30, -18), new Vector2(700, 40));
            LabUi.Txt(root, "Close", "T: đóng   ·   thời gian vẫn trôi!", 15, LabUi.Dim, TMPro.TextAlignmentOptions.TopRight,
                new Vector2(1, 1), new Vector2(-30, -24), new Vector2(400, 30), new Vector2(1, 1));
            o2Text = LabUi.Txt(root, "O2", "", 15, LabUi.Dim, TMPro.TextAlignmentOptions.TopLeft,
                new Vector2(0, 1), new Vector2(30, -600), new Vector2(700, 26));

            fire = new FireExperiment(root, this, config, bank, turret);

            flashImg = LabUi.Img(canvasGo.transform, "Flash", null, Vector2.zero, Vector2.zero, Vector2.zero);
            flashImg.rectTransform.anchorMin = Vector2.zero;
            flashImg.rectTransform.anchorMax = Vector2.one;
            flashImg.rectTransform.offsetMin = flashImg.rectTransform.offsetMax = Vector2.zero;
            flashImg.enabled = false;
            canvasGo.SetActive(false);
        }
    }
}
