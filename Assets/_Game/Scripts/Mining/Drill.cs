using System;
using UnityEngine;
using Underlab.Art;
using Underlab.Player;

namespace Underlab.Mining
{
    /// <summary>
    /// Khoan: giữ phím hướng vào 1 ô đất để phá nó.
    ///   A/D (đẩy vào tường) = khoan ngang · S/↓ (đang đứng) = khoan xuống · W/↑ = khoan lên trần
    /// Hiện vết nứt (tile_crack) theo HP còn lại, vỡ => fx_block_break + rơi quặng (OrePickup).
    /// Nâng cấp drill (A07): chỉnh DamageMultiplier.
    /// </summary>
    [RequireComponent(typeof(PlayerController))]
    public class Drill : MonoBehaviour
    {
        [SerializeField] private DrillConfig config;
        [SerializeField] private TerrainGenerator terrain;
        [Tooltip("SpriteRenderer + ArtSprite (tile_crack) đặt lên ô đang khoan")]
        [SerializeField] private ArtSprite crackOverlay;

        public float DamageMultiplier { get; set; } = 1f;
        public bool IsDrilling { get; private set; }
        public Vector3Int TargetCell { get; private set; }

        /// <summary>Phát khi khoan vỡ 1 ô (cell, dữ liệu ô trước khi vỡ).</summary>
        public event Action<Vector3Int, TerrainCell> OnCellBroken;

        private PlayerController player;
        private Collider2D playerCollider;
        private ArtSprite playerArt;

        private void Awake()
        {
            player = GetComponent<PlayerController>();
            playerCollider = GetComponent<Collider2D>();
            playerArt = GetComponent<ArtSprite>();
            if (terrain == null) terrain = FindFirstObjectByType<TerrainGenerator>();
            ShowCrack(false);
        }

        private void Update()
        {
            TerrainCell data = default;
            bool drilling = TryPickTarget(out var cell) && terrain.TryGetCell(cell, out data) && data.IsBreakable;

            if (drilling)
            {
                if (cell != TargetCell) TargetCell = cell;
                bool broke = terrain.Damage(cell, config.damagePerSecond * DamageMultiplier * Time.deltaTime);
                if (broke) Break(cell, data);
                else UpdateCrack(cell);
            }
            else ShowCrack(false);

            SetDrilling(drilling);
        }

        /// <summary>Chọn ô mục tiêu theo phím hướng đang giữ. False nếu không khoan.</summary>
        private bool TryPickTarget(out Vector3Int cell)
        {
            cell = default;
            if (terrain == null) return false;

            var input = player.MoveInput;
            float t = config.inputThreshold;
            Vector3 feet = transform.position;
            Vector3 body = feet + Vector3.up * 0.4f;

            if (input.y < -t && player.IsGrounded)
            {
                cell = terrain.WorldToCell(feet + Vector3.down * 0.1f);
                return true;
            }
            if (input.y > t && config.allowDrillUp)
            {
                cell = terrain.WorldToCell(feet + Vector3.up * 0.95f);
                return true;
            }
            if (Mathf.Abs(input.x) > t)
            {
                // Ô ngay cạnh thân, theo hướng đang giữ. Chỉ khoan khi thật sự bị chặn.
                float half = playerCollider != null ? playerCollider.bounds.extents.x : 0.3f;
                cell = terrain.WorldToCell(body + Vector3.right * Mathf.Sign(input.x) * (half + 0.1f));
                return terrain.IsSolid(cell);
            }
            return false;
        }

        private void Break(Vector3Int cell, TerrainCell data)
        {
            ShowCrack(false);
            var center = terrain.CellCenter(cell);
            ArtFx.Spawn("fx_block_break", center, 20);

            if (data.kind == TileKind.Ore)
                OrePickup.Spawn(data.ore, data.oreAmount, center, playerCollider, config.dropPopSpeed, config.dropPickupDelay);

            OnCellBroken?.Invoke(cell, data);
        }

        private void UpdateCrack(Vector3Int cell)
        {
            if (crackOverlay == null) return;
            ShowCrack(true);
            crackOverlay.transform.position = terrain.CellCenter(cell);
            int frames = Mathf.Max(1, crackOverlay.FrameCount);
            float damaged = 1f - terrain.HpRatio(cell);
            crackOverlay.SetFrame(Mathf.Min(frames - 1, Mathf.FloorToInt(damaged * frames)));
        }

        private void ShowCrack(bool show)
        {
            if (crackOverlay != null && crackOverlay.gameObject.activeSelf != show)
                crackOverlay.gameObject.SetActive(show);
        }

        private void SetDrilling(bool drilling)
        {
            if (drilling == IsDrilling) return;
            IsDrilling = drilling;
            player.AnimLocked = drilling;
            if (drilling && playerArt != null) playerArt.Play("char_player_drill");
        }
    }
}
