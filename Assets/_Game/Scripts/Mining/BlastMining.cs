using System.Collections;
using UnityEngine;
using UnityEngine.InputSystem;
using Underlab.Art;
using Underlab.Core;
using Underlab.Player;

namespace Underlab.Mining
{
    /// <summary>
    /// A13 — Blast Mining: bom phá đá.
    ///  - Mỗi lần GameEvents.UpgradePurchased(UpgradeIds.Blast) = +1 bom  (debug F10)
    ///  - Dưới đất bấm C (Player/Crouch): đặt bom dưới chân, nổ sau fuseSeconds
    ///  - Phá mọi ô (trừ bedrock) trong bán kính, quặng vẫn rơi ra, đẩy player ra xa, rung camera
    /// </summary>
    public class BlastMining : MonoBehaviour
    {
        [SerializeField] private PlayerController player;
        [SerializeField] private TerrainGenerator terrain;
        [SerializeField] private CameraFollow cameraFollow;
        [SerializeField, Min(0)] private int charges;
        [SerializeField] private float fuseSeconds = 2f;
        [Tooltip("Bán kính nổ (ô). 1.5 ≈ 3x3, 2.3 ≈ hình tròn 5x5")]
        [SerializeField] private float radius = 2.3f;
        [SerializeField] private float knockback = 8f;

        public int Charges => charges;

        private InputAction placeAction;
        private Collider2D playerCollider;

        private void Awake()
        {
            placeAction = InputSystem.actions?.FindAction("Player/Crouch");
            if (terrain == null) terrain = FindFirstObjectByType<TerrainGenerator>();
            if (player != null) playerCollider = player.GetComponent<Collider2D>();
        }

        private void OnEnable()
        {
            placeAction?.Enable();
            GameEvents.UpgradePurchased += OnUpgrade;
        }

        private void OnDisable() => GameEvents.UpgradePurchased -= OnUpgrade;

        private void OnUpgrade(string id)
        {
            if (id != UpgradeIds.Blast) return;
            charges++;
            FloatingText.Spawn($"+1 BOM (có {charges})", player.transform.position + Vector3.up * 1.4f, new Color(1f, 0.7f, 0.3f));
        }

        private void Update()
        {
#if UNITY_EDITOR
            if (Keyboard.current != null && Keyboard.current.f10Key.wasPressedThisFrame)
                GameEvents.RaiseUpgradePurchased(UpgradeIds.Blast);
#endif
            if (placeAction == null || !placeAction.WasPressedThisFrame() || player.Depth <= 0) return;

            if (charges <= 0)
            {
                FloatingText.Spawn("Hết bom", player.transform.position + Vector3.up * 1.3f, Color.white, size: 0.8f);
                return;
            }
            charges--;
            StartCoroutine(Detonate(player.transform.position + Vector3.up * 0.25f));
        }

        private IEnumerator Detonate(Vector3 pos)
        {
            var bomb = new GameObject("BlastCharge");
            bomb.transform.position = pos;
            var sr = bomb.AddComponent<SpriteRenderer>();
            sr.sortingOrder = 9;
            bomb.AddComponent<ArtSprite>().Play("item_blast_charge");

            // Nhấp nháy nhanh dần
            float t = 0f;
            while (t < fuseSeconds)
            {
                t += Time.deltaTime;
                float speed = Mathf.Lerp(4f, 20f, t / fuseSeconds);
                sr.color = Mathf.Sin(t * speed * Mathf.PI) > 0f ? Color.white : new Color(1f, 0.3f, 0.2f);
                yield return null;
            }
            Destroy(bomb);
            Explode(pos);
        }

        private void Explode(Vector3 pos)
        {
            ArtFx.Spawn("fx_blast", pos, 30);
            if (cameraFollow != null) cameraFollow.Shake(0.4f, 0.5f);

            var center = terrain.WorldToCell(pos);
            int r = Mathf.CeilToInt(radius);
            for (int dx = -r; dx <= r; dx++)
            for (int dy = -r; dy <= r; dy++)
            {
                if (dx * dx + dy * dy > radius * radius) continue;
                var cell = center + new Vector3Int(dx, dy, 0);
                if (!terrain.TryGetCell(cell, out var data) || !data.IsBreakable) continue;
                if (!terrain.Damage(cell, float.MaxValue)) continue;

                var c = terrain.CellCenter(cell);
                if (data.kind == TileKind.Ore)
                    OrePickup.Spawn(data.ore, data.oreAmount, c, playerCollider, 3f, 0.6f);
            }

            // Đẩy player nếu đứng gần
            Vector2 away = (Vector2)(player.transform.position - pos);
            if (away.magnitude < radius + 0.5f)
            {
                var dir = away.sqrMagnitude < 0.01f ? Vector2.up : away.normalized;
                player.Body.linearVelocity = (dir + Vector2.up * 0.5f).normalized * knockback;
            }
        }
    }
}
