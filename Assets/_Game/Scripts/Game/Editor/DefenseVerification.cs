using System;
using System.IO;
using Underlab.Core;
using Underlab.Defense;
using UnityEditor;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.LowLevel;

namespace Underlab.Game.EditorTools
{
    [InitializeOnLoad]
    public static class DefenseVerification
    {
        private const string Key = "Underlab.Defense.Verify";
        private static GameManager game;
        private static int checks, frames;
        private static double deadline;
        private static bool batch;
        private static Enemy combatTarget;
        private static float combatHealth;
        private static double combatDeadline;
        private static bool combatVerified;
        private static bool hostileVerified;
        private static int initialBaseHealth;
        static DefenseVerification() { EditorApplication.playModeStateChanged += Changed; }
        [MenuItem("Underlab/Defense/Verify Play Mode")]
        public static void Run()
        {
            if (EditorApplication.isPlaying) throw new InvalidOperationException("Stop Play Mode trước.");
            SessionState.SetBool(Key, true);
            EditorApplication.isPlaying = true;
        }
        public static void Batch()
        {
            DefenseSetup.Sandbox(); DefenseSetup.Integrated();
            SessionState.SetBool(Key + ".batch", true);
            Run();
        }
        public static void BatchTurretBoarding()
        {
            DefenseSetup.BindTurretPlayers();
            SessionState.SetBool(Key + ".batch", true);
            Run();
        }
        private static void Changed(PlayModeStateChange state)
        {
            if (state == PlayModeStateChange.EnteredPlayMode && SessionState.GetBool(Key, false))
            {
                batch = SessionState.GetBool(Key + ".batch", false);
                checks = frames = 0; game = null; combatVerified = hostileVerified = false; deadline = EditorApplication.timeSinceStartup + 60;
                EditorApplication.update += Tick;
            }
            if (state == PlayModeStateChange.EnteredEditMode && SessionState.GetBool(Key + ".exit", false))
            {
                SessionState.SetBool(Key + ".exit", false);
                DefenseSetup.StripPreviewSprites();
                EditorApplication.Exit(SessionState.GetInt(Key + ".code", 1));
            }
        }
        private static void Check(bool condition, string message)
        {
            if (!condition) throw new Exception(message);
            checks++;
        }
        private static void CheckTurretInput(Turret turret)
        {
            var mouse = InputSystem.AddDevice<Mouse>();
            var keyboard = InputSystem.AddDevice<Keyboard>();
            var background = InputSystem.settings.backgroundBehavior;
            var editorInput = InputSystem.settings.editorInputBehaviorInPlayMode;
            Action updateTurret = () => turret.SendMessage("Update");
            try
            {
                InputSystem.settings.backgroundBehavior = InputSettings.BackgroundBehavior.IgnoreFocus;
                InputSystem.settings.editorInputBehaviorInPlayMode = InputSettings.EditorInputBehaviorInPlayMode.AllDeviceInputAlwaysGoesToGameView;
                InputSystem.onAfterUpdate += updateTurret;
                var pointer = new Vector2(Screen.width * .5f, Screen.height * .75f);
                InputSystem.QueueStateEvent(mouse, new MouseState { position = pointer }); InputSystem.Update();
                InputSystem.QueueStateEvent(mouse, new MouseState { position = pointer, buttons = 1 }); InputSystem.Update();
                Check(turret.IsMounted && !turret.playerRoot.activeSelf, $"Mouse input did not board turret: CanMount={turret.CanMount} current={Mouse.current == mouse} down={mouse.leftButton.isPressed} pressed={mouse.leftButton.wasPressedThisFrame} point={mouse.position.ReadValue()} screen={Screen.width}x{Screen.height}");
                InputSystem.QueueStateEvent(mouse, new MouseState { position = pointer, buttons = 1 }); InputSystem.Update();
                Check(turret.pool.GetComponentsInChildren<Projectile>().Length == 0, "Boarding click also fired a projectile");
                InputSystem.QueueStateEvent(keyboard, new KeyboardState(UnityEngine.InputSystem.Key.Q)); InputSystem.Update();
                Check(!turret.IsMounted && turret.playerRoot.activeSelf, "Q input did not restore player");
            }
            finally
            {
                InputSystem.onAfterUpdate -= updateTurret;
                InputSystem.RemoveDevice(mouse); InputSystem.RemoveDevice(keyboard);
                InputSystem.settings.backgroundBehavior = background;
                InputSystem.settings.editorInputBehaviorInPlayMode = editorInput;
            }
        }
        private static void Tick()
        {
            try
            {
                if (EditorApplication.timeSinceStartup > deadline) throw new TimeoutException("Wave lifecycle timed out");
                if (++frames < 4) return;
                if (!game)
                {
                    game = UnityEngine.Object.FindFirstObjectByType<GameManager>();
                    Check(game != null, "Missing GameManager");
                    Check(UnityEngine.Object.FindObjectsByType<Underlab.Mining.DebugWaveClock>(FindObjectsSortMode.None).Length == 0, "Debug clock in integrated scene");
                    var shop = UnityEngine.Object.FindFirstObjectByType<DefenseShop>();
                    var turret = UnityEngine.Object.FindFirstObjectByType<Turret>();
                    game.StartRun();
                    Check(turret.playerRoot != null, "Turret missing player reference");
                    GameObject originalPlayer = turret.playerRoot;
                    turret.playerRoot = null;
                    Check(turret.CanMount && turret.playerRoot == originalPlayer, "Missing player reference was not recovered");
                    Vector3 playerPosition = turret.playerRoot.transform.position;
                    turret.playerRoot.transform.position += Vector3.right * (turret.pool.config.turretBoardingRadius + 5);
                    Check(!turret.TryMount(), "Boarding allowed away from turret");
                    turret.playerRoot.transform.position = playerPosition;
                    Check(turret.TryMount() && turret.IsMounted && !turret.playerRoot.activeSelf, "Boarding did not hide player");
                    Check(!turret.TryMount(), "Boarding accepted while already mounted");
                    turret.Dismount();
                    Check(!turret.IsMounted && turret.playerRoot.activeSelf && turret.playerRoot.transform.position == playerPosition, "Dismount did not restore player position");
                    game.TogglePause(); Check(!turret.TryMount(), "Boarding accepted while paused"); game.TogglePause();
                    CheckTurretInput(turret);
                    GameEvents.RaisePlayerAtBaseChanged(true);
                    GameEvents.RaiseResourcesDeposited(ResourceType.Iron, 1000);
                    Check(shop.bank.Balance(ResourceType.Iron) == 1000, "Deposits not received");
                    Check(!shop.bank.Spend(ResourceType.Iron, -1), "Negative spend accepted");
                    var drill = Array.Find(shop.upgrades, x => x.id == UpgradeIds.Drill);
                    Check(shop.Buy(drill), "Mining upgrade purchase failed");
                    Check(Underlab.Mining.MiningUpgrades.Instance.Level(UpgradeIds.Drill) == 1, "Mining did not receive upgrade event");
                    while (shop.CanBuy(drill)) Check(shop.Buy(drill), "Upgrade cap loop failed");
                    Check(!shop.Buy(drill), "Over-cap purchase accepted");
                    GameEvents.RaiseResourcesDeposited(ResourceType.Magnesium, 2);
                    Check(turret.Craft(2) && turret.Ammunition[2] == turret.pool.config.ammo[2].craftYield, "Fire recipe failed");
                    Check(!turret.Craft(2), "Craft allowed without resources");
                    game.baseHealth.Damage(10); game.baseHealth.Repair();
                    Check(game.baseHealth.Current == game.baseHealth.Maximum, "Repair failed");
                    GameEvents.RaisePlayerAtBaseChanged(false);
                    Check(!shop.Buy(drill) && !turret.Craft(1), "Shop allowed away from base");
                    // Chỉ thay bản sao config trong Play Mode; giữ nguyên balance asset.
                    var waves = UnityEngine.Object.Instantiate(game.config);
                    for (int i = 0; i < waves.waves.Length; i++)
                        waves.waves[i] = new WaveConfig.Wave { miningSeconds = .05f, spawnDelay = .01f, melee = i < 9 ? 1 : 0, flying = i == 2 ? 1 : 0, ranged = i == 3 ? 1 : 0, bosses = i == 9 ? 1 : 0 };
                    game.config = game.spawner.config = waves;
                    combatTarget = game.spawner.pool.Spawn(EnemyKind.Melee, Vector3.right * 4);
                    combatHealth = combatTarget.Health;
                    game.spawner.pool.Shoot(Vector3.up, Vector3.right, 10, 0, false);
                    combatDeadline = EditorApplication.timeSinceStartup + 3;
                    return;
                }
                if (!combatVerified)
                {
                    if (combatTarget.Health >= combatHealth)
                    {
                        if (EditorApplication.timeSinceStartup > combatDeadline) throw new Exception("Projectile did not hit target");
                        return;
                    }
                    Check(combatTarget.Health < combatHealth, "Projectile hit failed");
                    combatTarget.Hit(float.MaxValue);
                    var reused = game.spawner.pool.Spawn(EnemyKind.Flying, Vector3.up * 5);
                    Check(reused == combatTarget && reused.Kind == EnemyKind.Flying, "Enemy pool reuse failed");
                    reused.Hit(float.MaxValue);
                    combatVerified = true;
                    initialBaseHealth = game.baseHealth.Current;
                    game.spawner.pool.Spawn(EnemyKind.Ranged, Vector3.right * 6);
                    combatDeadline = EditorApplication.timeSinceStartup + 3;
                    return;
                }
                if (!hostileVerified)
                {
                    if (game.baseHealth.Current == initialBaseHealth)
                    {
                        if (EditorApplication.timeSinceStartup > combatDeadline) throw new Exception("Ranged enemy did not damage base");
                        return;
                    }
                    Check(game.baseHealth.Current < initialBaseHealth, "Ranged projectile hit failed");
                    game.spawner.pool.Clear(); game.baseHealth.Restore(); hostileVerified = true;
                    Check(UnityEngine.Object.FindFirstObjectByType<Turret>().TryMount(), "Could not board before defense wave");
                    game.BeginWave();
                }
                foreach (var enemy in game.spawner.pool.Enemies)
                    if (enemy.gameObject.activeSelf) enemy.Hit(float.MaxValue);
                if (game.Phase != GamePhase.Victory) return;
                Check(game.Wave == 10, "Victory before ten waves");
                Check(game.spawner.pool.Alive == 0, "Enemies remain after victory");
                var mountedTurret = UnityEngine.Object.FindFirstObjectByType<Turret>();
                Check(!mountedTurret.IsMounted && mountedTurret.playerRoot.activeSelf, "Victory did not restore mounted player");
                var loseGame = new GameObject("Loss check").AddComponent<GameManager>();
                loseGame.config = game.config; loseGame.spawner = game.spawner; loseGame.baseHealth = game.baseHealth;
                loseGame.StartRun(); game.baseHealth.Damage(game.baseHealth.Maximum);
                Check(loseGame.Phase == GamePhase.GameOver, "Base destruction did not end run");
                Check(game.Phase == GamePhase.Victory, "Terminal victory changed after later damage");
                Finish(true, $"PASS: {checks} assertions; friendly and ranged projectile hits; pool reuse; ten waves and boss; victory and defeat");
            }
            catch (Exception error) { Finish(false, error.ToString()); }
        }
        private static void Finish(bool success, string message)
        {
            EditorApplication.update -= Tick;
            SessionState.SetBool(Key, false);
            Directory.CreateDirectory("Logs"); File.WriteAllText("Logs/DefenseVerification.txt", message);
            if (success) Debug.Log("[DefenseVerification] " + message); else Debug.LogError("[DefenseVerification] " + message);
            if (batch) { SessionState.SetInt(Key + ".code", success ? 0 : 1); SessionState.SetBool(Key + ".exit", true); }
            EditorApplication.isPlaying = false;
        }
    }
}
