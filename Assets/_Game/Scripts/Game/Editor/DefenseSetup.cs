using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using Underlab.Art;
using Underlab.Defense;
using Underlab.Mining;
using Underlab.UI;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.InputSystem;

namespace Underlab.Game.EditorTools
{
    public static class DefenseSetup
    {
        private const string Data = "Assets/_Game/Data/Defense/";
        [MenuItem("Underlab/Defense/Build Sandbox_B")]
        public static void Sandbox() => Build("Assets/_Game/Scenes/Sandbox_B.unity");
        [MenuItem("Underlab/Defense/Build Integrated Game")]
        public static void Integrated() => Build("Assets/_Game/Scenes/Game.unity");
        private static T Config<T>(string name) where T : ScriptableObject
        {
            string path = Data + name + ".asset";
            var config = AssetDatabase.LoadAssetAtPath<T>(path);
            if (config) return config;
            config = ScriptableObject.CreateInstance<T>();
            AssetDatabase.CreateAsset(config, path);
            return config;
        }
        private static void Build(string destination)
        {
            if (EditorApplication.isPlaying) throw new System.InvalidOperationException("Stop Play Mode trước khi dựng scene.");
            if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) return;
            if (!File.Exists("Assets/_Game/Scenes/Sandbox_A.unity")) throw new FileNotFoundException("Cần scene Sandbox_A đã bàn giao.");
            Directory.CreateDirectory(Data);
            Directory.CreateDirectory("Assets/_Game/Prefabs/Defense");
            AssetDatabase.Refresh();
            // Dựng bản tích hợp từ scene bàn giao, không ghi lại Sandbox_A.
            var scene = EditorSceneManager.OpenScene("Assets/_Game/Scenes/Sandbox_A.unity", OpenSceneMode.Single);
            EditorSceneManager.SaveScene(scene, destination);
            foreach (var root in scene.GetRootGameObjects())
            {
                foreach (var clock in root.GetComponentsInChildren<DebugWaveClock>(true)) Object.DestroyImmediate(clock);
                foreach (var hud in root.GetComponentsInChildren<MiningDebugHud>(true)) Object.DestroyImmediate(hud);
            }
            var balance = Config<DefenseConfig>("DefenseConfig");
            var waves = Config<WaveConfig>("WaveConfig");
            if (waves.waves.Any(w => w == null))
            {
                for (int i = 0; i < waves.waves.Length; i++)
                    waves.waves[i] = new WaveConfig.Wave {
                        miningSeconds = 90, spawnDelay = Mathf.Max(.4f, 1.5f - i * .1f),
                        melee = 4 + i * 2, flying = i >= 2 ? i : 0, ranged = i >= 3 ? i / 2 : 0,
                        bosses = i == waves.waves.Length - 1 ? 1 : 0,
                        healthScale = 1 + i * .16f, speedScale = 1 + i * .025f
                    };
                EditorUtility.SetDirty(waves);
            }
            string[] ids = { "drill", "move", "carry", "jetpack", "lift", "blast", "turret_damage", "turret_rotate", "base_hp", "repair" };
            string[] names = { "Khoan", "Di chuyển", "Sức mang", "Jetpack", "Thang máy", "Bom phá đá", "Sát thương pháo", "Xoay pháo", "Máu base", "Sửa base" };
            var defs = new UpgradeDef[ids.Length];
            for (int i = 0; i < ids.Length; i++)
            {
                bool exists = File.Exists(Data + ids[i] + ".asset");
                defs[i] = Config<UpgradeDef>(ids[i]);
                if (exists) continue;
                defs[i].id = ids[i]; defs[i].displayName = names[i];
                if (i < 4) defs[i].ironCosts = new[] { 5, 10, 20, 35 };
                if (ids[i] == "lift") defs[i].ironCosts = new[] { 20 };
                if (ids[i] == "blast" || ids[i] == "repair") { defs[i].ironCosts = new[] { 5 }; defs[i].repeatable = true; }
                EditorUtility.SetDirty(defs[i]);
            }
            var rootB = new GameObject("[Defense]");
            var baseGo = scene.GetRootGameObjects().First(go => go.GetComponent<DepositZone>());
            baseGo.name = "Base"; baseGo.transform.SetParent(rootB.transform);
            Object.DestroyImmediate(baseGo.GetComponent<ArtSprite>());
            baseGo.AddComponent<DefenseVisual>().artId = "bld_base_normal";
            var health = baseGo.AddComponent<BaseHealth>(); health.config = balance;
            var bank = rootB.AddComponent<ResourceBank>();
            var poolGo = new GameObject("Combat Pool"); poolGo.transform.SetParent(rootB.transform);
            var pool = poolGo.AddComponent<CombatPool>(); pool.config = balance; pool.target = health;
            var audioFx = rootB.AddComponent<DefenseAudio>(); audioFx.config = Config<DefenseAudioConfig>("DefenseAudioConfig"); pool.audioFx = audioFx;
            var spawner = rootB.AddComponent<WaveSpawner>(); spawner.config = waves; spawner.pool = pool;
            var game = rootB.AddComponent<GameManager>(); game.config = waves; game.baseHealth = health; game.spawner = spawner;
            var shop = rootB.AddComponent<DefenseShop>(); shop.bank = bank; shop.baseHealth = health; shop.upgrades = defs;
            var body = Visual("Turret", "bld_turret_body", rootB.transform, new Vector3(0, 2, 0));
            var barrel = Visual("Barrel", "bld_turret_barrel", body.transform, Vector3.up * .4f);
            var muzzle = new GameObject("Muzzle"); muzzle.transform.SetParent(barrel.transform); muzzle.transform.localPosition = Vector3.right * 1.5f;
            var turret = body.AddComponent<Turret>(); turret.barrel = barrel.transform; turret.muzzle = muzzle.transform;
            turret.aimCamera = Camera.main; turret.pool = pool; turret.shop = shop; turret.game = game;
            turret.inputActions = AssetDatabase.LoadAssetAtPath<InputActionAsset>("Assets/InputSystem_Actions.inputactions");
            var hudB = rootB.AddComponent<DefenseHud>(); hudB.game = game; hudB.baseHealth = health; hudB.bank = bank; hudB.shop = shop; hudB.turret = turret;
            // Camera thuộc scene; gán lại sau khi instantiate prefab để không lưu reference ngoài prefab.
            turret.aimCamera = null;
            foreach (var sr in rootB.GetComponentsInChildren<SpriteRenderer>(true)) sr.sprite = null;
            string prefabPath = "Assets/_Game/Prefabs/Defense/DefenseRoot.prefab";
            PrefabUtility.SaveAsPrefabAssetAndConnect(rootB, prefabPath, InteractionMode.AutomatedAction);
            turret.aimCamera = Camera.main;
            PrefabUtility.RecordPrefabInstancePropertyModifications(turret);
            AssetDatabase.SaveAssets();
            EditorSceneManager.SaveScene(scene, destination);
            EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(destination, true) };
            Debug.Log("[Defense] Đã dựng " + destination + " — Play để chạy 10 wave.");
        }
        private static GameObject Visual(string name, string id, Transform parent, Vector3 position)
        {
            var go = new GameObject(name, typeof(SpriteRenderer), typeof(DefenseVisual));
            go.transform.SetParent(parent); go.transform.localPosition = position;
            go.GetComponent<SpriteRenderer>().sortingOrder = 8;
            go.GetComponent<DefenseVisual>().artId = id;
            return go;
        }
        public static void StripPreviewSprites()
        {
            // ArtSprite ExecuteAlways gán hình xem trước; không lưu cache PNG vào bản bàn giao.
            foreach (string path in new[] { "Assets/_Game/Scenes/Sandbox_B.unity", "Assets/_Game/Scenes/Game.unity", "Assets/_Game/Prefabs/Defense/DefenseRoot.prefab" })
                if (File.Exists(path)) File.WriteAllText(path, Regex.Replace(File.ReadAllText(path), @"(?m)^  m_Sprite: .+\r?$", "  m_Sprite: {fileID: 0}"));
        }
    }
}
