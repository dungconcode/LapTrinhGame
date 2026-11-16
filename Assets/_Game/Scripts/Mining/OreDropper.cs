using System;
using UnityEngine;
using UnityEngine.InputSystem;
using Underlab.Art;
using Underlab.Core;
using Underlab.Player;

namespace Underlab.Mining
{
    /// <summary>
    /// Vứt bớt quặng để dọn chỗ.
    ///   Q: đổi loại định vứt (xoay vòng giữa các loại đang có trong túi)
    ///   G: vứt 1 cục loại đang chọn · giữ G: vứt liên tục
    /// Quặng vứt ra không bị hút lại cho tới khi player đi xa (tránh vứt xong hút về ngay).
    /// (Q/G đọc thẳng bàn phím qua Input System để khỏi sửa file InputSystem_Actions dùng chung.)
    /// </summary>
    [RequireComponent(typeof(Carrier), typeof(PlayerController))]
    public class OreDropper : MonoBehaviour
    {
        [SerializeField] private float repeatDelay = 0.35f;
        [SerializeField] private float repeatInterval = 0.12f;
        [SerializeField] private float tossSpeed = 3f;
        [Tooltip("Phải đi xa hơn chừng này (ô) thì quặng đã vứt mới hút lại được")]
        [SerializeField] private float leaveDistance = 2.3f;

        /// <summary>Loại đang chọn để vứt; null nếu túi rỗng.</summary>
        public ResourceType? Selected { get; private set; }
        public event Action<ResourceType?> SelectedChanged;

        private Carrier carrier;
        private PlayerController player;
        private Collider2D playerCollider;
        private float holdTimer;

        private static readonly ResourceType[] Order =
            { ResourceType.Iron, ResourceType.Sulfur, ResourceType.Magnesium, ResourceType.KCl };

        private void Awake()
        {
            carrier = GetComponent<Carrier>();
            player = GetComponent<PlayerController>();
            playerCollider = GetComponent<Collider2D>();
        }

        private void OnEnable() => carrier.Changed += Validate;
        private void OnDisable() => carrier.Changed -= Validate;

        private void Update()
        {
            var k = Keyboard.current;
            if (k == null) return;

            if (k.qKey.wasPressedThisFrame) Cycle();

            if (k.gKey.wasPressedThisFrame)
            {
                DropOne();
                holdTimer = repeatDelay;
            }
            else if (k.gKey.isPressed)
            {
                holdTimer -= Time.deltaTime;
                if (holdTimer <= 0f)
                {
                    DropOne();
                    holdTimer = repeatInterval;
                }
            }
        }

        /// <summary>Chọn loại tiếp theo đang có trong túi.</summary>
        public void Cycle()
        {
            if (carrier.IsEmpty)
            {
                Say("Túi rỗng", Color.white);
                return;
            }
            int start = Selected.HasValue ? Array.IndexOf(Order, Selected.Value) : -1;
            for (int i = 1; i <= Order.Length; i++)
            {
                var t = Order[(start + i + Order.Length) % Order.Length];
                if (carrier.Get(t) <= 0) continue;
                SetSelected(t);
                Say($"Chọn vứt: {CarrierFeedback.DisplayName(t)} ({carrier.Get(t)})", CarrierFeedback.DisplayColor(t));
                return;
            }
        }

        public void DropOne()
        {
            if (!Selected.HasValue || carrier.Get(Selected.Value) <= 0)
            {
                Validate();
                if (!Selected.HasValue) { Say("Túi rỗng", Color.white); return; }
            }

            var t = Selected.Value;
            if (carrier.Remove(t, 1) <= 0) return;

            var pos = transform.position + Vector3.up * 0.5f + Vector3.right * player.Facing * 0.3f;
            var ore = OrePickup.Spawn(t, 1, pos, playerCollider, 0f, 0f);
            ore.BlockUntilLeave(transform, leaveDistance);
            ore.GetComponent<Rigidbody2D>().linearVelocity = new Vector2(player.Facing * tossSpeed, 2f);
            FloatingText.Spawn($"-1 {CarrierFeedback.DisplayName(t)}", transform.position + Vector3.up * 1.1f,
                CarrierFeedback.DisplayColor(t), duration: 0.7f, size: 0.8f);
        }

        /// <summary>Giữ lựa chọn hợp lệ: hết loại đang chọn thì tự nhảy sang loại khác còn trong túi.</summary>
        private void Validate()
        {
            if (Selected.HasValue && carrier.Get(Selected.Value) > 0) return;
            foreach (var t in Order)
            {
                if (carrier.Get(t) > 0) { SetSelected(t); return; }
            }
            SetSelected(null);
        }

        private void SetSelected(ResourceType? t)
        {
            if (Selected == t) return;
            Selected = t;
            SelectedChanged?.Invoke(t);
        }

        private void Say(string text, Color c) =>
            FloatingText.Spawn(text, transform.position + Vector3.up * 1.3f, c, duration: 1f, size: 0.8f);
    }
}
