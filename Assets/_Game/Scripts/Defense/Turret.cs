using Underlab.Core;
using Underlab.Game;
using UnityEngine;
using UnityEngine.InputSystem;

namespace Underlab.Defense
{
    public class Turret : MonoBehaviour
    {
        public Transform barrel, muzzle;
        public Camera aimCamera;
        public CombatPool pool;
        public DefenseShop shop;
        public GameManager game;
        public InputActionAsset inputActions;
        public GameObject playerRoot;
        public bool IsMounted { get; private set; }
        public bool CanMount
        {
            get
            {
                // Scene đã mở trước khi thêm field có thể chưa nhận reference mới.
                if (!playerRoot)
                    foreach (var root in gameObject.scene.GetRootGameObjects())
                        if (root.name == "Player") { playerRoot = root; break; }
                return playerRoot && playerRoot.activeInHierarchy && game.Started && !game.Paused &&
                    (game.Phase == GamePhase.Mining || game.Phase == GamePhase.Defense) && !shop.Open && !Underlab.Lab.LabStation.IsOpen &&
                    Vector2.Distance(playerRoot.transform.position, (Vector2)transform.position + pool.config.turretBoardingOffset) <= pool.config.turretBoardingRadius;
            }
        }
        public AmmoType Selected { get; private set; }
        public readonly int[] Ammunition = new int[4];
        private InputActionAsset controls;
        private InputAction attack;
        private float cooldown;
        private int damageLevel, rotationLevel;
        private bool waitingForRelease;
        private Underlab.Art.ArtSprite barrelArt;
        private void Awake()
        {
            controls = Instantiate(inputActions);
            attack = controls.FindAction("Player/Attack", true);
            // Nòng giật (bld_turret_fire) chạy 1 lần rồi về hình nòng thường. DefenseVisual (-200) đã tạo ArtSprite trước.
            barrelArt = barrel ? barrel.GetComponent<Underlab.Art.ArtSprite>() : null;
            if (barrelArt) barrelArt.OnFinished += id => { if (id == "bld_turret_fire") barrelArt.Play("bld_turret_barrel"); };
        }
        private void OnEnable() { controls?.Enable(); GameEvents.UpgradePurchased += Purchased; GameEvents.PhaseChanged += PhaseChanged; }
        private void OnDisable() { Dismount(); controls?.Disable(); GameEvents.UpgradePurchased -= Purchased; GameEvents.PhaseChanged -= PhaseChanged; }
        private void OnDestroy() { if (controls) Destroy(controls); }
        private void PhaseChanged(GamePhase phase) { if (phase == GamePhase.Victory || phase == GamePhase.GameOver) Dismount(); }
        public bool TryMount()
        {
            if (IsMounted || !CanMount) return false;
            IsMounted = true; waitingForRelease = true;
            var body = playerRoot.GetComponent<Rigidbody2D>();
            if (body) { body.linearVelocity = Vector2.zero; body.angularVelocity = 0; }
            // Tắt cả nhân vật để dừng di chuyển, khoan và vật lý khi đang trong pháo.
            playerRoot.SetActive(false);
            return true;
        }
        public void Dismount()
        {
            if (!IsMounted) return;
            IsMounted = false; waitingForRelease = false;
            if (playerRoot) playerRoot.SetActive(true);
        }
        private void Purchased(string id) { if (id == "turret_damage") damageLevel++; if (id == "turret_rotate") rotationLevel++; }
        public void Select(int index) => Selected = (AmmoType)Mathf.Clamp(index, 0, 3);
        public bool Craft(int index)
        {
            if (!shop.Available || index < 1 || index > 3) return false;
            if (index == (int)AmmoType.Fire) return false; // đạn lửa giờ phải tự làm thí nghiệm (Underlab.Lab.FireExperiment)
            var ammo = pool.config.ammo[index];
            ResourceType resource = index == 1 ? ResourceType.Sulfur : index == 2 ? ResourceType.Magnesium : ResourceType.KCl;
            if (!shop.bank.Spend(resource, ammo.craftCost)) return false;
            Ammunition[index] += ammo.craftYield; return true;
        }
        private void Update()
        {
            if (!game.Started || game.Paused || game.Phase == GamePhase.Victory || game.Phase == GamePhase.GameOver) return;
            if (Underlab.Lab.LabStation.IsOpen) return; // đang làm thí nghiệm: chuột/phím dành cho phòng thí nghiệm
            var keyboard = Keyboard.current;
            if (IsMounted && keyboard != null && keyboard.qKey.wasPressedThisFrame) { Dismount(); return; }
            if (keyboard != null)
            {
                if (keyboard.digit1Key.wasPressedThisFrame) Select(0);
                if (keyboard.digit2Key.wasPressedThisFrame) Select(1);
                if (keyboard.digit3Key.wasPressedThisFrame) Select(2);
                if (keyboard.digit4Key.wasPressedThisFrame) Select(3);
                if (!IsMounted && keyboard.eKey.wasPressedThisFrame && shop.Available) shop.Open = !shop.Open;
            }
            cooldown -= Time.deltaTime;
            if (shop.Open || Mouse.current == null) return;
            float uiScale = Mathf.Min(Screen.width / 1280f, Screen.height / 720f);
            if (!IsMounted)
            {
                if (Mouse.current.position.y.ReadValue() >= 110 * uiScale && Mouse.current.leftButton.wasPressedThisFrame) TryMount();
                return;
            }
            // Cú bấm lên pháo chỉ dùng để nhập; nhả chuột rồi bấm tiếp mới bắn.
            if (waitingForRelease)
            {
                if (!attack.IsPressed()) waitingForRelease = false;
                return;
            }
            if (!aimCamera) return;
            Vector3 pointer = aimCamera.ScreenToWorldPoint(new Vector3(Mouse.current.position.x.ReadValue(), Mouse.current.position.y.ReadValue(), -aimCamera.transform.position.z));
            Vector3 delta = pointer - barrel.position;
            float angle = Mathf.Atan2(delta.y, delta.x) * Mathf.Rad2Deg;
            barrel.rotation = Quaternion.RotateTowards(barrel.rotation, Quaternion.Euler(0, 0, angle),
                pool.config.rotationSpeed * (1 + rotationLevel * pool.config.rotationUpgrade) * Time.deltaTime);
            int index = (int)Selected;
            if (Mouse.current.position.y.ReadValue() < 110 * uiScale) return;
            if (!attack.IsPressed() || cooldown > 0 || (index != 0 && Ammunition[index] <= 0)) return;
            if (index != 0) Ammunition[index]--;
            cooldown = pool.config.fireSeconds;
            if (pool.audioFx) pool.audioFx.Shot();
            Underlab.Art.ArtFx.Spawn("fx_muzzle_flash", muzzle.position, 16, 0.9f, rotationZ: barrel.eulerAngles.z);
            if (barrelArt) barrelArt.Play("bld_turret_fire", loop: false, restart: true);
            pool.Shoot(muzzle.position, barrel.right, pool.config.ammo[index].damage * (1 + damageLevel * pool.config.damageUpgrade), index, false);
        }
    }
}
