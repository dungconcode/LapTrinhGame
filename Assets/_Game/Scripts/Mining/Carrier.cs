using System;
using System.Collections.Generic;
using UnityEngine;
using Underlab.Core;
using Underlab.Player;

namespace Underlab.Mining
{
    /// <summary>
    /// Túi quặng trên người thợ mỏ.
    ///  - Tự hút quặng (OrePickup) trong bán kính, nhặt nếu còn sức mang.
    ///  - Càng nặng: đi chậm hơn, jetpack yếu hơn, chuyển anim carry.
    ///  - Phát GameEvents.ResourcePickedUp / CarryWeightChanged.
    /// Về base (A05) gọi TakeAll() để lấy hết ra.
    /// Nâng cấp sức mang (A08): CapacityBonus.
    /// </summary>
    [RequireComponent(typeof(PlayerController))]
    public class Carrier : MonoBehaviour
    {
        [SerializeField] private CarrierConfig config;

        public float CapacityBonus
        {
            get => capacityBonus;
            set { capacityBonus = Mathf.Max(0f, value); Refresh(); }
        }
        public float MaxWeight => config.maxWeight + capacityBonus;
        public float Weight { get; private set; }
        public float Load01 => MaxWeight > 0f ? Mathf.Clamp01(Weight / MaxWeight) : 1f;
        public bool IsEmpty => Weight <= 0f;
        /// <summary>Không nhặt thêm được cả loại quặng nhẹ nhất.</summary>
        public bool IsFull => Weight + LightestWeight() > MaxWeight + 0.0001f;

        /// <summary>Gọi mỗi khi túi thay đổi (nhặt hoặc lấy ra).</summary>
        public event Action Changed;
        /// <summary>Gọi khi vừa nhặt quặng (loại, số lượng).</summary>
        public event Action<ResourceType, int> PickedUp;

        private readonly Dictionary<ResourceType, int> items = new Dictionary<ResourceType, int>();
        private readonly List<Collider2D> nearby = new List<Collider2D>();
        private ContactFilter2D filter;
        private PlayerController player;
        private float capacityBonus;

        private void Awake()
        {
            player = GetComponent<PlayerController>();
            filter = new ContactFilter2D { useTriggers = true };
            filter.NoFilter();
        }

        private void Start() => Refresh();

        public int Get(ResourceType t) => items.TryGetValue(t, out var n) ? n : 0;

        public bool CanCarry(ResourceType t, int amount = 1) =>
            Weight + config.WeightOf(t) * amount <= MaxWeight + 0.0001f;

        /// <summary>Thêm quặng vào túi. Trả về số thực sự nhận (có thể ít hơn nếu gần đầy).</summary>
        public int Add(ResourceType t, int amount)
        {
            int taken = 0;
            while (taken < amount && CanCarry(t)) taken++;
            if (taken == 0) return 0;

            items[t] = Get(t) + taken;
            GameEvents.RaiseResourcePickedUp(t, taken);
            PickedUp?.Invoke(t, taken);
            Refresh();
            return taken;
        }

        /// <summary>Bỏ bớt quặng khỏi túi. Trả về số thực sự bỏ được.</summary>
        public int Remove(ResourceType t, int amount)
        {
            int have = Get(t);
            int n = Mathf.Min(have, amount);
            if (n <= 0) return 0;
            if (have - n == 0) items.Remove(t);
            else items[t] = have - n;
            Refresh();
            return n;
        }

        /// <summary>Lấy hết quặng ra (dùng khi gửi vào kho ở base).</summary>
        public Dictionary<ResourceType, int> TakeAll()
        {
            var result = new Dictionary<ResourceType, int>(items);
            items.Clear();
            Refresh();
            return result;
        }

        private void FixedUpdate()
        {
            nearby.Clear();
            Vector2 center = (Vector2)transform.position + Vector2.up * 0.4f;
            Physics2D.OverlapCircle(center, config.magnetRadius, filter, nearby);

            foreach (var col in nearby)
            {
                if (col == null || !col.TryGetComponent<OrePickup>(out var ore) || !ore.CanPickup) continue;
                if (!CanCarry(ore.Type)) continue;

                Vector2 to = center - (Vector2)ore.transform.position;
                if (to.magnitude <= config.collectRadius)
                {
                    int got = Add(ore.Type, ore.Amount);
                    if (got > 0) ore.Collect();
                }
                else if (ore.TryGetComponent<Rigidbody2D>(out var rb))
                {
                    rb.linearVelocity = to.normalized * config.magnetSpeed;
                }
            }
        }

        private float LightestWeight()
        {
            float min = float.MaxValue;
            foreach (var w in config.weights) min = Mathf.Min(min, w.weight);
            return min == float.MaxValue ? 1f : min;
        }

        private void Refresh()
        {
            float w = 0f;
            foreach (var kv in items) w += config.WeightOf(kv.Key) * kv.Value;
            Weight = w;

            float load = Load01;
            player.SpeedMultiplier = config.speedByLoad.Evaluate(load);
            player.ThrustMultiplier = config.thrustByLoad.Evaluate(load);
            player.WalkAnimId = load >= config.carryAnimThreshold ? "char_player_carry" : PlayerController.DefaultWalkAnim;

            GameEvents.RaiseCarryWeightChanged(Weight, MaxWeight);
            Changed?.Invoke();
        }

#if UNITY_EDITOR
        private void OnDrawGizmosSelected()
        {
            if (config == null) return;
            Vector3 c = transform.position + Vector3.up * 0.4f;
            Gizmos.color = Color.yellow;
            Gizmos.DrawWireSphere(c, config.magnetRadius);
            Gizmos.color = Color.green;
            Gizmos.DrawWireSphere(c, config.collectRadius);
        }
#endif
    }
}
