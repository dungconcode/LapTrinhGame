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
        public AmmoType Selected { get; private set; }
        public readonly int[] Ammunition = new int[4];
        private InputActionAsset controls;
        private InputAction attack;
        private float cooldown;
        private int damageLevel, rotationLevel;
        private void Awake()
        {
            controls = Instantiate(inputActions);
            attack = controls.FindAction("Player/Attack", true);
        }
        private void OnEnable() { controls?.Enable(); GameEvents.UpgradePurchased += Purchased; }
        private void OnDisable() { controls?.Disable(); GameEvents.UpgradePurchased -= Purchased; }
        private void OnDestroy() { if (controls) Destroy(controls); }
        private void Purchased(string id) { if (id == "turret_damage") damageLevel++; if (id == "turret_rotate") rotationLevel++; }
        public void Select(int index) => Selected = (AmmoType)Mathf.Clamp(index, 0, 3);
        public bool Craft(int index)
        {
            if (!shop.Available || index < 1 || index > 3) return false;
            var ammo = pool.config.ammo[index];
            ResourceType resource = index == 1 ? ResourceType.Sulfur : index == 2 ? ResourceType.Magnesium : ResourceType.KCl;
            if (!shop.bank.Spend(resource, ammo.craftCost)) return false;
            Ammunition[index] += ammo.craftYield; return true;
        }
        private void Update()
        {
            if (!game.Started || game.Paused || game.Phase == GamePhase.Victory || game.Phase == GamePhase.GameOver) return;
            var keyboard = Keyboard.current;
            if (keyboard != null)
            {
                if (keyboard.digit1Key.wasPressedThisFrame) Select(0);
                if (keyboard.digit2Key.wasPressedThisFrame) Select(1);
                if (keyboard.digit3Key.wasPressedThisFrame) Select(2);
                if (keyboard.digit4Key.wasPressedThisFrame) Select(3);
                if (keyboard.eKey.wasPressedThisFrame && shop.Available) shop.Open = !shop.Open;
            }
            cooldown -= Time.deltaTime;
            if (shop.Open || !shop.AtBase || Mouse.current == null) return;
            Vector3 pointer = aimCamera.ScreenToWorldPoint(new Vector3(Mouse.current.position.x.ReadValue(), Mouse.current.position.y.ReadValue(), -aimCamera.transform.position.z));
            Vector3 delta = pointer - barrel.position;
            float angle = Mathf.Atan2(delta.y, delta.x) * Mathf.Rad2Deg;
            barrel.rotation = Quaternion.RotateTowards(barrel.rotation, Quaternion.Euler(0, 0, angle),
                pool.config.rotationSpeed * (1 + rotationLevel * pool.config.rotationUpgrade) * Time.deltaTime);
            int index = (int)Selected;
            float uiScale = Mathf.Min(Screen.width / 1280f, Screen.height / 720f);
            if (Mouse.current.position.y.ReadValue() < 110 * uiScale) return;
            if (!attack.IsPressed() || cooldown > 0 || (index != 0 && Ammunition[index] <= 0)) return;
            if (index != 0) Ammunition[index]--;
            cooldown = pool.config.fireSeconds;
            if (pool.audioFx) pool.audioFx.Shot();
            pool.Shoot(muzzle.position, barrel.right, pool.config.ammo[index].damage * (1 + damageLevel * pool.config.damageUpgrade), index, false);
        }
    }
}
