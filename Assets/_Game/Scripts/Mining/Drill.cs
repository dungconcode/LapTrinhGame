using System;
using UnityEngine;
using Underlab.Art;
using Underlab.Player;

namespace Underlab.Mining
{
    /// <summary>
    /// Khoan: giữ phím hướng vào 1 ô đất để phá nó.
    ///   A/D (đẩy vào tường) = khoan ngang · S/↓ (đang đứng) = khoan xuống · Space (bay sát trần) = khoan lên
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

        private void OnDisable()
        {
            ShowCrack(false);
            SetDrilling(false, null);
        }

        private void Update()
        {
            TerrainCell data = default;
            bool drilling = TryPickTarget(out var cell, out var animationId) && terrain.TryGetCell(cell, out data) && data.IsBreakable;

            if (drilling)
            {
                if (cell != TargetCell) TargetCell = cell;
                SparkTick(cell);
                bool broke = terrain.Damage(cell, config.damagePerSecond * DamageMultiplier * Time.deltaTime);
                if (broke) Break(cell, data);
                else UpdateCrack(cell);
            }
            else ShowCrack(false);

            SetDrilling(drilling, animationId);
        }

        /// <summary>Chọn ô mục tiêu theo phím hướng đang giữ. False nếu không khoan.</summary>
        private bool TryPickTarget(out Vector3Int cell, out string animationId)
        {
            cell = default;
            animationId = "char_player_drill";
            if (terrain == null) return false;

            var input = player.MoveInput;
            float t = config.inputThreshold;
            Vector3 feet = transform.position;
            Vector3 body = feet + Vector3.up * 0.4f;

            if (input.y < -t && player.IsGrounded)
            {
                animationId = "char_player_drill_down";
                cell = terrain.WorldToCell(feet + Vector3.down * 0.1f);
                return true;
            }
            if (player.IsThrusting && config.allowDrillUp)
            {
                // Dò ngay trên đỉnh collider để bắt được ô trần khi bay sát vào.
                var bounds = playerCollider.bounds;
                cell = terrain.WorldToCell(new Vector3(bounds.center.x, bounds.max.y + 0.1f, feet.z));
                if (terrain.TryGetCell(cell, out var ceiling) && ceiling.IsBreakable)
                {
                    animationId = "char_player_drill_up";
                    return true;
                }
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

        private float nextSpark;

        /// <summary>Tia lửa ở chỗ mũi khoan chạm đất, mỗi ~0.18s, xoay theo hướng khoan.</summary>
        private void SparkTick(Vector3Int cell)
        {
            if (Time.time < nextSpark) return;
            nextSpark = Time.time + 0.18f;
            Vector3 body = transform.position + Vector3.up * 0.4f;
            Vector3 center = terrain.CellCenter(cell);
            Vector3 dir = center - body;
            Vector3 contact = Vector3.Lerp(body, center, 0.55f);
            float angle = Mathf.Abs(dir.x) >= Mathf.Abs(dir.y) ? 0f : (dir.y > 0f ? 90f : -90f);
            ArtFx.Spawn("fx_drill_spark", contact, 21, 0.8f, flipX: angle == 0f && dir.x < 0f, rotationZ: angle);
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

        private void SetDrilling(bool drilling, string animationId)
        {
            if (drilling != IsDrilling)
            {
                IsDrilling = drilling;
                player.AnimLocked = drilling;
            }
            // Kiểm tra cả khi đang khoan để đổi anim ngay khi đổi hướng; Play giữ frame nếu id không đổi.
            if (drilling && playerArt != null) playerArt.Play(animationId);
        }
    }
}
