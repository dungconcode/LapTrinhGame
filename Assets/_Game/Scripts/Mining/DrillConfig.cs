using UnityEngine;

namespace Underlab.Mining
{
    [CreateAssetMenu(menuName = "Underlab/Mining/Drill Config", fileName = "DrillConfig")]
    public class DrillConfig : ScriptableObject
    {
        [Tooltip("HP ô bị trừ mỗi giây (ô tầng 1 có 2 HP => ~0.5s)")]
        public float damagePerSecond = 4f;

        [Tooltip("Cho phép khoan lên trần")]
        public bool allowDrillUp = true;

        [Tooltip("Ngưỡng nghiêng cần analog để tính là đang chọn hướng")]
        [Range(0.1f, 0.9f)] public float inputThreshold = 0.5f;

        [Header("Quặng rơi ra")]
        public float dropPopSpeed = 2.5f;
        [Tooltip("Thời gian (giây) quặng mới rơi chưa nhặt được — để không hút ngay vào người")]
        public float dropPickupDelay = 0.25f;
    }
}
