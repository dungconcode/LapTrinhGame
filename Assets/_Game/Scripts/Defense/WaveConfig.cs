using System;
using UnityEngine;

namespace Underlab.Defense
{
    // Thêm loại mới ở CUỐI (giá trị số đã lưu trong asset không đổi)
    public enum EnemyKind { Melee, Flying, Ranged, Boss, Armored, Lava, Swarm, Diver, Pod, Burrower, Hatchling }

    [CreateAssetMenu(menuName = "Underlab/Defense/Waves")]
    public class WaveConfig : ScriptableObject
    {
        [Serializable] public class Wave
        {
            public float miningSeconds = 90, spawnDelay = 1.5f;
            public int melee = 5, flying, ranged, bosses;
            [Tooltip("Bọ giáp (kháng đạn thường, yếu axit) — đi bộ từ 2 bên")] public int armored;
            [Tooltip("Sinh vật dung nham (hồi máu khi trúng lửa, yếu băng) — đi bộ từ 2 bên")] public int lava;
            [Tooltip("Đàn bay nhỏ — bay theo nhóm 4 con, từ 2 bên hoặc trên trời")] public int swarm;
            [Tooltip("Quái bổ nhào — xuất hiện trên trời, lượn rồi lao thẳng xuống base")] public int divers;
            [Tooltip("Kén rơi — rơi từ trời, chạm đất nở 3 con nhỏ nếu không bắn kịp")] public int pods;
            [Tooltip("Quái đào hầm — chui lên từ dưới đất gần base (có cảnh báo)")] public int burrowers;
            public int Total => melee + flying + ranged + bosses + armored + lava + swarm + divers + pods + burrowers;
            public float healthScale = 1, speedScale = 1;
        }
        public float warningSeconds = 10, spawnDistance = 16, flyingHeight = 5;
        public Wave[] waves = new Wave[10];
    }
}
