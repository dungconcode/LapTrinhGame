using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
using Underlab.Art;
using Underlab.Core;
using Underlab.Player;

namespace Underlab.Mining
{
    /// <summary>
    /// A12 — Thang máy chở quặng.
    ///  - Mở khoá: GameEvents.UpgradePurchased(UpgradeIds.Lift)  (debug F9)
    ///  - Dưới đất (độ sâu ≥ minDepth) bấm E (Player/Interact): đặt trạm tại chỗ đứng (đặt lại = dời trạm)
    ///  - Đứng cạnh trạm bấm E: đổ hết túi vào xe goòng, xe chạy lên mặt đất rồi gửi vào kho
    ///    (phát ResourcesDeposited y như về base)
    /// </summary>
    public class LiftSystem : MonoBehaviour
    {
        [SerializeField] private PlayerController player;
        [SerializeField] private Carrier carrier;
        [SerializeField] private bool unlocked;
        [SerializeField, Min(1)] private int minDepth = 3;
        [Tooltip("Tốc độ xe goòng (ô/giây)")]
        [SerializeField] private float cartSpeed = 6f;
        [SerializeField] private float interactRange = 1.2f;

        public bool Unlocked => unlocked;
        public bool HasStation => station != null;

        private InputAction interact;
        private GameObject station;
        private SpriteRenderer shaft;
        private TextMesh hint;

        private void Awake()
        {
            interact = InputSystem.actions?.FindAction("Player/Interact");
        }

        private void OnEnable()
        {
            interact?.Enable();
            GameEvents.UpgradePurchased += OnUpgrade;
        }

        private void OnDisable() => GameEvents.UpgradePurchased -= OnUpgrade;

        private void OnUpgrade(string id)
        {
            if (id != UpgradeIds.Lift || unlocked) return;
            unlocked = true;
            FloatingText.Spawn("MỞ KHOÁ THANG MÁY! (E để đặt)", player.transform.position + Vector3.up * 1.4f,
                new Color(0.5f, 1f, 1f), duration: 2f);
        }

        private void Update()
        {
#if UNITY_EDITOR
            if (Keyboard.current != null && Keyboard.current.f9Key.wasPressedThisFrame)
                GameEvents.RaiseUpgradePurchased(UpgradeIds.Lift);
#endif
            bool near = station != null && Vector2.Distance(player.transform.position, station.transform.position) <= interactRange;
            if (hint != null) hint.gameObject.SetActive(near);

            if (interact == null || !interact.WasPressedThisFrame()) return;

            if (!unlocked)
            {
                if (player.Depth >= minDepth) Say("Chưa mở khoá thang máy", new Color(1f, 0.6f, 0.4f));
                return;
            }

            if (near)
            {
                if (carrier.IsEmpty) Say("Túi rỗng", Color.white);
                else StartCoroutine(SendCart(carrier.TakeAll()));
            }
            else if (player.Depth >= minDepth && player.IsGrounded)
            {
                PlaceStation(player.transform.position);
            }
            else if (player.Depth > 0 && player.Depth < minDepth) // trên mặt đất thì im: E còn dùng cho shop ở base
            {
                Say($"Đặt thang máy ở độ sâu ≥ {minDepth}", Color.white);
            }
        }

        private void PlaceStation(Vector3 feet)
        {
            var pos = new Vector3(Mathf.Floor(feet.x) + 0.5f, Mathf.Round(feet.y), 0f);
            if (station == null)
            {
                station = new GameObject("LiftStation");
                var sr = station.AddComponent<SpriteRenderer>();
                sr.sortingOrder = 3;
                station.AddComponent<ArtSprite>().Play("bld_lift_cart");

                var shaftGo = new GameObject("LiftShaft");
                shaftGo.transform.SetParent(station.transform, false);
                shaft = shaftGo.AddComponent<SpriteRenderer>();
                shaft.sortingOrder = 1;
                shaft.sprite = ArtDatabase.GetSprite("bld_lift");
                shaft.drawMode = SpriteDrawMode.Tiled;

                hint = FloatingText.CreateLabel("E: gửi quặng lên", Vector3.zero, new Color(0.6f, 1f, 1f), 0.6f);
                hint.transform.SetParent(station.transform, false);
                hint.transform.localPosition = new Vector3(0f, 1.6f, 0f);
                hint.gameObject.SetActive(false);
            }
            station.transform.position = pos;
            if (shaft != null) shaft.size = new Vector2(1f, Mathf.Max(1f, -pos.y)); // pivot đáy => mọc lên tới mặt đất
            Say("Đã đặt thang máy", new Color(0.6f, 1f, 1f));
        }

        private IEnumerator SendCart(Dictionary<ResourceType, int> load)
        {
            var cart = new GameObject("LiftCart");
            cart.transform.position = station.transform.position;
            var sr = cart.AddComponent<SpriteRenderer>();
            sr.sortingOrder = 4;
            cart.AddComponent<ArtSprite>().Play("bld_lift_cart");

            while (cart.transform.position.y < 0f)
            {
                cart.transform.position += Vector3.up * cartSpeed * Time.deltaTime;
                yield return null;
            }

            var top = new Vector3(cart.transform.position.x, 0.5f, 0f);
            ArtFx.Spawn("fx_deposit", top, 25);
            int line = 0;
            foreach (var kv in load)
            {
                if (kv.Value <= 0) continue;
                GameEvents.RaiseResourcesDeposited(kv.Key, kv.Value);
                FloatingText.Spawn($"+{kv.Value} {CarrierFeedback.DisplayName(kv.Key)} (thang máy)",
                    top + Vector3.up * (1f + 0.35f * line), CarrierFeedback.DisplayColor(kv.Key), duration: 1.4f, riseSpeed: 0.8f);
                line++;
            }
            Destroy(cart);
        }

        private void Say(string text, Color color) =>
            FloatingText.Spawn(text, player.transform.position + Vector3.up * 1.3f, color, duration: 1.2f, size: 0.8f);
    }
}
