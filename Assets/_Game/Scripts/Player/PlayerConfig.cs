using UnityEngine;

namespace Underlab.Player
{
    [CreateAssetMenu(menuName = "Underlab/Player/Player Config", fileName = "PlayerConfig")]
    public class PlayerConfig : ScriptableObject
    {
        [Header("Di chuyển ngang")]
        [Tooltip("ô/giây")] public float moveSpeed = 5f;
        [Tooltip("Tăng tốc trên mặt đất")] public float groundAccel = 60f;
        [Tooltip("Tăng tốc khi đang bay/rơi")] public float airAccel = 30f;

        [Header("Jetpack (giữ Space / nút nhảy để bay lên)")]
        public float thrustAccel = 35f;
        public float maxRiseSpeed = 5f;
        public float maxFallSpeed = 14f;
        public float gravityScale = 2.5f;

        [Header("Va chạm")]
        [Tooltip("Khoảng kiểm tra chạm đất")] public float groundCheckDistance = 0.06f;
    }
}
