using System;
using System.Collections.Generic;
using UnityEngine;
using Underlab.Core;

namespace Underlab.Mining
{
    [CreateAssetMenu(menuName = "Underlab/Mining/Carrier Config", fileName = "CarrierConfig")]
    public class CarrierConfig : ScriptableObject
    {
        [Serializable]
        public class ResourceWeight
        {
            public ResourceType type;
            [Min(0.1f)] public float weight = 1f;
        }

        [Header("Sức mang")]
        [Tooltip("Tổng trọng lượng tối đa (nâng cấp cộng thêm qua Carrier.CapacityBonus)")]
        public float maxWeight = 10f;
        public List<ResourceWeight> weights = new List<ResourceWeight>
        {
            new ResourceWeight { type = ResourceType.Iron, weight = 1f },
            new ResourceWeight { type = ResourceType.Sulfur, weight = 1f },
            new ResourceWeight { type = ResourceType.Magnesium, weight = 1.5f },
            new ResourceWeight { type = ResourceType.KCl, weight = 1.2f },
        };

        [Header("Ảnh hưởng của tải (trục X: 0 = rỗng, 1 = đầy)")]
        [Tooltip("Hệ số tốc độ đi")]
        public AnimationCurve speedByLoad = AnimationCurve.Linear(0f, 1f, 1f, 0.45f);
        [Tooltip("Hệ số lực jetpack — mang nặng thì bay lên khó")]
        public AnimationCurve thrustByLoad = AnimationCurve.Linear(0f, 1f, 1f, 0.6f);
        [Tooltip("Tải từ mức này trở lên thì dùng anim char_player_carry")]
        [Range(0f, 1f)] public float carryAnimThreshold = 0.6f;

        [Header("Nhặt quặng")]
        [Tooltip("Bán kính hút quặng về phía người")]
        public float magnetRadius = 1.6f;
        public float magnetSpeed = 4.5f;
        [Tooltip("Khoảng cách coi như đã nhặt")]
        public float collectRadius = 0.45f;

        public float WeightOf(ResourceType t)
        {
            foreach (var w in weights)
                if (w.type == t) return w.weight;
            return 1f;
        }
    }
}
