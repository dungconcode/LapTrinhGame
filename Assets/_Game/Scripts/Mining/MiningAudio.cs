using UnityEngine;
using Underlab.Core;
using Underlab.Player;

namespace Underlab.Mining
{
    /// <summary>
    /// A15 — Âm thanh phần đào: khoan (loop), vỡ đất, nhặt quặng, gửi kho, jetpack (loop), tiếp đất, vứt quặng.
    /// Gắn lên Player. Tự tìm Drill/Carrier/PlayerJuice cùng object; config có thể để trống.
    /// Âm thanh tổng hợp bằng code => chưa cần file; có file thật thì gán trong MiningAudioConfig.
    /// </summary>
    [RequireComponent(typeof(PlayerController))]
    public class MiningAudio : MonoBehaviour
    {
        [SerializeField] private MiningAudioConfig config;

        private PlayerController player;
        private Drill drill;
        private Carrier carrier;
        private PlayerJuice juice;
        private AudioSource oneShot, drillSrc, jetSrc;
        private AudioClip cDrill, cBreak, cPickup, cDeposit, cJet, cLand, cDrop;
        private float lastDeposit;
        private const int Rate = 44100;

        private float Master => config != null ? config.masterVolume : 0.6f;

        private void Awake()
        {
            player = GetComponent<PlayerController>();
            drill = GetComponent<Drill>();
            carrier = GetComponent<Carrier>();
            juice = GetComponent<PlayerJuice>();
            if (config == null) config = ScriptableObject.CreateInstance<MiningAudioConfig>();

            cDrill = config.drillLoop ? config.drillLoop : MakeDrillLoop();
            cBreak = config.blockBreak ? config.blockBreak : MakeBreak();
            cPickup = config.orePickup ? config.orePickup : MakeSweep(700f, 1250f, 0.11f, 0.5f);
            cDeposit = config.deposit ? config.deposit : MakeArpeggio();
            cJet = config.jetpackLoop ? config.jetpackLoop : MakeJetLoop();
            cLand = config.land ? config.land : MakeThump(85f, 0.14f);
            cDrop = config.oreDrop ? config.oreDrop : MakeSweep(420f, 240f, 0.1f, 0.45f);

            oneShot = NewSource(false, null);
            drillSrc = NewSource(true, cDrill);
            jetSrc = NewSource(true, cJet);
        }

        private void OnEnable()
        {
            if (drill != null) drill.OnCellBroken += OnBroken;
            if (carrier != null) carrier.PickedUp += OnPickedUp;
            if (juice != null) juice.Landed += OnLanded;
            GameEvents.ResourcesDeposited += OnDeposited;
            // Player bị tắt/bật (lên/xuống pháo) làm AudioSource dừng => chạy lại loop
            if (drillSrc != null && !drillSrc.isPlaying) drillSrc.Play();
            if (jetSrc != null && !jetSrc.isPlaying) jetSrc.Play();
        }

        private void OnDisable()
        {
            if (drill != null) drill.OnCellBroken -= OnBroken;
            if (carrier != null) carrier.PickedUp -= OnPickedUp;
            if (juice != null) juice.Landed -= OnLanded;
            GameEvents.ResourcesDeposited -= OnDeposited;
            if (drillSrc != null) drillSrc.volume = 0f;
            if (jetSrc != null) jetSrc.volume = 0f;
        }

        /// <summary>Gọi từ code khác (vd OreDropper) để phát tiếng vứt quặng.</summary>
        public void PlayDrop() => Play(cDrop, 0.4f);

        private void Update()
        {
            // Loop: kéo âm lượng lên/xuống mượt thay vì bật/tắt cụt
            bool drilling = drill != null && drill.IsDrilling;
            Fade(drillSrc, drilling ? config.drillVolume * Master : 0f, 12f);
            drillSrc.pitch = drilling ? 1f + 0.05f * Mathf.Sin(Time.time * 7f) : 1f;

            bool jet = player.IsThrusting;
            Fade(jetSrc, jet ? config.jetpackVolume * Master : 0f, 8f);
            jetSrc.pitch = Mathf.Lerp(jetSrc.pitch, jet ? 1f + Mathf.Clamp01(player.Body.linearVelocity.y / 6f) * 0.25f : 0.9f, Time.deltaTime * 6f);
        }

        private void OnBroken(Vector3Int cell, TerrainCell data) => Play(cBreak, config.breakVolume, data.kind == TileKind.Ore ? 1.15f : 1f);
        private void OnPickedUp(ResourceType t, int n) => Play(cPickup, config.pickupVolume, 1f + 0.08f * (int)t);
        private void OnLanded(float speed) => Play(cLand, config.landVolume * Mathf.Clamp01(speed / 10f));

        private void OnDeposited(ResourceType t, int n)
        {
            if (Time.time - lastDeposit < 0.4f) return; // đổ nhiều loại cùng lúc => 1 tiếng
            lastDeposit = Time.time;
            Play(cDeposit, config.depositVolume);
        }

        private void Play(AudioClip clip, float volume, float pitch = 1f)
        {
            if (clip == null || oneShot == null) return;
            oneShot.pitch = pitch * Random.Range(0.95f, 1.05f);
            oneShot.PlayOneShot(clip, volume * Master);
        }

        private AudioSource NewSource(bool loop, AudioClip clip)
        {
            var s = gameObject.AddComponent<AudioSource>();
            s.playOnAwake = false;
            s.loop = loop;
            s.clip = clip;
            s.spatialBlend = 0f;
            if (loop) { s.volume = 0f; s.Play(); }
            return s;
        }

        private static void Fade(AudioSource s, float target, float speed) =>
            s.volume = Mathf.MoveTowards(s.volume, target, speed * 0.1f * Time.deltaTime);

        // ---------------- Âm tổng hợp ----------------

        private static AudioClip Clip(string name, float[] data)
        {
            var c = AudioClip.Create(name, data.Length, 1, Rate, false);
            c.SetData(data, 0);
            return c;
        }

        private static AudioClip MakeDrillLoop()
        {
            // 0.5s lặp: răng cưa 110Hz + nhiễu, rung 32Hz. Tần số chia hết cho độ dài => lặp không vấp.
            int n = Rate / 2;
            var d = new float[n];
            var rng = new System.Random(1);
            for (int i = 0; i < n; i++)
            {
                float t = (float)i / Rate;
                float saw = 2f * (t * 110f % 1f) - 1f;
                float noise = (float)rng.NextDouble() * 2f - 1f;
                float am = 0.65f + 0.35f * Mathf.Sin(2f * Mathf.PI * 32f * t);
                d[i] = (saw * 0.35f + noise * 0.25f) * am;
            }
            return Clip("drill_loop", d);
        }

        private static AudioClip MakeJetLoop()
        {
            // nhiễu lọc thấp (1 cực) — tiếng phụt khí
            int n = Rate;
            var d = new float[n];
            var rng = new System.Random(2);
            float y = 0f;
            for (int i = 0; i < n; i++)
            {
                float x = (float)rng.NextDouble() * 2f - 1f;
                y += 0.08f * (x - y);
                d[i] = y * 1.6f;
            }
            // làm mềm chỗ nối đầu/cuối
            int fade = Rate / 50;
            for (int i = 0; i < fade; i++)
            {
                float k = (float)i / fade;
                d[i] *= k;
                d[n - 1 - i] *= k;
            }
            return Clip("jet_loop", d);
        }

        private static AudioClip MakeBreak()
        {
            int n = (int)(Rate * 0.26f);
            var d = new float[n];
            var rng = new System.Random(3);
            float y = 0f;
            for (int i = 0; i < n; i++)
            {
                float t = (float)i / Rate;
                float env = Mathf.Exp(-t * 16f);
                float x = (float)rng.NextDouble() * 2f - 1f;
                y += 0.25f * (x - y);                                    // nhiễu đục (đất đá)
                float thump = Mathf.Sin(2f * Mathf.PI * (90f - 40f * t) * t) * Mathf.Exp(-t * 25f);
                d[i] = (y * 0.9f + thump * 0.8f) * env;
            }
            return Clip("block_break", d);
        }

        private static AudioClip MakeSweep(float f0, float f1, float seconds, float amp)
        {
            int n = (int)(Rate * seconds);
            var d = new float[n];
            float phase = 0f;
            for (int i = 0; i < n; i++)
            {
                float k = (float)i / n;
                phase += 2f * Mathf.PI * Mathf.Lerp(f0, f1, k) / Rate;
                float env = Mathf.Min(1f, i / (Rate * 0.004f)) * (1f - k);
                d[i] = Mathf.Sin(phase) * env * amp;
            }
            return Clip($"sweep_{f0}_{f1}", d);
        }

        private static AudioClip MakeArpeggio()
        {
            float[] notes = { 1046.5f, 1318.5f, 1568f }; // C6 E6 G6
            float step = 0.09f;
            int n = (int)(Rate * (step * notes.Length + 0.25f));
            var d = new float[n];
            for (int k = 0; k < notes.Length; k++)
            {
                int start = (int)(Rate * step * k);
                for (int i = start; i < n; i++)
                {
                    float t = (float)(i - start) / Rate;
                    d[i] += Mathf.Sin(2f * Mathf.PI * notes[k] * t) * Mathf.Exp(-t * 9f) * 0.3f;
                }
            }
            return Clip("deposit", d);
        }

        private static AudioClip MakeThump(float freq, float seconds)
        {
            int n = (int)(Rate * seconds);
            var d = new float[n];
            var rng = new System.Random(4);
            for (int i = 0; i < n; i++)
            {
                float t = (float)i / Rate;
                float noise = ((float)rng.NextDouble() * 2f - 1f) * Mathf.Exp(-t * 60f) * 0.3f;
                d[i] = (Mathf.Sin(2f * Mathf.PI * freq * t) * 0.9f + noise) * Mathf.Exp(-t * 28f);
            }
            return Clip("land", d);
        }
    }
}
