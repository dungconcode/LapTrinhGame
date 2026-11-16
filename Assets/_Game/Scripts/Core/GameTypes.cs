namespace Underlab.Core
{
    // ======================================================================
    // HỢP ĐỒNG CHUNG giữa Dev A (Mining) và Dev B (Defense).
    // Sửa file này = báo người kia trước + merge riêng 1 PR nhỏ.
    // ======================================================================

    /// <summary>Loại quặng / tài nguyên.</summary>
    public enum ResourceType
    {
        Iron = 0,      // tiền chính: nâng cấp, sửa base
        Sulfur = 1,    // -> đạn Axit
        Magnesium = 2, // -> đạn Lửa
        KCl = 3,       // -> đạn Băng
    }

    /// <summary>Loại đạn của pháo base.</summary>
    public enum AmmoType
    {
        Normal = 0,
        Acid = 1,
        Fire = 2,
        Ice = 3,
    }

    /// <summary>Pha của 1 vòng chơi.</summary>
    public enum GamePhase
    {
        Mining = 0,   // đào, đồng hồ đếm ngược tới wave
        Defense = 1,  // wave đang đánh
        Victory = 2,
        GameOver = 3,
    }
}
