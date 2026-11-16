using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Tilemaps;
using Underlab.Art;
using Underlab.Core;
using Underlab.EditorTools.Art;
using Underlab.Mining;
using Underlab.Player;

namespace Underlab.EditorTools.Mining
{
    /// <summary>
    /// Dựng tự động scene Sandbox_A (test phần đào) + các config mặc định.
    /// Chạy lại được nhiều lần: config đã có thì giữ nguyên số đã chỉnh, scene thì dựng lại.
    /// </summary>
    public static class MiningSandboxSetup
    {
        private const string DataFolder = "Assets/_Game/Data/Mining";
        private const string ScenePath = "Assets/_Game/Scenes/Sandbox_A.unity";
        private const string TerrainConfigPath = DataFolder + "/TerrainConfig.asset";
        private const string PlayerConfigPath = DataFolder + "/PlayerConfig.asset";
        private const string DrillConfigPath = DataFolder + "/DrillConfig.asset";

        [MenuItem("Underlab/Mining/Build Sandbox_A Scene", priority = 100)]
        public static void Build()
        {
            if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) return;

            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            // Load config SAU NewScene (NewScene dọn asset không dùng => load trước sẽ bị unload mất).
            var terrainConfig = GetOrCreateTerrainConfig();
            var playerConfig = GetOrCreate<PlayerConfig>(PlayerConfigPath);
            var drillConfig = GetOrCreate<DrillConfig>(DrillConfigPath);
            var carrierConfig = GetOrCreate<CarrierConfig>(DataFolder + "/CarrierConfig.asset");

            // Ánh sáng 2D toàn cục (URP 2D cần light để sprite Lit hiện đúng màu)
            var lightGo = new GameObject("Global Light 2D");
            var light = lightGo.AddComponent<Light2D>();
            light.lightType = Light2D.LightType.Global;
            light.intensity = 1f;

            // Grid + Tilemap địa hình
            var grid = new GameObject("World", typeof(Grid));
            var tmGo = new GameObject("Terrain");
            tmGo.transform.SetParent(grid.transform, false);
            var tilemap = tmGo.AddComponent<Tilemap>();
            tmGo.AddComponent<TilemapRenderer>();
            var rb = tmGo.AddComponent<Rigidbody2D>();
            rb.bodyType = RigidbodyType2D.Static;
            var tmCol = tmGo.AddComponent<TilemapCollider2D>();
            tmCol.compositeOperation = Collider2D.CompositeOperation.Merge;
            var comp = tmGo.AddComponent<CompositeCollider2D>();
            comp.geometryType = CompositeCollider2D.GeometryType.Polygons;

            var gen = grid.AddComponent<TerrainGenerator>();
            Set(gen, "config", terrainConfig);
            Set(gen, "tilemap", tilemap);

            // Base TẠM (base thật là prefab của Dev B — B02). Chỉ để test gửi quặng.
            var baseGo = new GameObject("Base (placeholder)");
            var baseSr = baseGo.AddComponent<SpriteRenderer>();
            baseSr.sortingOrder = 2;
            var baseArt = baseGo.AddComponent<ArtSprite>();
            Set(baseArt, "artId", "bld_base_normal");
            var zone = baseGo.AddComponent<BoxCollider2D>();
            zone.isTrigger = true;
            zone.size = new Vector2(3f, 2.5f);
            zone.offset = new Vector2(0f, 1.25f);
            baseGo.AddComponent<DepositZone>();

            // Player
            var player = new GameObject("Player");
            player.transform.position = new Vector3(0f, 0.05f, 0f);
            var sr = player.AddComponent<SpriteRenderer>();
            sr.sortingOrder = 10;
            var art = player.AddComponent<ArtSprite>();
            Set(art, "artId", "char_player_idle");
            var prb = player.AddComponent<Rigidbody2D>();
            prb.freezeRotation = true;
            var cap = player.AddComponent<CapsuleCollider2D>();
            cap.direction = CapsuleDirection2D.Vertical;
            cap.size = new Vector2(0.55f, 0.8f);
            cap.offset = new Vector2(0f, 0.4f);
            var pc = player.AddComponent<PlayerController>();
            Set(pc, "config", playerConfig);
            Set(pc, "art", art);

            // Vết nứt trên ô đang khoan (không làm con của Player để không bị lật theo)
            var crack = new GameObject("DrillCrack");
            var crackSr = crack.AddComponent<SpriteRenderer>();
            crackSr.sortingOrder = 5;
            var crackArt = crack.AddComponent<ArtSprite>();
            Set(crackArt, "artId", "tile_crack");
            SetBool(crackArt, "playOnEnable", false);
            crack.SetActive(false);

            var drill = player.AddComponent<Drill>();
            Set(drill, "config", drillConfig);
            Set(drill, "terrain", gen);
            Set(drill, "crackOverlay", crackArt);

            var carrier = player.AddComponent<Carrier>();
            Set(carrier, "config", carrierConfig);
            player.AddComponent<CarrierFeedback>();

            var hud = new GameObject("MiningDebugHud").AddComponent<MiningDebugHud>();
            Set(hud, "player", pc);
            Set(hud, "carrier", carrier);

            // Camera
            var camGo = new GameObject("Main Camera", typeof(Camera), typeof(AudioListener));
            camGo.tag = "MainCamera";
            camGo.transform.position = new Vector3(0f, 0f, -10f);
            var cam = camGo.GetComponent<Camera>();
            cam.orthographic = true;
            cam.orthographicSize = 7f;
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(0.12f, 0.1f, 0.2f);
            camGo.AddComponent<UniversalAdditionalCameraData>();
            var follow = camGo.AddComponent<CameraFollow>();
            Set(follow, "target", player.transform);
            Set(follow, "terrain", gen);

            // Vòng chơi giả + HUD (A09) + cảnh báo wave (A10)
            var systems = new GameObject("[Mining Systems]");
            systems.AddComponent<DebugWaveClock>();
            var miningHud = systems.AddComponent<Underlab.UI.MiningHud>();
            Set(miningHud, "carrier", carrier);
            var upgrades = systems.AddComponent<MiningUpgrades>();
            Set(upgrades, "config", GetOrCreate<MiningUpgradeConfig>(DataFolder + "/MiningUpgradeConfig.asset"));
            Set(upgrades, "player", pc);
            Set(upgrades, "drill", drill);
            Set(upgrades, "carrier", carrier);

            var lift = systems.AddComponent<LiftSystem>();
            Set(lift, "player", pc);
            Set(lift, "carrier", carrier);

            var blast = systems.AddComponent<BlastMining>();
            Set(blast, "player", pc);
            Set(blast, "terrain", gen);
            Set(blast, "cameraFollow", follow);

            var alert = systems.AddComponent<WaveAlert>();
            Set(alert, "player", pc);
            Set(alert, "cameraFollow", follow);

            // Nền parallax (A11). Lòng đất vẽ sau cùng; trời + núi che phần trên mặt đất.
            var bgRoot = new GameObject("Backgrounds");
            // id, follow, anchor, size, tint, order
            AddLayer(bgRoot, camGo.transform, "bg_underground_far", new Vector2(0.85f, 0.85f), new Vector2(0, -150), new Vector2(150, 300), new Color(0.55f, 0.55f, 0.65f), -40);
            AddLayer(bgRoot, camGo.transform, "bg_underground_mid", new Vector2(0.6f, 0.6f), new Vector2(0, -150), new Vector2(150, 300), new Color(0.75f, 0.75f, 0.8f), -35);
            AddLayer(bgRoot, camGo.transform, "bg_surface_sky", new Vector2(1f, 0f), new Vector2(0, 20f), new Vector2(300, 40), Color.white, -30);
            AddLayer(bgRoot, camGo.transform, "bg_surface_far", new Vector2(0.85f, 0f), new Vector2(0, 5.625f), new Vector2(300, 11.25f), Color.white, -25);
            AddLayer(bgRoot, camGo.transform, "bg_surface_mid", new Vector2(0.6f, 0f), new Vector2(0, 5.625f), new Vector2(300, 11.25f), Color.white, -20);

            ArtDatabaseBuilder.EnsureFolder("Assets/_Game/Scenes");
            EditorSceneManager.SaveScene(scene, ScenePath);
            Debug.Log($"[Mining] Đã dựng {ScenePath}. Bấm Play: A/D đi, giữ Space bay, giữ S/A/D/W vào đất để khoan.");
        }

        private static TerrainConfig GetOrCreateTerrainConfig()
        {
            var existing = AssetDatabase.LoadAssetAtPath<TerrainConfig>(TerrainConfigPath);
            if (existing != null) return existing;

            var c = ScriptableObject.CreateInstance<TerrainConfig>();
            c.surfaceTile = Tile("tile_surface");
            c.layer1Tile = Tile("tile_dirt_1");
            c.layer2Tile = Tile("tile_dirt_2");
            c.layer3Tile = Tile("tile_dirt_3");
            c.bedrockTile = Tile("tile_bedrock");
            c.ores.Add(Ore(ResourceType.Iron, "tile_ore_iron", 2, 999, 0.03f, 2, 5, 1));
            c.ores.Add(Ore(ResourceType.Sulfur, "tile_ore_sulfur", 10, 80, 0.015f, 2, 4, 2));
            c.ores.Add(Ore(ResourceType.Magnesium, "tile_ore_mg", 30, 999, 0.012f, 2, 4, 3));
            c.ores.Add(Ore(ResourceType.KCl, "tile_ore_kcl", 50, 999, 0.01f, 2, 3, 4));

            ArtDatabaseBuilder.EnsureFolder(DataFolder);
            AssetDatabase.CreateAsset(c, TerrainConfigPath);
            AssetDatabase.SaveAssets();
            return c;
        }

        private static TerrainConfig.OreRule Ore(ResourceType t, string tileId, int min, int max, float chance, int smin, int smax, int extraHp) =>
            new TerrainConfig.OreRule
            {
                type = t, tile = Tile(tileId), minDepth = min, maxDepth = max,
                veinChance = chance, veinSizeMin = smin, veinSizeMax = smax, extraHp = extraHp, dropAmount = 1,
            };

        private static TileBase Tile(string id)
        {
            var t = AssetDatabase.LoadAssetAtPath<TileBase>($"{ArtDatabaseBuilder.TilesFolder}/{id}.asset");
            if (t == null) Debug.LogWarning($"[Mining] Thiếu tile {id} — chạy Underlab/Art/Generate Missing Placeholders");
            return t;
        }

        private static T GetOrCreate<T>(string path) where T : ScriptableObject
        {
            var a = AssetDatabase.LoadAssetAtPath<T>(path);
            if (a != null) return a;
            a = ScriptableObject.CreateInstance<T>();
            ArtDatabaseBuilder.EnsureFolder(System.IO.Path.GetDirectoryName(path).Replace('\\', '/'));
            AssetDatabase.CreateAsset(a, path);
            AssetDatabase.SaveAssets();
            return a;
        }

        private static void Set(Object target, string field, Object value)
        {
            var so = new SerializedObject(target);
            so.FindProperty(field).objectReferenceValue = value;
            so.ApplyModifiedPropertiesWithoutUndo();
        }

        private static void AddLayer(GameObject root, Transform cam, string id, Vector2 follow, Vector2 anchor,
                                     Vector2 size, Color tint, int order)
        {
            var go = new GameObject(id);
            go.transform.SetParent(root.transform, false);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sortingOrder = order;
            var layer = go.AddComponent<ParallaxLayer>();
            var so = new SerializedObject(layer);
            so.FindProperty("artId").stringValue = id;
            so.FindProperty("follow").vector2Value = follow;
            so.FindProperty("anchor").vector2Value = anchor;
            so.FindProperty("size").vector2Value = size;
            so.FindProperty("tint").colorValue = tint;
            so.FindProperty("cameraTransform").objectReferenceValue = cam;
            so.ApplyModifiedPropertiesWithoutUndo();
        }

        private static void SetBool(Object target, string field, bool value)
        {
            var so = new SerializedObject(target);
            so.FindProperty(field).boolValue = value;
            so.ApplyModifiedPropertiesWithoutUndo();
        }

        private static void Set(Object target, string field, string value)
        {
            var so = new SerializedObject(target);
            so.FindProperty(field).stringValue = value;
            so.ApplyModifiedPropertiesWithoutUndo();
        }
    }
}
