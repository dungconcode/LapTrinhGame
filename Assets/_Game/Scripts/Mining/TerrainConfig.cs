using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;
using Underlab.Core;

namespace Underlab.Mining
{
    /// <summary>Cấu hình sinh địa hình. Chỉnh số trong Inspector, không sửa code.</summary>
    [CreateAssetMenu(menuName = "Underlab/Mining/Terrain Config", fileName = "TerrainConfig")]
    public class TerrainConfig : ScriptableObject
    {
        [Serializable]
        public class OreRule
        {
            public ResourceType type;
            public TileBase tile;
            [Tooltip("Độ sâu (số ô) bắt đầu xuất hiện")] public int minDepth = 3;
            [Tooltip("Độ sâu (số ô) ngừng xuất hiện")] public int maxDepth = 999;
            [Tooltip("Xác suất 1 ô bắt đầu 1 mạch quặng")] [Range(0f, 0.2f)] public float veinChance = 0.02f;
            [Min(1)] public int veinSizeMin = 2;
            [Min(1)] public int veinSizeMax = 5;
            [Tooltip("HP cộng thêm so với đất xung quanh")] public int extraHp = 1;
            [Tooltip("Số quặng rơi ra khi phá 1 ô")] [Min(1)] public int dropAmount = 1;
        }

        [Header("Kích thước (ô)")]
        [Min(8)] public int width = 40;
        [Min(10)] public int depth = 120;
        [Tooltip("0 = ngẫu nhiên mỗi lần chơi")] public int seed = 0;

        [Header("Lối vào base hai tầng (ô)")]
        public bool carveBaseEntrance = true;
        public int entranceCenterX;
        [Min(2)] public int entranceChamberWidth = 4;
        [Min(1)] public int entranceChamberDepth = 2;
        [Min(1)] public int entranceShaftWidth = 2;
        [Min(1)] public int entranceShaftDepth = 3;
        [Min(.6f)] public float entranceHatchWidth = 1.4f;
        [Min(.01f)] public float entranceFloorThickness = .125f;

        [Header("Tầng đất (độ sâu bắt đầu, tính bằng ô)")]
        public int layer2Depth = 30;
        public int layer3Depth = 70;

        [Header("HP mỗi ô (drill gây damage/giây)")]
        public int surfaceHp = 2;
        public int layer1Hp = 2;
        public int layer2Hp = 5;
        public int layer3Hp = 10;

        [Header("Tile (kéo từ Assets/_Game/Art/_GeneratedTiles)")]
        public TileBase surfaceTile;
        public TileBase layer1Tile;
        public TileBase layer2Tile;
        public TileBase layer3Tile;
        public TileBase bedrockTile;

        [Header("Quặng")]
        public List<OreRule> ores = new List<OreRule>();

        [Header("Hang trống ngẫu nhiên")]
        [Range(0f, 0.05f)] public float caveChance = 0.004f;
        [Min(1)] public int caveSizeMax = 6;
    }
}
