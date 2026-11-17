using UnityEngine;

namespace Underlab.Lab
{
    /// <summary>Số liệu phòng thí nghiệm. Chỉnh độ khó ở đây, không cần sửa code.</summary>
    [CreateAssetMenu(menuName = "Underlab/Lab/Lab Config", fileName = "LabConfig")]
    public class LabConfig : ScriptableObject
    {
        [Header("Chấm điểm")]
        [Tooltip("Lệch tối đa so với lượng đúng (0.05 = 5%). Vượt => thất bại, mất sạch nguyên liệu")]
        [Range(0.01f, 0.2f)] public float tolerance = 0.05f;
        [Tooltip("Hiệu suất khi lệch đúng bằng tolerance (lệch 0 => 100%)")]
        [Range(0.5f, 1f)] public float efficiencyAtTolerance = 0.8f;

        [Header("Hoá học")]
        [Tooltip("1 mol khí ở điều kiện chuẩn (25°C, 1 bar) ≈ 24.79 L")]
        public float gasMolarVolume = 24.79f;
        [Tooltip("1 cục quặng = bao nhiêu mol")]
        public float molPerOre = 1f;

        [Header("Thao tác cân")]
        public Vector2 scoopGrams = new Vector2(2.0f, 4.0f);     // 1 thìa đầy
        public Vector2 tapGrams = new Vector2(0.15f, 0.45f);     // Shift + click: gõ nhẹ
        [Tooltip("Cân đọc trễ (giây) — số nhảy dần tới giá trị thật")]
        public float scaleLag = 0.35f;

        [Header("Van khí O₂")]
        [Tooltip("Lưu lượng tối đa (L/s) khi mở hết van")]
        public float maxFlow = 14f;
        [Tooltip("Mở van quá mức này liên tục => xì khí, hỏng")]
        [Range(0.5f, 1f)] public float overPressureOpen = 0.88f;
        public float overPressureSeconds = 0.5f;
        [Tooltip("Khí còn chảy thêm sau khi khoá van (quán tính)")]
        public float valveInertia = 0.25f;

        [Header("Bình O₂ của base (tạm thời — sau thay bằng điện phân nước)")]
        public float o2Capacity = 120f;
        public float o2RegenPerSecond = 1.2f;

        [Header("Sản phẩm")]
        [Tooltip("Đạn lửa nhận được cho mỗi mol Mg đốt đúng (nhân hiệu suất)")]
        public float fireBulletsPerMolMg = 1f;

        [Header("Tự động hoá")]
        public int masteryRuns = 3;
        [Range(0.5f, 1f)] public float autoEfficiency = 0.9f;
        public float autoSecondsPerMol = 1.5f;
    }
}
