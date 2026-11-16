using UnityEngine;
using UnityEngine.InputSystem;
using Underlab.Core;

namespace Underlab.Mining
{
    /// <summary>
    /// ĐỒNG HỒ WAVE GIẢ — chỉ để test phần đào khi chưa có GameManager (B01) của Dev B.
    /// Phát đúng các event B01 sẽ phát: PhaseChanged, WaveCountdown, WaveWarning, WaveStarted, WaveCleared.
    /// KHÔNG đặt vào scene Game.unity.  Phím: F2 = bắt đầu wave ngay.
    /// </summary>
    public class DebugWaveClock : MonoBehaviour
    {
        [SerializeField] private float miningSeconds = 60f;
        [SerializeField] private float warningAt = 10f;
        [SerializeField] private float defenseSeconds = 12f;

        private float timer;
        private int wave = 1;
        private bool warned;
        private GamePhase phase = GamePhase.Mining;

        private void Start() => EnterMining();

        private void Update()
        {
#if UNITY_EDITOR
            if (Keyboard.current != null && Keyboard.current.f2Key.wasPressedThisFrame && phase == GamePhase.Mining)
                timer = 0.01f;
#endif
            timer -= Time.deltaTime;

            if (phase == GamePhase.Mining)
            {
                GameEvents.RaiseWaveCountdown(Mathf.Max(0f, timer));
                if (!warned && timer <= warningAt)
                {
                    warned = true;
                    GameEvents.RaiseWaveWarning(wave);
                }
                if (timer <= 0f)
                {
                    phase = GamePhase.Defense;
                    timer = defenseSeconds;
                    GameEvents.RaisePhaseChanged(phase);
                    GameEvents.RaiseWaveStarted(wave);
                }
            }
            else if (phase == GamePhase.Defense && timer <= 0f)
            {
                GameEvents.RaiseWaveCleared(wave);
                wave++;
                EnterMining();
            }
        }

        private void EnterMining()
        {
            phase = GamePhase.Mining;
            timer = miningSeconds;
            warned = false;
            GameEvents.RaisePhaseChanged(phase);
        }
    }
}
