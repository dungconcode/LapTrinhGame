using System;
using UnityEngine;

namespace Underlab.Defense
{
    [CreateAssetMenu(menuName = "Underlab/Defense/Balance")]
    public class DefenseConfig : ScriptableObject
    {
        [Serializable] public class EnemyStats
        {
            public EnemyKind kind;
            public float health = 40, speed = 1, range = 2, attackSeconds = 1.5f;
            public int damage = 8;
            [Tooltip("Kích thước hình")] public float visualScale = 1f;
            [Tooltip("Hệ số nhận sát thương theo đạn: Thường, Axit, Lửa, Băng. <1 kháng, >1 yếu, <0 hồi máu")]
            public float[] ammoTaken = { 1f, 1f, 1f, 1f };
            public bool immuneBurn;
            public Color tint = Color.white;
            [Tooltip("Tiền tố art id riêng (vd enemy_armored). Chưa có hình => dùng hình dự phòng đổi màu")]
            public string art;
        }
        [Serializable] public class AmmoStats
        {
            public string artId = "proj_normal";
            public float damage = 20, statusSeconds, damagePerSecond, speedMultiplier = 1;
            public int craftCost = 1, craftYield = 5;
        }
        public int baseHealth = 500, repairAmount = 100, baseHealthBonus = 100;
        public float rotationSpeed = 180, fireSeconds = .3f, projectileSpeed = 22, projectileLifetime = 3;
        public float damageUpgrade = .25f, rotationUpgrade = .2f, hitRadius = .65f;
        public float bossPatternSeconds = 6, bossChargeMultiplier = 3;
        public int bossSummonCount = 2;
        public float turretBoardingRadius = 1.5f;
        public Vector2 turretBoardingOffset = new Vector2(0, -2);
        public EnemyStats[] enemies = {
            new EnemyStats { kind = EnemyKind.Melee },
            new EnemyStats { kind = EnemyKind.Flying, health = 25, speed = 2, range = 2 },
            new EnemyStats { kind = EnemyKind.Ranged, health = 35, range = 8 },
            new EnemyStats { kind = EnemyKind.Boss, health = 1600, speed = .6f, range = 4, damage = 25 }
        };
        public AmmoStats[] ammo = {
            new AmmoStats(),
            new AmmoStats { artId = "proj_acid", damage = 12, statusSeconds = 4, damagePerSecond = 8 },
            new AmmoStats { artId = "proj_fire", damage = 40, statusSeconds = 3, damagePerSecond = 5, craftCost = 2, craftYield = 1 },
            new AmmoStats { artId = "proj_ice", damage = 12, statusSeconds = 4, speedMultiplier = .5f }
        };
        public EnemyStats Stats(EnemyKind kind) => Array.Find(enemies, x => x.kind == kind) ?? Defaults(kind);

        // Quái mới: chỉ số mặc định ngay trong code (asset cũ chưa có dòng nào cho chúng).
        private static readonly System.Collections.Generic.Dictionary<EnemyKind, EnemyStats> defaults =
            new System.Collections.Generic.Dictionary<EnemyKind, EnemyStats>();
        public static EnemyStats Defaults(EnemyKind kind)
        {
            if (defaults.TryGetValue(kind, out var s)) return s;
            switch (kind)
            {
                case EnemyKind.Armored:   // giáp kim loại: đạn thường dội ra, axit ăn mòn
                    s = new EnemyStats { kind = kind, health = 70, speed = .7f, range = 2, damage = 12, visualScale = 1.15f,
                        ammoTaken = new[] { .3f, 1.6f, 1f, 1f }, tint = new Color(.65f, .8f, 1f), art = "enemy_armored" };
                    break;
                case EnemyKind.Lava:      // dung nham: lửa làm nó khoẻ thêm, băng làm nứt vỡ
                    s = new EnemyStats { kind = kind, health = 55, speed = .9f, range = 2, damage = 10, immuneBurn = true,
                        ammoTaken = new[] { 1f, 1f, -.5f, 2f }, tint = new Color(1f, .55f, .3f), art = "enemy_lava" };
                    break;
                case EnemyKind.Swarm:     // đàn bay nhỏ: yếu, nhanh, đông
                    s = new EnemyStats { kind = kind, health = 10, speed = 3f, range = 1.2f, damage = 3, visualScale = .5f,
                        tint = new Color(1f, .8f, 1f), art = "enemy_swarm" };
                    break;
                case EnemyKind.Diver:     // bổ nhào: lượn trên trời rồi lao xuống, nổ khi chạm base
                    s = new EnemyStats { kind = kind, health = 30, speed = 2.2f, range = 1f, damage = 30, visualScale = .85f,
                        tint = new Color(1f, .6f, .6f), art = "enemy_diver" };
                    break;
                case EnemyKind.Pod:       // kén rơi: bắn khi đang rơi, chạm đất nở 3 con
                    s = new EnemyStats { kind = kind, health = 45, speed = 4f, range = 0f, damage = 0, visualScale = 1.4f, art = "enemy_pod" };
                    break;
                case EnemyKind.Burrower:  // đào hầm: chui lên gần base
                    s = new EnemyStats { kind = kind, health = 60, speed = .8f, range = 2, damage = 14, visualScale = 1.05f,
                        tint = new Color(.85f, .7f, .5f), art = "enemy_burrower" };
                    break;
                case EnemyKind.Hatchling: // con nở từ kén
                    s = new EnemyStats { kind = kind, health = 14, speed = 1.6f, range = 1.5f, damage = 4, visualScale = .55f,
                        tint = new Color(.9f, 1f, .7f), art = "enemy_hatchling" };
                    break;
                default:
                    s = new EnemyStats { kind = kind };
                    break;
            }
            defaults[kind] = s;
            return s;
        }
    }
}
