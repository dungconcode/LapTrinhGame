using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
using Underlab.Art;
using Underlab.Core;
using Underlab.Player;

namespace Underlab.Mining
{
    /// <summary>
    /// A07 + A08 — Áp dụng nâng cấp phần đào.
    /// Nghe GameEvents.UpgradePurchased(id) với id trong UpgradeIds (drill, move, carry, jetpack).
    /// Shop (Dev B) chỉ cần phát event; hỏi cấp hiện tại / cấp tối đa qua Level() / MaxLevel().
    /// Debug (chỉ Editor): F5 khoan · F6 tốc độ · F7 sức mang · F8 jetpack.
    /// </summary>
    public class MiningUpgrades : MonoBehaviour
    {
        [SerializeField] private MiningUpgradeConfig config;
        [SerializeField] private PlayerController player;
        [SerializeField] private Drill drill;
        [SerializeField] private Carrier carrier;

        public static MiningUpgrades Instance { get; private set; }

        private readonly Dictionary<string, int> levels = new Dictionary<string, int>();

        private void Awake() => Instance = this;

        // Start (không phải Awake): đợi Carrier/Player Awake xong rồi mới áp giá trị.
        private void Start() => Apply();

        private void OnDestroy()
        {
            if (Instance == this) Instance = null;
        }

        private void OnEnable() => GameEvents.UpgradePurchased += OnPurchased;
        private void OnDisable() => GameEvents.UpgradePurchased -= OnPurchased;

        public int Level(string id) => levels.TryGetValue(id, out var l) ? l : 0;

        /// <summary>Cấp tối đa; -1 nếu id không thuộc phần đào.</summary>
        public int MaxLevel(string id)
        {
            var arr = Table(id);
            return arr == null ? -1 : arr.Length - 1;
        }

        public bool CanUpgrade(string id) => MaxLevel(id) > Level(id);

        private void OnPurchased(string id)
        {
            if (Table(id) == null) return; // không phải upgrade phần đào
            if (!CanUpgrade(id)) return;
            levels[id] = Level(id) + 1;
            Apply();
            if (player != null)
                FloatingText.Spawn($"{DisplayName(id)} CẤP {Level(id)}!", player.transform.position + Vector3.up * 1.4f,
                    new Color(0.5f, 1f, 1f), duration: 1.4f);
        }

        private void Apply()
        {
            if (config == null) return;
            if (drill != null) drill.DamageMultiplier = Value(config.drillDamage, UpgradeIds.Drill);
            if (player != null)
            {
                player.SpeedUpgrade = Value(config.moveSpeed, UpgradeIds.Move);
                player.ThrustUpgrade = Value(config.jetpackThrust, UpgradeIds.Jetpack);
            }
            if (carrier != null) carrier.CapacityBonus = Value(config.carryBonus, UpgradeIds.Carry);
        }

        private float Value(float[] table, string id) =>
            table == null || table.Length == 0 ? 1f : table[Mathf.Clamp(Level(id), 0, table.Length - 1)];

        private float[] Table(string id)
        {
            if (config == null) return null;
            switch (id)
            {
                case UpgradeIds.Drill: return config.drillDamage;
                case UpgradeIds.Move: return config.moveSpeed;
                case UpgradeIds.Carry: return config.carryBonus;
                case UpgradeIds.Jetpack: return config.jetpackThrust;
                default: return null;
            }
        }

        public static string DisplayName(string id)
        {
            switch (id)
            {
                case UpgradeIds.Drill: return "KHOAN";
                case UpgradeIds.Move: return "TỐC ĐỘ";
                case UpgradeIds.Carry: return "SỨC MANG";
                case UpgradeIds.Jetpack: return "JETPACK";
                default: return id.ToUpperInvariant();
            }
        }

#if UNITY_EDITOR
        private void Update()
        {
            var k = Keyboard.current;
            if (k == null) return;
            if (k.f5Key.wasPressedThisFrame) GameEvents.RaiseUpgradePurchased(UpgradeIds.Drill);
            if (k.f6Key.wasPressedThisFrame) GameEvents.RaiseUpgradePurchased(UpgradeIds.Move);
            if (k.f7Key.wasPressedThisFrame) GameEvents.RaiseUpgradePurchased(UpgradeIds.Carry);
            if (k.f8Key.wasPressedThisFrame) GameEvents.RaiseUpgradePurchased(UpgradeIds.Jetpack);
        }
#endif
    }
}
