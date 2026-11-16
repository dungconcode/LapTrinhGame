using System;
using UnityEngine;
using Underlab.Art;
using Underlab.Mining;

namespace Underlab.Player
{
    /// <summary>
    /// A15 — "Juice" cho thợ mỏ (chỉ hình ảnh, không đổi va chạm):
    ///  - Nhún khi tiếp đất (mạnh theo tốc độ rơi) + bụi
    ///  - Duỗi người khi bắt đầu bay jetpack, rung nhẹ khi đang khoan
    ///  - Rung camera nhẹ mỗi lần vỡ 1 ô đất
    /// Cách làm: tạo object con "Visual" vẽ lại sprite của Player rồi ẩn renderer gốc
    /// => co giãn được hình mà collider giữ nguyên. Không cần sửa prefab/scene.
    /// </summary>
    [RequireComponent(typeof(PlayerController))]
    public class PlayerJuice : MonoBehaviour
    {
        [SerializeField] private float landSquash = 0.28f;
        [SerializeField] private float minLandSpeed = 3f;
        [SerializeField] private float springStiffness = 260f;
        [SerializeField] private float springDamping = 16f;
        [SerializeField] private float drillJitter = 0.03f;
        [SerializeField] private float breakShake = 0.06f;

        /// <summary>Tiếp đất (tốc độ rơi lúc chạm, ô/giây).</summary>
        public event Action<float> Landed;

        private PlayerController player;
        private Drill drill;
        private CameraFollow cam;
        private SpriteRenderer source, visual;
        private Vector2 scale = Vector2.one, scaleVel;
        private bool wasGrounded = true, wasThrusting;
        private float lastFallSpeed;

        private void Awake()
        {
            player = GetComponent<PlayerController>();
            drill = GetComponent<Drill>();
            source = GetComponent<SpriteRenderer>();
            if (Camera.main != null) cam = Camera.main.GetComponent<CameraFollow>();

            if (source != null)
            {
                var go = new GameObject("Visual");
                go.transform.SetParent(transform, false);
                visual = go.AddComponent<SpriteRenderer>();
                visual.sortingLayerID = source.sortingLayerID;
                visual.sortingOrder = source.sortingOrder;
                visual.sharedMaterial = source.sharedMaterial;
                source.enabled = false; // ArtSprite vẫn đổi sprite trên renderer gốc, Visual chép lại mỗi frame
            }
        }

        private void OnEnable()
        {
            if (drill != null) drill.OnCellBroken += OnBroken;
            wasGrounded = true;
        }

        private void OnDisable()
        {
            if (drill != null) drill.OnCellBroken -= OnBroken;
        }

        private void OnBroken(Vector3Int cell, TerrainCell data)
        {
            if (cam != null) cam.Shake(breakShake, 0.1f);
            Kick(new Vector2(0.12f, -0.12f));
        }

        private void FixedUpdate()
        {
            if (!player.IsGrounded) lastFallSpeed = Mathf.Max(0f, -player.Body.linearVelocity.y);
        }

        private void Update()
        {
            // Tiếp đất
            if (player.IsGrounded && !wasGrounded)
            {
                float speed = lastFallSpeed;
                if (speed >= minLandSpeed)
                {
                    float k = Mathf.Clamp01(speed / 12f);
                    Kick(new Vector2(landSquash * k, -landSquash * k));
                    ArtFx.Spawn("fx_block_break", transform.position + Vector3.up * 0.05f, 9, 0.45f + 0.3f * k);
                }
                Landed?.Invoke(speed);
                lastFallSpeed = 0f;
            }
            wasGrounded = player.IsGrounded;

            // Bắt đầu bay
            if (player.IsThrusting && !wasThrusting) Kick(new Vector2(-0.12f, 0.15f));
            wasThrusting = player.IsThrusting;

            // Lò xo đưa scale về (1,1)
            Vector2 force = (Vector2.one - scale) * springStiffness - scaleVel * springDamping;
            scaleVel += force * Time.deltaTime;
            scale += scaleVel * Time.deltaTime;
        }

        private void LateUpdate()
        {
            if (visual == null || source == null) return;
            visual.sprite = source.sprite;
            visual.flipX = source.flipX;
            visual.color = source.color;

            // Scale quanh chân (pivot sprite ở đáy) => nhún không bị lún xuống đất
            visual.transform.localScale = new Vector3(scale.x, scale.y, 1f);
            Vector3 jitter = Vector3.zero;
            if (drill != null && drill.IsDrilling)
                jitter = (Vector3)(UnityEngine.Random.insideUnitCircle * drillJitter);
            visual.transform.localPosition = jitter;
        }

        /// <summary>Đẩy scale lệch đi rồi lò xo tự kéo về (x dương = béo ra, y âm = lùn xuống).</summary>
        public void Kick(Vector2 delta)
        {
            scale += delta;
            scale.x = Mathf.Clamp(scale.x, 0.6f, 1.5f);
            scale.y = Mathf.Clamp(scale.y, 0.6f, 1.5f);
        }
    }
}
