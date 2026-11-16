using System;
using UnityEngine;

namespace Underlab.Defense
{
    public enum EnemyKind { Melee, Flying, Ranged, Boss }

    [CreateAssetMenu(menuName = "Underlab/Defense/Waves")]
    public class WaveConfig : ScriptableObject
    {
        [Serializable] public class Wave
        {
            public float miningSeconds = 90, spawnDelay = 1.5f;
            public int melee = 5, flying, ranged, bosses;
            public float healthScale = 1, speedScale = 1;
        }
        public float warningSeconds = 10, spawnDistance = 16, flyingHeight = 5;
        public Wave[] waves = new Wave[10];
    }
}
