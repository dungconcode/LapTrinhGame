using UnityEngine;
using UnityEngine.UI;
using Underlab.Art;
using Underlab.Core;
using Underlab.Mining;

namespace Underlab.UI
{
    /// <summary>
    /// HUD phần đào (A09). Tự dựng UI bằng code lúc chạy — sprite lấy theo art id nên thay art là tự đổi.
    ///  Trái trên: thanh tải + số quặng đang mang
    ///  Phải trên: đồng hồ wave (tròn) + số giây + độ sâu
    /// Chỉ nghe GameEvents + đọc Carrier (cùng phần Dev A).
    /// </summary>
    public class MiningHud : MonoBehaviour
    {
        [SerializeField] private Carrier carrier;
        [SerializeField] private Color loadLow = new Color(0.35f, 0.9f, 0.5f);
        [SerializeField] private Color loadMid = new Color(1f, 0.75f, 0.25f);
        [SerializeField] private Color loadHigh = new Color(1f, 0.3f, 0.25f);

        private static Font font;
        private Image loadFill, timerFill;
        private Text loadText, timerText, waveText, depthText;
        private readonly Text[] oreTexts = new Text[4];
        private float countdownMax = 60f;
        private bool warning;
        private int waveIndex = 1, nextWave = 1;

        private void Awake()
        {
            if (font == null) font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            BuildUi();
        }

        private void OnEnable()
        {
            GameEvents.CarryWeightChanged += OnWeight;
            GameEvents.DepthChanged += OnDepth;
            GameEvents.WaveCountdown += OnCountdown;
            GameEvents.WaveWarning += OnWarning;
            GameEvents.PhaseChanged += OnPhase;
            GameEvents.WaveStarted += OnWaveStarted;
            GameEvents.WaveCleared += OnWaveCleared;
            if (carrier != null) carrier.Changed += RefreshOres;
        }

        private void OnDisable()
        {
            GameEvents.CarryWeightChanged -= OnWeight;
            GameEvents.DepthChanged -= OnDepth;
            GameEvents.WaveCountdown -= OnCountdown;
            GameEvents.WaveWarning -= OnWarning;
            GameEvents.PhaseChanged -= OnPhase;
            GameEvents.WaveStarted -= OnWaveStarted;
            GameEvents.WaveCleared -= OnWaveCleared;
            if (carrier != null) carrier.Changed -= RefreshOres;
        }

        // ---------------- Event ----------------

        private void OnWeight(float cur, float max)
        {
            float t = max > 0 ? Mathf.Clamp01(cur / max) : 1f;
            loadFill.fillAmount = t;
            loadFill.color = t < 0.6f ? Color.Lerp(loadLow, loadMid, t / 0.6f) : Color.Lerp(loadMid, loadHigh, (t - 0.6f) / 0.4f);
            loadText.text = $"TẢI  {cur:0.#} / {max:0.#}";
        }

        private void OnDepth(int d) => depthText.text = d <= 0 ? "MẶT ĐẤT" : $"ĐỘ SÂU  {d} m";

        private void OnCountdown(float s)
        {
            if (s > countdownMax) countdownMax = s;
            timerFill.fillAmount = countdownMax > 0 ? s / countdownMax : 0f;
            timerText.text = Mathf.CeilToInt(s).ToString();
            var c = warning ? Color.Lerp(Color.white, loadHigh, 0.5f + 0.5f * Mathf.Sin(Time.time * 10f)) : Color.white;
            timerText.color = c;
            timerFill.color = warning ? loadHigh : new Color(0.4f, 0.9f, 1f);
        }

        private void OnWarning(int wave) => warning = true;

        private void OnWaveStarted(int wave) => waveIndex = wave;
        private void OnWaveCleared(int wave) => nextWave = wave + 1;

        private void OnPhase(GamePhase p)
        {
            if (p == GamePhase.Mining)
            {
                warning = false;
                countdownMax = 0f;
                waveText.text = $"WAVE {nextWave} TỚI SAU";
            }
            else if (p == GamePhase.Defense)
            {
                timerFill.fillAmount = 0f;
                timerText.text = "!";
                waveText.text = $"WAVE {waveIndex} ĐANG TẤN CÔNG";
            }
        }

        private void RefreshOres()
        {
            for (int i = 0; i < oreTexts.Length; i++)
                oreTexts[i].text = carrier.Get((ResourceType)i).ToString();
        }

        // ---------------- Dựng UI ----------------

        private void BuildUi()
        {
            var canvasGo = new GameObject("MiningHudCanvas", typeof(Canvas), typeof(CanvasScaler));
            canvasGo.transform.SetParent(transform, false);
            var canvas = canvasGo.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 10;
            var scaler = canvasGo.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920, 1080);
            scaler.matchWidthOrHeight = 0.5f;
            var root = canvasGo.transform;

            // --- Thanh tải (trái trên)
            var frame = MakeImage(root, "LoadFrame", "ui_bar_frame", new Vector2(0, 1), new Vector2(40, -40), new Vector2(460, 56));
            frame.type = Image.Type.Sliced;
            loadFill = MakeImage(frame.transform, "LoadFill", "ui_bar_fill", new Vector2(0, 0.5f), new Vector2(8, 0), new Vector2(444, 40));
            loadFill.rectTransform.pivot = new Vector2(0, 0.5f);
            loadFill.type = Image.Type.Filled;
            loadFill.fillMethod = Image.FillMethod.Horizontal;
            loadFill.fillAmount = 0f;
            loadText = MakeText(frame.transform, "LoadText", "TẢI 0 / 10", 26, TextAnchor.MiddleCenter, new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(444, 40));

            // --- Số quặng đang mang
            string[] icons = { "icon_ore_iron", "icon_ore_sulfur", "icon_ore_mg", "icon_ore_kcl" };
            for (int i = 0; i < icons.Length; i++)
            {
                var pos = new Vector2(40 + i * 115, -110);
                MakeImage(root, icons[i], icons[i], new Vector2(0, 1), pos, new Vector2(48, 48));
                oreTexts[i] = MakeText(root, icons[i] + "_n", "0", 30, TextAnchor.MiddleLeft, new Vector2(0, 1), pos + new Vector2(56, 0), new Vector2(60, 48));
            }

            // --- Đồng hồ wave (phải trên)
            var timerBg = MakeImage(root, "WaveTimer", "ui_wave_timer", new Vector2(1, 1), new Vector2(-40, -40), new Vector2(150, 150));
            timerBg.rectTransform.pivot = new Vector2(1, 1);
            timerFill = MakeImage(timerBg.transform, "WaveTimerFill", "ui_bar_fill", new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(120, 120));
            timerFill.rectTransform.pivot = new Vector2(0.5f, 0.5f);
            timerFill.type = Image.Type.Filled;
            timerFill.fillMethod = Image.FillMethod.Radial360;
            timerFill.fillOrigin = (int)Image.Origin360.Top;
            timerFill.fillClockwise = false;
            timerText = MakeText(timerBg.transform, "WaveTimerText", "--", 54, TextAnchor.MiddleCenter, new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(150, 150));
            timerText.rectTransform.pivot = new Vector2(0.5f, 0.5f);

            waveText = MakeText(root, "WaveText", "WAVE 1 TỚI SAU", 26, TextAnchor.MiddleRight, new Vector2(1, 1), new Vector2(-40, -200), new Vector2(460, 40));
            waveText.rectTransform.pivot = new Vector2(1, 1);
            depthText = MakeText(root, "DepthText", "MẶT ĐẤT", 34, TextAnchor.MiddleRight, new Vector2(1, 1), new Vector2(-40, -245), new Vector2(460, 44));
            depthText.rectTransform.pivot = new Vector2(1, 1);
        }

        private static Image MakeImage(Transform parent, string name, string artId, Vector2 anchor, Vector2 pos, Vector2 size)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Image));
            go.transform.SetParent(parent, false);
            var rt = (RectTransform)go.transform;
            rt.anchorMin = rt.anchorMax = anchor;
            rt.pivot = new Vector2(0, 1);
            rt.anchoredPosition = pos;
            rt.sizeDelta = size;
            var img = go.GetComponent<Image>();
            img.sprite = ArtDatabase.GetSprite(artId);
            img.raycastTarget = false;
            return img;
        }

        private static Text MakeText(Transform parent, string name, string text, int size, TextAnchor align,
                                     Vector2 anchor, Vector2 pos, Vector2 box)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Text), typeof(Outline));
            go.transform.SetParent(parent, false);
            var rt = (RectTransform)go.transform;
            rt.anchorMin = rt.anchorMax = anchor;
            rt.pivot = new Vector2(0, 1);
            rt.anchoredPosition = pos;
            rt.sizeDelta = box;
            var t = go.GetComponent<Text>();
            t.font = font;
            t.fontSize = size;
            t.fontStyle = FontStyle.Bold;
            t.alignment = align;
            t.color = Color.white;
            t.text = text;
            t.raycastTarget = false;
            go.GetComponent<Outline>().effectColor = new Color(0, 0, 0, 0.8f);
            return t;
        }
    }
}
