using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Underlab.Art;
using Underlab.Core;

namespace Underlab.Mining
{
    /// <summary>
    /// Vùng gửi quặng ở base (gắn lên base, cần Collider2D isTrigger).
    /// Player mang quặng đi vào => tự đổ hết vào kho:
    ///   GameEvents.RaiseResourcesDeposited(loại, số) cho từng loại  (ResourceBank của Dev B nghe event này)
    ///   GameEvents.RaisePlayerAtBaseChanged(true/false) khi vào/ra
    /// </summary>
    [RequireComponent(typeof(Collider2D))]
    public class DepositZone : MonoBehaviour
    {
        [Tooltip("Khoảng cách giữa các dòng chữ +N khi đổ nhiều loại quặng")]
        [SerializeField] private float stagger = 0.15f;
        [Tooltip("Chữ hiện ở độ cao này so với chân player")]
        [SerializeField] private Vector3 textOffset = new Vector3(0f, 1.3f, 0f);

        public bool PlayerInside { get; private set; }

        private Carrier carrier;
        private bool depositing;

        private void Reset() => GetComponent<Collider2D>().isTrigger = true;

        private void OnTriggerEnter2D(Collider2D other)
        {
            var c = FindCarrier(other);
            if (c == null) return;
            carrier = c;
            if (!PlayerInside)
            {
                PlayerInside = true;
                GameEvents.RaisePlayerAtBaseChanged(true);
            }
            TryDeposit();
        }

        // Đứng trong base mà nhặt thêm quặng (vd quặng lăn tới) thì vẫn gửi tiếp.
        private void OnTriggerStay2D(Collider2D other)
        {
            if (PlayerInside && carrier != null && !carrier.IsEmpty) TryDeposit();
        }

        private void OnTriggerExit2D(Collider2D other)
        {
            if (FindCarrier(other) == null || !PlayerInside) return;
            PlayerInside = false;
            GameEvents.RaisePlayerAtBaseChanged(false);
        }

        private void TryDeposit()
        {
            if (depositing || carrier == null || carrier.IsEmpty) return;
            StartCoroutine(Deposit(carrier.TakeAll()));
        }

        private IEnumerator Deposit(Dictionary<ResourceType, int> items)
        {
            depositing = true;
            ArtFx.Spawn("fx_deposit", carrier.transform.position + Vector3.up * 0.4f, 25);

            int line = 0;
            foreach (var kv in items)
            {
                if (kv.Value <= 0) continue;
                GameEvents.RaiseResourcesDeposited(kv.Key, kv.Value);
                FloatingText.Spawn($"+{kv.Value} {CarrierFeedback.DisplayName(kv.Key)} vào kho",
                    carrier.transform.position + textOffset + Vector3.up * (0.35f * line),
                    CarrierFeedback.DisplayColor(kv.Key), duration: 1.3f, riseSpeed: 0.8f);
                line++;
                yield return new WaitForSeconds(stagger);
            }
            depositing = false;
        }

        private static Carrier FindCarrier(Collider2D other)
        {
            var rb = other.attachedRigidbody;
            return rb != null ? rb.GetComponent<Carrier>() : other.GetComponent<Carrier>();
        }
    }
}
