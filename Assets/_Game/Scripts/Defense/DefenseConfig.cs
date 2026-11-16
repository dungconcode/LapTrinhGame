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
        public EnemyStats Stats(EnemyKind kind) => Array.Find(enemies, x => x.kind == kind);
    }
}
