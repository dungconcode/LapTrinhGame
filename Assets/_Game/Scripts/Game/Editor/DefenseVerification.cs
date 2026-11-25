using System;
using System.IO;
using Underlab.Art;
using Underlab.Core;
using Underlab.Defense;
using Underlab.Mining;
using UnityEditor;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.LowLevel;
using InputKey = UnityEngine.InputSystem.Key;

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
        private static bool previousRunInBackground;
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
                previousRunInBackground = Application.runInBackground;
                Application.runInBackground = true;
                checks = frames = 0; game = null; combatVerified = hostileVerified = false; deadline = EditorApplication.timeSinceStartup + 60;
                EditorApplication.update += Tick;
            }
            if (state == PlayModeStateChange.ExitingPlayMode && SessionState.GetBool(Key, false))
            {
                EditorApplication.update -= Tick;
                Application.runInBackground = previousRunInBackground;
                SessionState.SetBool(Key, false);
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
                InputSystem.QueueStateEvent(mouse, new MouseState { position = pointer }); InputSystem.Update();
                turret.Ammunition[2] = 1;
                InputSystem.QueueStateEvent(keyboard, new KeyboardState(UnityEngine.InputSystem.Key.Digit3)); InputSystem.Update();
                Check((int)turret.Selected == 2, "Combat key 3 did not select its ammo");
                InputSystem.QueueStateEvent(mouse, new MouseState { position = pointer, buttons = 1 }); InputSystem.Update();
                Check(turret.Ammunition[2] == 0 && turret.pool.GetComponentsInChildren<Projectile>().Length == 1,
                    "Combat click did not fire the selected ammo");
                InputSystem.QueueStateEvent(keyboard, new KeyboardState(UnityEngine.InputSystem.Key.Q)); InputSystem.Update();
                Check(!turret.IsMounted && turret.playerRoot.activeSelf, "Q input did not restore player");
                turret.pool.Clear();
                turret.Select(0);
            }
            finally
            {
                InputSystem.onAfterUpdate -= updateTurret;
                InputSystem.RemoveDevice(mouse); InputSystem.RemoveDevice(keyboard);
                InputSystem.settings.backgroundBehavior = background;
                InputSystem.settings.editorInputBehaviorInPlayMode = editorInput;
            }
        }

        private static void CheckDome(BaseHealth baseHealth, Turret turret)
        {
            var dome = baseHealth.GetComponent<DomeVisual>();
            Check(dome != null, "Layered dome missing");
            var shell = dome.GlassDomeLayer.GetComponent<EdgeCollider2D>();
            Physics2D.SyncTransforms();
            var roofHits = Physics2D.LinecastAll(dome.transform.position + Vector3.up, dome.transform.position + Vector3.up * 4);
            Check(Array.Exists(roofHits, hit => hit.collider == shell), "Player path through dome roof is open");
            var sideHits = Physics2D.LinecastAll(dome.transform.position + Vector3.up * .2f,
                dome.transform.position + new Vector3(4, .2f, 0));
            Check(Array.Exists(sideHits, hit => hit.collider == shell), "Player path through dome side is open");
            Check(dome.TryTraceGlass(Vector3.right * 4 + Vector3.up, Vector3.up, out var impact) && impact.x > 1f,
                "Hostile projectile did not contact exterior glass");

            var terrain = UnityEngine.Object.FindFirstObjectByType<TerrainGenerator>();
            int entrance = terrain.Config.entranceCenterX;
            var top = new Vector3Int(entrance + terrain.Config.entranceChamberWidth, -1, 0);
            Check(terrain.TryGetCell(top, out var surface) && surface.IsSolid && !surface.IsBreakable &&
                !terrain.Damage(top, float.MaxValue), "Topsoil can be destroyed");
            CheckHatch(dome.GetComponentInChildren<DomeHatch>(), terrain, turret.playerRoot);

            Check(!dome.CrackOverlay.enabled, "Full HP shows cracks");
            var cracks = dome.CrackOverlay.GetComponent<ArtSprite>();
            int maximum = baseHealth.Maximum;
            baseHealth.DamageFromEnemy(Mathf.CeilToInt(maximum * .3f), dome.transform.position + Vector3.right * 4);
            Check(dome.CrackOverlay.enabled && cracks.Frame == 0, "Light cracks missing");
            Check(GameObject.Find("fx_drill_spark") && GameObject.Find("fx_hit_ice"), "Glass impact effects missing");
            baseHealth.Damage(Mathf.CeilToInt(maximum * .25f));
            Check(cracks.Frame == 1, "Medium cracks missing");
            baseHealth.Damage(Mathf.CeilToInt(maximum * .25f));
            Check(cracks.Frame == 2, "Severe cracks missing");
            baseHealth.Repair();
            Check(cracks.Frame == 1, "Repair did not reduce cracks");
            baseHealth.Restore();
            Check(!dome.CrackOverlay.enabled, "Full repair did not clear cracks");
        }

        private static void CheckHatch(DomeHatch hatch, TerrainGenerator terrain, GameObject player)
        {
            Check(hatch != null, "Upper dome hatch missing");
            var floor = hatch.transform.Find("HatchFloorCollider").GetComponent<BoxCollider2D>();
            var sensor = hatch.transform.Find("HatchAscentSensor").GetComponent<BoxCollider2D>();
            var left = hatch.transform.Find("DomeHatch_Left").GetComponent<SpriteRenderer>();
            var right = hatch.transform.Find("DomeHatch_Right").GetComponent<SpriteRenderer>();
            Check(floor.enabled && !floor.isTrigger && sensor.isTrigger && left.sprite && right.sprite,
                "Hatch did not start closed with both sprites and the ascent sensor");
            Vector3 original = player.transform.position;
            var keyboard = InputSystem.AddDevice<Keyboard>();
            void Step(float y, params InputKey[] keys)
            {
                player.transform.position = hatch.transform.position + Vector3.up * y;
                Physics2D.SyncTransforms();
                InputSystem.QueueStateEvent(keyboard, new KeyboardState(keys));
                InputSystem.Update();
                player.SendMessage("Update");
                player.SendMessage("FixedUpdate");
                hatch.SendMessage("FixedUpdate");
            }

            try
            {
                Step(.02f);
                Check(floor.enabled && player.GetComponent<Underlab.Player.PlayerController>().IsGrounded,
                    "Closed hatch does not support Player");
                Step(.02f, InputKey.DownArrow);
                Check(!floor.enabled, "Down Arrow did not open the hatch");
                Step(-.35f);
                Check(!floor.enabled, "Hatch closed on Player during descent");
                Step(-1.1f);
                Check(floor.enabled, "Hatch did not close after descent");
                Step(-1.1f, InputKey.Space);
                Check(!floor.enabled, "Jetpack did not open the hatch from below");
                Step(-.35f);
                Check(!floor.enabled, "Hatch closed on Player after releasing Space in the opening");
                Step(.04f, InputKey.Space);
                Check(floor.enabled, "Hatch did not immediately restore support after ascent");

                Step(.02f, InputKey.S);
                float depth = terrain.Config.entranceChamberDepth;
                Vector2 center = hatch.transform.position;
                var hits = Physics2D.LinecastAll(center + Vector2.up * .25f, center - Vector2.up * (depth + .25f));
                Check(!Array.Exists(hits, hit => !hit.collider.isTrigger && hit.collider.gameObject != player),
                    "S did not clear the route through both hatches");
                Step(-1.1f);
            }
            finally
            {
                InputSystem.RemoveDevice(keyboard);
                player.transform.position = original;
                player.GetComponent<Rigidbody2D>().linearVelocity = Vector2.zero;
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
                    CheckDome(game.baseHealth, turret);
                    Vector3 playerPosition = turret.BoardingPosition;
                    playerPosition.z = turret.playerRoot.transform.position.z;
                    turret.playerRoot.transform.position = playerPosition;
                    GameObject originalPlayer = turret.playerRoot;
                    turret.playerRoot = null;
                    Check(turret.CanMount && turret.playerRoot == originalPlayer, "Missing player reference was not recovered");
                    turret.playerRoot.transform.position += Vector3.right * (turret.pool.config.turretBoardingRadius + 5);
                    Check(!turret.TryMount(), "Boarding allowed away from turret");
                    turret.playerRoot.transform.position = playerPosition;
                    float miningZoom = turret.aimCamera.orthographicSize;
                    Check(turret.TryMount() && turret.IsMounted && !turret.playerRoot.activeSelf, "Boarding did not hide player");
                    Check(turret.aimCamera.orthographicSize == turret.pool.config.combatCameraSize, "Combat camera did not zoom");
                    Check(!turret.TryMount(), "Boarding accepted while already mounted");
                    turret.Dismount();
                    Check(turret.aimCamera.orthographicSize == miningZoom, "Combat camera did not restore zoom");
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
                    // Đạn đặc biệt giờ chỉ làm bằng thí nghiệm (Underlab.Lab) => chế nhanh luôn bị chặn.
                    GameEvents.RaiseResourcesDeposited(ResourceType.Magnesium, 2);
                    GameEvents.RaiseResourcesDeposited(ResourceType.Sulfur, 1);
                    GameEvents.RaiseResourcesDeposited(ResourceType.KCl, 1);
                    Check(!turret.Craft(1) && !turret.Craft(2) && !turret.Craft(3), "Special ammo must come from the lab, not quick craft");
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
            Application.runInBackground = previousRunInBackground;
            SessionState.SetBool(Key, false);
            Directory.CreateDirectory("Logs"); File.WriteAllText("Logs/DefenseVerification.txt", message);
            if (success) Debug.Log("[DefenseVerification] " + message); else Debug.LogError("[DefenseVerification] " + message);
            if (batch) { SessionState.SetInt(Key + ".code", success ? 0 : 1); SessionState.SetBool(Key + ".exit", true); }
            EditorApplication.isPlaying = false;
        }
    }
}
