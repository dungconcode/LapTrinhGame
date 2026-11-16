using System;
using UnityEngine;

namespace Underlab.Core
{
    /// <summary>
    /// Kênh sự kiện toàn cục — cách DUY NHẤT để phần Mining (Dev A) và Defense/UI (Dev B)
    /// nói chuyện với nhau, để 2 người không phải sửa code của nhau.
    ///
    ///   Phát:  GameEvents.RaiseResourcesDeposited(ResourceType.Iron, 5);
    ///   Nghe:  void OnEnable()  => GameEvents.ResourcesDeposited += Handle;
    ///          void OnDisable() => GameEvents.ResourcesDeposited -= Handle;
    /// </summary>
    public static class GameEvents
    {
        // ---- Vòng chơi (Dev B phát) ----
        public static event Action<GamePhase> PhaseChanged;
        /// <summary>Giây còn lại tới wave tiếp theo (phát mỗi frame trong pha Mining).</summary>
        public static event Action<float> WaveCountdown;
        /// <summary>Bắt đầu cảnh báo wave (vd còn 10s) — dùng cho âm thanh / nháy HUD.</summary>
        public static event Action<int> WaveWarning;
        public static event Action<int> WaveStarted;
        public static event Action<int> WaveCleared;
        public static event Action<int, int> BaseHpChanged; // (hiện tại, tối đa)

        // ---- Đào / tài nguyên (Dev A phát) ----
        public static event Action<ResourceType, int> ResourcePickedUp;   // nhặt vào người
        public static event Action<ResourceType, int> ResourcesDeposited; // về base, đưa vào kho
        public static event Action<float, float> CarryWeightChanged;      // (đang mang, tối đa)
        public static event Action<int> DepthChanged;                     // độ sâu theo số ô
        public static event Action<bool> PlayerAtBaseChanged;             // true = đang ở base

        // ---- Kinh tế (Dev B phát) ----
        public static event Action<ResourceType, int> BankChanged;        // (loại, số dư mới)
        public static event Action<string> UpgradePurchased;              // upgrade id

        public static void RaisePhaseChanged(GamePhase p) => PhaseChanged?.Invoke(p);
        public static void RaiseWaveCountdown(float s) => WaveCountdown?.Invoke(s);
        public static void RaiseWaveWarning(int wave) => WaveWarning?.Invoke(wave);
        public static void RaiseWaveStarted(int wave) => WaveStarted?.Invoke(wave);
        public static void RaiseWaveCleared(int wave) => WaveCleared?.Invoke(wave);
        public static void RaiseBaseHpChanged(int hp, int max) => BaseHpChanged?.Invoke(hp, max);
        public static void RaiseResourcePickedUp(ResourceType t, int n) => ResourcePickedUp?.Invoke(t, n);
        public static void RaiseResourcesDeposited(ResourceType t, int n) => ResourcesDeposited?.Invoke(t, n);
        public static void RaiseCarryWeightChanged(float cur, float max) => CarryWeightChanged?.Invoke(cur, max);
        public static void RaiseDepthChanged(int d) => DepthChanged?.Invoke(d);
        public static void RaisePlayerAtBaseChanged(bool atBase) => PlayerAtBaseChanged?.Invoke(atBase);
        public static void RaiseBankChanged(ResourceType t, int total) => BankChanged?.Invoke(t, total);
        public static void RaiseUpgradePurchased(string id) => UpgradePurchased?.Invoke(id);

        // Xoá listener cũ khi vào Play Mode (an toàn khi tắt Domain Reload).
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
        private static void ResetAll()
        {
            PhaseChanged = null; WaveCountdown = null; WaveWarning = null; WaveStarted = null;
            WaveCleared = null; BaseHpChanged = null; ResourcePickedUp = null; ResourcesDeposited = null;
            CarryWeightChanged = null; DepthChanged = null; PlayerAtBaseChanged = null;
            BankChanged = null; UpgradePurchased = null;
        }
    }
}
