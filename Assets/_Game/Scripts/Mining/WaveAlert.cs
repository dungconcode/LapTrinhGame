using UnityEngine;
using UnityEngine.UI;
using Underlab.Core;
using Underlab.Player;

namespace Underlab.Mining
{
    /// <summary>
    /// A10 — Cảnh báo wave cho người đang ở DƯỚI ĐẤT:
    ///  - Từ lúc WaveWarning: bíp mỗi giây (3s cuối bíp cao + dồn), viền đỏ nhịp đập, rung nhẹ
    ///  - Khi wave bắt đầu mà vẫn dưới đất: banner "WAVE ĐẾN — VỀ BASE!", rung mạnh, viền đỏ giữ nguyên
    /// Ở trên mặt đất thì im (người chơi đã thấy đồng hồ).
    /// Âm thanh tạo bằng code (chưa cần file).
    /// </summary>
    public class WaveAlert : MonoBehaviour
    {
        [SerializeField] private PlayerController player;
        [SerializeField] private CameraFollow cameraFollow;
        [SerializeField] private Color vignetteColor = new Color(1f, 0.1f, 0.05f, 1f);
        [SerializeField, Range(0f, 1f)] private float vignetteMaxAlpha = 0.55f;
        [SerializeField, Range(0f, 1f)] private float volume = 0.35f;

        private AudioSource audioSource;
        private AudioClip beepLow, beepHigh;
        private RawImage vignette;
        private Text banner;
        private bool warning, defense;
        private int lastBeepSecond = -1;
        private float bannerTime;

        private bool Underground => player != null && player.Depth > 0;

        private void Awake()
        {
            audioSource = gameObject.AddComponent<AudioSource>();
            audioSource.playOnAwake = false;
            beepLow = MakeBeep(660f, 0.12f);
            beepHigh = MakeBeep(990f, 0.1f);
            BuildOverlay();
        }

        private void OnEnable()
        {
            GameEvents.WaveWarning += OnWarning;
            GameEvents.WaveCountdown += OnCountdown;
            GameEvents.PhaseChanged += OnPhase;
        }

        private void OnDisable()
        {
            GameEvents.WaveWarning -= OnWarning;
            GameEvents.WaveCountdown -= OnCountdown;
            GameEvents.PhaseChanged -= OnPhase;
        }

        private void OnWarning(int wave) => warning = true;

        private void OnCountdown(float seconds)
        {
            if (!warning || !Underground) return;
            int s = Mathf.CeilToInt(seconds);
            if (s == lastBeepSecond) return;
            lastBeepSecond = s;
            bool last = s <= 3;
            audioSource.PlayOneShot(last ? beepHigh : beepLow, volume);
            if (cameraFollow != null) cameraFollow.Shake(last ? 0.12f : 0.06f, 0.25f);
        }

        private void OnPhase(GamePhase p)
        {
            defense = p == GamePhase.Defense;
            if (p == GamePhase.Mining)
            {
                warning = false;
                lastBeepSecond = -1;
            }
            if (defense && Underground)
            {
                bannerTime = 2.5f;
                audioSource.PlayOneShot(beepHigh, volume);
                if (cameraFollow != null) cameraFollow.Shake(0.3f, 0.6f);
            }
        }

        private void Update()
        {
            bool show = (warning || defense) && Underground;
            float pulse = 0.5f + 0.5f * Mathf.Sin(Time.time * (defense ? 9f : 6f));
            var c = vignetteColor;
            c.a = show ? Mathf.Lerp(0.25f, 1f, pulse) * vignetteMaxAlpha : 0f;
            vignette.color = c;

            bannerTime -= Time.deltaTime;
            bool showBanner = bannerTime > 0f;
            if (banner.enabled != showBanner) banner.enabled = showBanner;
            if (showBanner) banner.transform.localScale = Vector3.one * (1f + 0.06f * pulse);
        }

        // ---------------- Tạo tài nguyên bằng code ----------------

        private static AudioClip MakeBeep(float freq, float seconds)
        {
            const int rate = 44100;
            int n = Mathf.CeilToInt(rate * seconds);
            var data = new float[n];
            for (int i = 0; i < n; i++)
            {
                float t = (float)i / rate;
                float env = Mathf.Min(1f, i / (rate * 0.005f)) * (1f - (float)i / n); // attack nhanh, nhỏ dần
                data[i] = Mathf.Sin(2f * Mathf.PI * freq * t) * env * 0.8f;
            }
            var clip = AudioClip.Create($"beep_{freq}", n, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        private void BuildOverlay()
        {
            var canvasGo = new GameObject("WaveAlertCanvas", typeof(Canvas), typeof(CanvasScaler));
            canvasGo.transform.SetParent(transform, false);
            var canvas = canvasGo.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 20;
            var scaler = canvasGo.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920, 1080);

            // Viền đỏ: texture trong suốt ở giữa, đậm dần ra mép
            var vgo = new GameObject("Vignette", typeof(RectTransform), typeof(RawImage));
            vgo.transform.SetParent(canvasGo.transform, false);
            var rt = (RectTransform)vgo.transform;
            rt.anchorMin = Vector2.zero;
            rt.anchorMax = Vector2.one;
            rt.offsetMin = rt.offsetMax = Vector2.zero;
            vignette = vgo.GetComponent<RawImage>();
            vignette.texture = MakeVignette(128);
            vignette.raycastTarget = false;
            vignette.color = Color.clear;

            var bgo = new GameObject("Banner", typeof(RectTransform), typeof(Text), typeof(Outline));
            bgo.transform.SetParent(canvasGo.transform, false);
            var brt = (RectTransform)bgo.transform;
            brt.anchorMin = brt.anchorMax = new Vector2(0.5f, 0.7f);
            brt.sizeDelta = new Vector2(1400, 140);
            banner = bgo.GetComponent<Text>();
            banner.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            banner.fontSize = 84;
            banner.fontStyle = FontStyle.Bold;
            banner.alignment = TextAnchor.MiddleCenter;
            banner.color = new Color(1f, 0.85f, 0.3f);
            banner.text = "WAVE ĐẾN — VỀ BASE!";
            banner.raycastTarget = false;
            banner.enabled = false;
            bgo.GetComponent<Outline>().effectColor = new Color(0.4f, 0f, 0f, 1f);
        }

        private static Texture2D MakeVignette(int size)
        {
            var tex = new Texture2D(size, size, TextureFormat.RGBA32, false) { wrapMode = TextureWrapMode.Clamp };
            var px = new Color32[size * size];
            for (int y = 0; y < size; y++)
            for (int x = 0; x < size; x++)
            {
                float dx = (x + 0.5f) / size * 2f - 1f, dy = (y + 0.5f) / size * 2f - 1f;
                float d = Mathf.Max(Mathf.Abs(dx), Mathf.Abs(dy)) * 0.6f + Mathf.Sqrt(dx * dx + dy * dy) * 0.4f;
                float a = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.6f, 1.05f, d));
                px[y * size + x] = new Color32(255, 255, 255, (byte)(a * 255));
            }
            tex.SetPixels32(px);
            tex.Apply();
            return tex;
        }
    }
}
