using UnityEngine;

namespace Underlab.Mining
{
    /// <summary>
    /// Âm thanh phần đào. Ô clip để TRỐNG => dùng âm tổng hợp bằng code.
    /// Có file thật (wav/ogg) thì kéo vào là thay, không cần sửa code.
    /// </summary>
    [CreateAssetMenu(menuName = "Underlab/Mining/Mining Audio Config", fileName = "MiningAudioConfig")]
    public class MiningAudioConfig : ScriptableObject
    {
        [Range(0f, 1f)] public float masterVolume = 0.6f;

        [Header("Clip thật (để trống = âm tổng hợp)")]
        public AudioClip drillLoop;
        public AudioClip blockBreak;
        public AudioClip orePickup;
        public AudioClip deposit;
        public AudioClip jetpackLoop;
        public AudioClip land;
        public AudioClip oreDrop;

        [Header("Âm lượng từng loại")]
        [Range(0f, 1f)] public float drillVolume = 0.35f;
        [Range(0f, 1f)] public float breakVolume = 0.6f;
        [Range(0f, 1f)] public float pickupVolume = 0.45f;
        [Range(0f, 1f)] public float depositVolume = 0.5f;
        [Range(0f, 1f)] public float jetpackVolume = 0.25f;
        [Range(0f, 1f)] public float landVolume = 0.5f;
    }
}
