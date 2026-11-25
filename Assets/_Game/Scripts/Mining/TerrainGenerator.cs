using System;
using UnityEngine;
using UnityEngine.Tilemaps;
using Underlab.Core;

namespace Underlab.Mining
{
    public enum TileKind { Empty, Surface, Layer1, Layer2, Layer3, Ore, Bedrock }

    public struct TerrainCell
    {
        public TileKind kind;
        public ResourceType ore;   // chỉ có nghĩa khi kind == Ore
        public int oreAmount;
        public int maxHp;
        public float hp;
        public bool reinforced;

        public bool IsSolid => kind != TileKind.Empty;
        public bool IsBreakable => IsSolid && kind != TileKind.Bedrock && !reinforced;
    }

    /// <summary>
    /// Sinh map lòng đất trên Tilemap và giữ dữ liệu từng ô (loại, HP, quặng).
    /// Toạ độ: mặt đất ở y = 0; hàng ô trên cùng là cell y = -1, đào xuống y âm.
    /// x chạy từ -width/2 tới width/2 - 1. Viền trái/phải/đáy là bedrock.
    /// Drill (A03) dùng: TryGetCell / Damage / OnCellDestroyed.
    /// </summary>
    public class TerrainGenerator : MonoBehaviour
    {
        [SerializeField] private TerrainConfig config;
        [SerializeField] private Tilemap tilemap;
        [SerializeField] private bool generateOnAwake = true;

        /// <summary>Phát khi 1 ô bị phá (cell, dữ liệu trước khi phá).</summary>
        public event Action<Vector3Int, TerrainCell> OnCellDestroyed;

        public TerrainConfig Config => config;
        public Tilemap Tilemap => tilemap;
        public int Width => config.width;
        public int Depth => config.depth;
        public int MinX => -config.width / 2;
        public int MaxX => MinX + config.width - 1;
        internal float EntranceOpeningWidth => Mathf.Min(config.entranceShaftWidth,
            Mathf.Max(2, config.entranceChamberWidth), config.entranceHatchWidth);

        /// <summary>Khung thế giới của map (kể cả viền bedrock).</summary>
        public Bounds WorldBounds
        {
            get
            {
                var min = new Vector3(MinX - 1, -config.depth - 1, 0f);
                var max = new Vector3(MaxX + 2, 0f, 0f);
                var b = new Bounds();
                b.SetMinMax(min, max);
                return b;
            }
        }

        private TerrainCell[,] cells; // [x - MinX + 1, -y - 1 + 0] với viền
        private System.Random rng;

        private void Awake()
        {
            if (generateOnAwake) Generate();
        }

        [ContextMenu("Generate")]
        public void Generate()
        {
            if (config == null || tilemap == null)
            {
                Debug.LogError("[Terrain] Thiếu config hoặc tilemap", this);
                return;
            }

            int seed = config.seed != 0 ? config.seed : Environment.TickCount;
            rng = new System.Random(seed);

            // +2 cột viền, +1 hàng đáy
            cells = new TerrainCell[config.width + 2, config.depth + 1];

            for (int ix = 0; ix < config.width + 2; ix++)
            for (int iy = 0; iy < config.depth + 1; iy++)
            {
                bool border = ix == 0 || ix == config.width + 1 || iy == config.depth;
                cells[ix, iy] = border ? Make(TileKind.Bedrock, 0) : BaseCell(iy);
                if (iy == 0) cells[ix, iy].reinforced = true;
            }

            PlaceOres();
            CarveCaves();
            CarveBaseEntrance();
            PaintAll();
            BuildEntranceFloors();

            Debug.Log($"[Terrain] Sinh map {config.width}x{config.depth}, seed {seed}");
        }

        private void CarveBaseEntrance()
        {
            if (!config.carveBaseEntrance) return;
            int chamberWidth = Mathf.Max(2, config.entranceChamberWidth);
            int shaftWidth = Mathf.Clamp(config.entranceShaftWidth, 1, chamberWidth);
            int chamberDepth = Mathf.Max(1, config.entranceChamberDepth);
            int bottom = chamberDepth + Mathf.Max(1, config.entranceShaftDepth);
            // Cập nhật cả dữ liệu ô và Tilemap để collider/logic khoan đều thấy lối trống.
            for (int depth = 0; depth < Mathf.Min(bottom, config.depth); depth++)
            {
                int width = depth < chamberDepth ? chamberWidth : shaftWidth;
                int left = config.entranceCenterX - width / 2;
                for (int x = left; x < left + width; x++)
                    if (x >= MinX && x <= MaxX && ToIndex(new Vector3Int(x, -depth - 1, 0), out int ix, out int iy))
                        cells[ix, iy] = Make(TileKind.Empty, 0);
            }

            int chamberLeft = config.entranceCenterX - chamberWidth / 2;
            int shaftLeft = config.entranceCenterX - shaftWidth / 2;
            for (int row = 0; row < chamberDepth; row++)
            {
                Reinforce(chamberLeft - 1, row);
                Reinforce(chamberLeft + chamberWidth, row);
            }
            for (int x = chamberLeft; x < chamberLeft + chamberWidth; x++)
                if (x < shaftLeft || x >= shaftLeft + shaftWidth) Reinforce(x, chamberDepth);
        }

        private void Reinforce(int x, int row)
        {
            if (!ToIndex(new Vector3Int(x, -row - 1, 0), out int ix, out int iy)) return;
            if (!cells[ix, iy].IsSolid) cells[ix, iy] = BaseCell(row);
            cells[ix, iy].reinforced = true;
        }

        private void BuildEntranceFloors()
        {
            var floors = tilemap.transform.Find("BaseEntranceFloors");
            if (!config.carveBaseEntrance)
            {
                if (floors) floors.gameObject.SetActive(false);
                return;
            }
            if (!floors)
            {
                floors = new GameObject("BaseEntranceFloors").transform;
                floors.SetParent(tilemap.transform, false);
            }
            floors.gameObject.SetActive(true);
            float width = Mathf.Max(2, config.entranceChamberWidth);
            float opening = EntranceOpeningWidth;
            float ledge = (width - opening) * .5f;
            float thickness = Mathf.Max(.01f, config.entranceFloorThickness);
            for (int level = 0; level < 2; level++)
            for (int side = 0; side < 2; side++)
            {
                string name = $"Floor_{level}_{side}";
                var part = floors.Find(name);
                if (!part)
                {
                    part = new GameObject(name, typeof(BoxCollider2D)).transform;
                    part.SetParent(floors, false);
                }
                part.gameObject.layer = tilemap.gameObject.layer;
                part.localPosition = new Vector3(config.entranceCenterX + (side == 0 ? -1 : 1) * (opening + ledge) * .5f,
                    -level * Mathf.Max(1, config.entranceChamberDepth) - thickness * .5f, 0);
                var collider = part.GetComponent<BoxCollider2D>();
                collider.enabled = ledge > 0;
                collider.size = new Vector2(Mathf.Max(.01f, ledge), thickness);
            }
        }

        // ---------------- API cho Drill / Player ----------------

        public Vector3Int WorldToCell(Vector3 world) => tilemap.WorldToCell(world);
        public Vector3 CellCenter(Vector3Int cell) => tilemap.GetCellCenterWorld(cell);

        public bool TryGetCell(Vector3Int cell, out TerrainCell data)
        {
            if (cells != null && ToIndex(cell, out int ix, out int iy))
            {
                data = cells[ix, iy];
                return true;
            }
            data = default;
            return false;
        }

        public bool IsSolid(Vector3Int cell) => TryGetCell(cell, out var c) && c.IsSolid;

        /// <summary>Gây damage vào ô. Trả về true nếu ô vỡ ở lần này.</summary>
        public bool Damage(Vector3Int cell, float amount)
        {
            if (!ToIndex(cell, out int ix, out int iy)) return false;
            ref var c = ref cells[ix, iy];
            if (!c.IsBreakable) return false;

            c.hp -= amount;
            if (c.hp > 0f) return false;

            var before = c;
            c = Make(TileKind.Empty, 0);
            tilemap.SetTile(cell, null);
            OnCellDestroyed?.Invoke(cell, before);
            return true;
        }

        /// <summary>Tỉ lệ HP còn lại 0..1 (để chọn frame tile_crack).</summary>
        public float HpRatio(Vector3Int cell) =>
            TryGetCell(cell, out var c) && c.maxHp > 0 ? Mathf.Clamp01(c.hp / c.maxHp) : 1f;

        /// <summary>Độ sâu theo số ô của 1 vị trí (0 = trên mặt đất).</summary>
        /// (chân đứng ở y = -1 => đang ở hàng ô thứ 1 => độ sâu 1)
        public static int DepthOf(Vector3 world) => Mathf.Max(0, Mathf.CeilToInt(-world.y - 0.001f));

        // ---------------- Sinh map ----------------

        private TerrainCell BaseCell(int depthIndex)
        {
            if (depthIndex == 0) return Make(TileKind.Surface, config.surfaceHp);
            if (depthIndex < config.layer2Depth) return Make(TileKind.Layer1, config.layer1Hp);
            if (depthIndex < config.layer3Depth) return Make(TileKind.Layer2, config.layer2Hp);
            return Make(TileKind.Layer3, config.layer3Hp);
        }

        private void PlaceOres()
        {
            for (int r = 0; r < config.ores.Count; r++)
            {
                var rule = config.ores[r];
                int from = Mathf.Max(1, rule.minDepth);
                int to = Mathf.Min(config.depth - 1, rule.maxDepth);
                for (int iy = from; iy <= to; iy++)
                for (int ix = 1; ix <= config.width; ix++)
                {
                    if (rng.NextDouble() >= rule.veinChance) continue;
                    int size = rng.Next(rule.veinSizeMin, rule.veinSizeMax + 1);
                    int x = ix, y = iy;
                    for (int s = 0; s < size; s++)
                    {
                        if (x >= 1 && x <= config.width && y >= 1 && y < config.depth)
                        {
                            var baseHp = BaseCell(y).maxHp;
                            cells[x, y] = new TerrainCell
                            {
                                kind = TileKind.Ore,
                                ore = rule.type,
                                oreAmount = rule.dropAmount,
                                maxHp = baseHp + rule.extraHp,
                                hp = baseHp + rule.extraHp,
                            };
                        }
                        // đi ngẫu nhiên 4 hướng => mạch quặng liền nhau
                        switch (rng.Next(4))
                        {
                            case 0: x++; break;
                            case 1: x--; break;
                            case 2: y++; break;
                            default: y--; break;
                        }
                    }
                }
            }
        }

        private void CarveCaves()
        {
            for (int iy = 4; iy < config.depth - 1; iy++)
            for (int ix = 2; ix < config.width; ix++)
            {
                if (rng.NextDouble() >= config.caveChance) continue;
                int size = rng.Next(2, config.caveSizeMax + 1);
                int x = ix, y = iy;
                for (int s = 0; s < size; s++)
                {
                    if (x >= 1 && x <= config.width && y >= 2 && y < config.depth && cells[x, y].kind != TileKind.Ore)
                        cells[x, y] = Make(TileKind.Empty, 0);
                    if (rng.Next(2) == 0) x += rng.Next(2) == 0 ? 1 : -1;
                    else y += rng.Next(2) == 0 ? 1 : -1;
                }
            }
        }

        private void PaintAll()
        {
            tilemap.ClearAllTiles();
            int w = config.width + 2, h = config.depth + 1;
            var positions = new Vector3Int[w * h];
            var tiles = new TileBase[w * h];
            int i = 0;
            for (int ix = 0; ix < w; ix++)
            for (int iy = 0; iy < h; iy++)
            {
                positions[i] = ToCell(ix, iy);
                tiles[i] = TileFor(cells[ix, iy]);
                i++;
            }
            tilemap.SetTiles(positions, tiles);
        }

        private TileBase TileFor(TerrainCell c)
        {
            switch (c.kind)
            {
                case TileKind.Surface: return config.surfaceTile;
                case TileKind.Layer1: return config.layer1Tile;
                case TileKind.Layer2: return config.layer2Tile;
                case TileKind.Layer3: return config.layer3Tile;
                case TileKind.Bedrock: return config.bedrockTile;
                case TileKind.Ore:
                    foreach (var r in config.ores)
                        if (r.type == c.ore) return r.tile;
                    return config.layer1Tile;
                default: return null;
            }
        }

        private static TerrainCell Make(TileKind kind, int hp) =>
            new TerrainCell { kind = kind, maxHp = hp, hp = hp };

        private Vector3Int ToCell(int ix, int iy) => new Vector3Int(ix - 1 + MinX, -iy - 1, 0);

        private bool ToIndex(Vector3Int cell, out int ix, out int iy)
        {
            ix = cell.x - MinX + 1;
            iy = -cell.y - 1;
            return cells != null && ix >= 0 && ix < cells.GetLength(0) && iy >= 0 && iy < cells.GetLength(1);
        }
    }
}
