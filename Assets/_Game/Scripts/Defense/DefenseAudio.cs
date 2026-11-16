using Underlab.Core;
using UnityEngine;

namespace Underlab.Defense
{
    public class DefenseAudio : MonoBehaviour
    {
        public DefenseAudioConfig config;
        private AudioSource effects, music;
        private AudioClip shot, explosion, warning, miningTrack, defenseTrack;
        private void Awake()
        {
            effects = gameObject.AddComponent<AudioSource>(); effects.playOnAwake = false; effects.volume = config.effectsVolume;
            music = gameObject.AddComponent<AudioSource>(); music.playOnAwake = false; music.volume = config.musicVolume; music.loop = true;
            shot = config.shot ? config.shot : Tone("shot", new[] { config.shotFrequency }, config.effectSeconds, false);
            explosion = config.explosion ? config.explosion : Tone("explosion", new[] { config.explosionFrequency }, config.effectSeconds, true);
            warning = config.warning ? config.warning : Tone("warning", new[] { config.warningFrequency }, config.effectSeconds, false);
            miningTrack = config.miningMusic ? config.miningMusic : Tone("mining", config.miningNotes, config.musicSeconds, false);
            defenseTrack = config.defenseMusic ? config.defenseMusic : Tone("defense", config.defenseNotes, config.musicSeconds, false);
        }
        private void OnEnable() { GameEvents.PhaseChanged += Phase; GameEvents.WaveWarning += Warn; }
        private void OnDisable() { GameEvents.PhaseChanged -= Phase; GameEvents.WaveWarning -= Warn; AudioListener.pause = false; }
        private void Warn(int wave) => effects.PlayOneShot(warning);
        private void Phase(GamePhase phase)
        {
            music.Stop();
            if (phase == GamePhase.Mining || phase == GamePhase.Defense)
            { music.clip = phase == GamePhase.Mining ? miningTrack : defenseTrack; music.Play(); }
        }
        public void Shot() => effects.PlayOneShot(shot);
        public void Explosion() => effects.PlayOneShot(explosion);
        private AudioClip Tone(string label, float[] notes, float seconds, bool noise)
        {
            const int rate = 22050;
            var data = new float[Mathf.Max(1, Mathf.RoundToInt(seconds * rate))];
            var random = new System.Random(1);
            for (int i = 0; i < data.Length; i++)
            {
                float progress = (float)i / data.Length;
                float noteProgress = progress * notes.Length % 1;
                float frequency = notes[Mathf.Min(notes.Length - 1, (int)(progress * notes.Length))];
                float envelope = Mathf.Min(1, noteProgress * 40) * (1 - noteProgress);
                data[i] = (noise ? (float)random.NextDouble() * 2 - 1 : Mathf.Sin(2 * Mathf.PI * frequency * i / rate)) * envelope;
            }
            var clip = AudioClip.Create(label, data.Length, 1, rate, false); clip.SetData(data, 0); return clip;
        }
        private void OnDestroy()
        {
            foreach (var clip in new[] { shot, explosion, warning, miningTrack, defenseTrack })
                if (clip && !clip.Equals(config.shot) && !clip.Equals(config.explosion) && !clip.Equals(config.warning) && !clip.Equals(config.miningMusic) && !clip.Equals(config.defenseMusic)) Destroy(clip);
        }
    }
}
