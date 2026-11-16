using Underlab.Core;
using Underlab.Defense;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.SceneManagement;

namespace Underlab.Game
{
    public class GameManager : MonoBehaviour
    {
        public WaveConfig config;
        public WaveSpawner spawner;
        public BaseHealth baseHealth;
        public GamePhase Phase { get; private set; }
        public int Wave { get; private set; }
        public float Remaining { get; private set; }
        public bool Started { get; private set; }
        public bool Paused { get; private set; }
        private bool warned;
        private void OnEnable() => GameEvents.BaseHpChanged += OnHealth;
        private void OnDisable() { GameEvents.BaseHpChanged -= OnHealth; Time.timeScale = 1; }
        private void Start() { if (!Started) Time.timeScale = 0; }
        public void StartRun() { if (Started) return; Time.timeScale = 1; Started = true; Wave = 0; Mining(); }
        private void Mining()
        {
            Remaining = config.waves[Wave].miningSeconds; warned = false;
            SetPhase(GamePhase.Mining); GameEvents.RaiseWaveCountdown(Remaining);
        }
        public void BeginWave()
        {
            if (!Started || Phase != GamePhase.Mining || Paused) return;
            Remaining = 0; GameEvents.RaiseWaveCountdown(0);
            SetPhase(GamePhase.Defense); GameEvents.RaiseWaveStarted(Wave + 1); spawner.Begin(Wave);
        }
        private void Update()
        {
            if (Keyboard.current != null && Keyboard.current.escapeKey.wasPressedThisFrame && Started && Phase < GamePhase.Victory) TogglePause();
            if (!Started || Paused) return;
            if (Phase == GamePhase.Mining)
            {
                Remaining = Mathf.Max(0, Remaining - Time.deltaTime); GameEvents.RaiseWaveCountdown(Remaining);
                if (!warned && Remaining <= config.warningSeconds) { warned = true; GameEvents.RaiseWaveWarning(Wave + 1); }
                if (Remaining <= 0) BeginWave();
            }
            else if (Phase == GamePhase.Defense && !spawner.Spawning && spawner.pool.Alive == 0)
            {
                GameEvents.RaiseWaveCleared(Wave + 1);
                if (++Wave >= config.waves.Length) Finish(GamePhase.Victory); else Mining();
            }
#if UNITY_EDITOR
            var k = Keyboard.current;
            if (k == null) return;
            if (k.f1Key.wasPressedThisFrame) foreach (ResourceType t in System.Enum.GetValues(typeof(ResourceType))) GameEvents.RaiseResourcesDeposited(t, 10);
            if (k.f2Key.wasPressedThisFrame) BeginWave();
            if (k.f3Key.wasPressedThisFrame) baseHealth.Restore();
            if (k.f4Key.wasPressedThisFrame && Phase < GamePhase.Victory) { spawner.Stop(); Wave = config.waves.Length - 1; Mining(); BeginWave(); }
#endif
        }
        private void OnHealth(int hp, int max) { if (Started && hp <= 0 && (Phase == GamePhase.Mining || Phase == GamePhase.Defense)) Finish(GamePhase.GameOver); }
        private void Finish(GamePhase result) { spawner.Stop(); SetPhase(result); Time.timeScale = 0; }
        private void SetPhase(GamePhase phase) { Phase = phase; GameEvents.RaisePhaseChanged(phase); }
        public void TogglePause() { Paused = !Paused; Time.timeScale = Paused ? 0 : 1; AudioListener.pause = Paused; }
        public void Restart() { Time.timeScale = 1; SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex); }
    }
}
