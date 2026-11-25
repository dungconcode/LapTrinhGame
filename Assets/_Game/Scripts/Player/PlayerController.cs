using UnityEngine;
using UnityEngine.InputSystem;
using Underlab.Art;
using Underlab.Core;
using Underlab.Mining;

namespace Underlab.Player
{
    /// <summary>
    /// Thợ mỏ: đi trái/phải (A/D, mũi tên), giữ Space để bay bằng jetpack (leo khỏi hố).
    /// Input lấy từ project-wide actions (Assets/InputSystem_Actions): Player/Move, Player/Jump.
    ///
    /// Các hệ thống khác dùng:
    ///   SpeedMultiplier  — Carrier (A04) giảm khi mang nặng, Upgrade tăng
    ///   MoveInput/Facing — Drill (A03) lấy hướng khoan
    ///   AnimLocked       — Drill bật để tự chạy anim khoan
    /// </summary>
    [RequireComponent(typeof(Rigidbody2D), typeof(CapsuleCollider2D))]
    public class PlayerController : MonoBehaviour
    {
        [SerializeField] private PlayerConfig config;
        [SerializeField] private ArtSprite art;

        public const string DefaultWalkAnim = "char_player_walk";

        /// <summary>Hệ số do tải (Carrier đặt).</summary>
        public float SpeedMultiplier { get; set; } = 1f;
        /// <summary>Hệ số do nâng cấp (MiningUpgrades đặt). Tốc độ thật = base × tải × nâng cấp.</summary>
        public float SpeedUpgrade { get; set; } = 1f;
        public float ThrustUpgrade { get; set; } = 1f;
        /// <summary>Anim khi đi bộ — Carrier đổi sang char_player_carry khi mang nặng.</summary>
        public string WalkAnimId { get; set; } = DefaultWalkAnim;
        public float ThrustMultiplier { get; set; } = 1f;
        public Vector2 MoveInput { get; private set; }
        public int Facing { get; private set; } = 1;
        public bool IsGrounded { get; private set; }
        public bool IsThrusting { get; private set; }
        public bool AnimLocked { get; set; }
        public int Depth { get; private set; } = -1;
        public Rigidbody2D Body => body;

        private Rigidbody2D body;
        private CapsuleCollider2D capsule;
        private InputAction moveAction, jumpAction;
        private readonly RaycastHit2D[] hits = new RaycastHit2D[4];
        private ContactFilter2D groundFilter;

        private void Awake()
        {
            body = GetComponent<Rigidbody2D>();
            capsule = GetComponent<CapsuleCollider2D>();
            if (art == null) art = GetComponentInChildren<ArtSprite>();

            body.gravityScale = config.gravityScale;
            body.freezeRotation = true;
            body.interpolation = RigidbodyInterpolation2D.Interpolate;
            body.collisionDetectionMode = CollisionDetectionMode2D.Continuous;

            // Không ma sát => không dính vào tường khi vừa bay vừa giữ phím sang ngang.
            if (capsule.sharedMaterial == null)
                capsule.sharedMaterial = new PhysicsMaterial2D("PlayerNoFriction") { friction = 0f, bounciness = 0f };

            groundFilter = new ContactFilter2D { useTriggers = false };
            groundFilter.SetLayerMask(Physics2D.GetLayerCollisionMask(gameObject.layer));

            moveAction = InputSystem.actions?.FindAction("Player/Move");
            jumpAction = InputSystem.actions?.FindAction("Player/Jump");
            if (moveAction == null || jumpAction == null)
                Debug.LogError("[Player] Không tìm thấy action Player/Move hoặc Player/Jump trong project-wide Input Actions", this);
        }

        private void OnEnable()
        {
            moveAction?.Enable();
            jumpAction?.Enable();
        }

        private void Update()
        {
            MoveInput = moveAction != null ? moveAction.ReadValue<Vector2>() : Vector2.zero;
            IsThrusting = jumpAction != null && jumpAction.IsPressed();
            if (MoveInput.x > 0.1f) Facing = 1;
            else if (MoveInput.x < -0.1f) Facing = -1;

            UpdateAnimation();
            UpdateDepth();
        }

        private void FixedUpdate()
        {
            IsGrounded = capsule.Cast(Vector2.down, groundFilter, hits, config.groundCheckDistance) > 0;

            var v = body.linearVelocity;

            float target = MoveInput.x * config.moveSpeed * SpeedMultiplier * SpeedUpgrade;
            float accel = IsGrounded ? config.groundAccel : config.airAccel;
            v.x = Mathf.MoveTowards(v.x, target, accel * Time.fixedDeltaTime);

            if (IsThrusting)
            {
                // Tải chỉ làm GIẢM tốc độ bay lên tối đa, không bao giờ làm jetpack thua trọng lực.
                // Lực đẩy = bù trọng lực + thrustAccel => luôn bay lên được, kể cả túi đầy.
                float thrust = ThrustMultiplier * ThrustUpgrade;
                float gravity = Mathf.Abs(Physics2D.gravity.y) * body.gravityScale;
                float lift = gravity + config.thrustAccel * Mathf.Max(0.3f, thrust);
                v.y = Mathf.MoveTowards(v.y, config.maxRiseSpeed * thrust, lift * Time.fixedDeltaTime);
            }
            v.y = Mathf.Max(v.y, -config.maxFallSpeed);

            body.linearVelocity = v;
        }

        private void UpdateAnimation()
        {
            if (art == null) return;
            art.SetFlipX(Facing < 0);
            if (AnimLocked) return;

            // Khoan giữ quyền ưu tiên qua AnimLocked; chỉ hiện phản lực khi không khoan.
            if (IsThrusting)
            {
                art.Play("char_player_jetpack");
                return;
            }

            bool walking = IsGrounded && Mathf.Abs(MoveInput.x) > 0.1f;
            art.Play(walking ? WalkAnimId : "char_player_idle");
        }

        private void UpdateDepth()
        {
            int d = TerrainGenerator.DepthOf(transform.position);
            if (d == Depth) return;
            Depth = d;
            GameEvents.RaiseDepthChanged(d);
        }
    }
}
