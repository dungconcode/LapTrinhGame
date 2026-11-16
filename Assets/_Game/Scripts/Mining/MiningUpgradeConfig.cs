using UnityEngine;

namespace Underlab.Mining
{
    /// <summary>
    /// Giá trị từng cấp nâng cấp phần đào. Phần tử [0] = cấp 0 (chưa nâng).
    /// GIÁ tiền do shop (Dev B) quyết, file này chỉ quyết HIỆU QUẢ.
    /// </summary>
    [CreateAssetMenu(menuName = "Underlab/Mining/Mining Upgrade Config", fileName = "MiningUpgradeConfig")]
    public class MiningUpgradeConfig : ScriptableObject
    {
        [Tooltip("Hệ số sát thương khoan")]
        public float[] drillDamage = { 1f, 1.5f, 2.2f, 3f, 4f };
        [Tooltip("Hệ số tốc độ đi")]
        public float[] moveSpeed = { 1f, 1.15f, 1.3f, 1.45f, 1.6f };
        [Tooltip("Sức mang cộng thêm")]
        public float[] carryBonus = { 0f, 4f, 8f, 13f, 20f };
        [Tooltip("Hệ số lực jetpack")]
        public float[] jetpackThrust = { 1f, 1.2f, 1.4f, 1.6f, 1.8f };
    }
}
