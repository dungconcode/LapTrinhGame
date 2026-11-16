using UnityEngine;

namespace Underlab.Defense
{
    [CreateAssetMenu(menuName = "Underlab/Defense/Audio")]
    public class DefenseAudioConfig : ScriptableObject
    {
        public AudioClip shot, explosion, warning, miningMusic, defenseMusic;
        [Range(0, 1)] public float effectsVolume = .2f, musicVolume = .08f;
        public float shotFrequency = 180, explosionFrequency = 60, warningFrequency = 660;
        public float effectSeconds = .12f, musicSeconds = 4;
        public float[] miningNotes = { 130.81f, 164.81f, 196, 164.81f };
        public float[] defenseNotes = { 130.81f, 155.56f, 146.83f, 174.61f };
    }
}
