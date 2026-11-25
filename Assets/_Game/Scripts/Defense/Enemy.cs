using Underlab.Art;
using UnityEngine;

namespace Underlab.Defense
{
    public class Enemy : MonoBehaviour
    {
        public EnemyKind Kind { get; private set; }
        public float Health { get; private set; }
        public float Maximum { get; private set; }
        private CombatPool pool;
        private DefenseConfig.EnemyStats stats;
        private ArtSprite art;
        private ArtSprite statusArt;
        private float speedScale, attackClock, patternClock, chargeUntil;
        private float poisonUntil, burnUntil, iceUntil, poisonDps, burnDps, slow = 1;
        private int pattern;
        private float hurtUntil, flashUntil;
        private const float HurtSeconds = 0.2f;   // hiện anim bị thương bao lâu (không chặn di chuyển)
        private const float CorpseLinger = 0.8f;  // xác nằm lại rồi mờ dần
        private string Prefix => Kind == EnemyKind.Flying ? "enemy_flying" : Kind == EnemyKind.Ranged ? "enemy_ranged" : "enemy_melee";
        private string MoveAnim => Kind == EnemyKind.Boss ? "boss_move" : Prefix + (Kind == EnemyKind.Flying ? "_fly" : "_walk");
        private bool Hurting => Time.time < hurtUntil;
        public void Initialize(CombatPool owner, EnemyKind kind, float hpScale, float movementScale)
        {
            pool = owner; Kind = kind; stats = pool.config.Stats(kind);
            Maximum = Health = stats.health * hpScale; speedScale = movementScale;
            attackClock = patternClock = chargeUntil = poisonUntil = burnUntil = iceUntil = 0;
            poisonDps = burnDps = 0; slow = 1; pattern = 0; hurtUntil = flashUntil = 0;
            art = GetComponent<ArtSprite>();
            if (!statusArt)
            {
                var status = new GameObject("Status", typeof(SpriteRenderer), typeof(ArtSprite));
                status.transform.SetParent(transform); status.transform.localPosition = Vector3.up * 2;
                status.GetComponent<SpriteRenderer>().sortingOrder = 14;
                statusArt = status.GetComponent<ArtSprite>();
            }
            statusArt.gameObject.SetActive(false);
            art.Play(MoveAnim);
        }
        public void Hit(float damage, DefenseConfig.AmmoStats ammo = null, int ammoIndex = 0)
        {
            Health -= damage;
            if (ammo != null)
            {
                if (ammoIndex == 1) { poisonUntil = Time.time + ammo.statusSeconds; poisonDps = ammo.damagePerSecond; }
                if (ammoIndex == 2) { burnUntil = Time.time + ammo.statusSeconds; burnDps = ammo.damagePerSecond; }
                if (ammoIndex == 3) { iceUntil = Time.time + ammo.statusSeconds; slow = ammo.speedMultiplier; }
                // Trúng đạn (không phải sát thương độc/cháy theo thời gian) => anim bị thương / chớp đỏ
                flashUntil = Time.time + 0.1f;
                if (Kind != EnemyKind.Boss && Health > 0)
                {
                    hurtUntil = Time.time + HurtSeconds;
                    art.Play(Prefix + "_hurt", loop: false, restart: true);
                }
            }
            if (Health <= 0) Die();
        }
        private void Die()
        {
            // Xác chạy anim chết ở object riêng => quái thật tắt ngay (wave/pool đếm đúng như cũ).
            bool flip = GetComponent<SpriteRenderer>().flipX;
            if (Kind == EnemyKind.Boss)
            {
                ArtFx.Spawn("boss_death", transform.position, 11, 1f, flip, CorpseLinger * 2f);
                ArtFx.Spawn("fx_explosion", transform.position + Vector3.up * 1.5f, 30, 2.5f);
            }
            else
                ArtFx.Spawn(Prefix + "_death", transform.position, 11, 1f, flip, CorpseLinger);
            if (pool.audioFx) pool.audioFx.Explosion();
            statusArt.gameObject.SetActive(false);
            gameObject.SetActive(false);
        }
        private void Update()
        {
            if (!pool.target || pool.target.Current <= 0) return;
            float dot = (Time.time < poisonUntil ? poisonDps : 0) + (Time.time < burnUntil ? burnDps : 0);
            if (dot > 0) { Hit(dot * Time.deltaTime); if (!gameObject.activeSelf) return; }
            float statusSpeed = Time.time < iceUntil ? slow : 1;
            GetComponent<SpriteRenderer>().color = Time.time < flashUntil ? new Color(1f, .45f, .45f) :
                Time.time < iceUntil ? Color.cyan : Time.time < burnUntil ? new Color(1, .5f, .2f) : Time.time < poisonUntil ? Color.green : Color.white;
            string statusId = Time.time < iceUntil ? "fx_status_frozen" : Time.time < burnUntil ? "fx_status_burn" : Time.time < poisonUntil ? "fx_status_poison" : null;
            statusArt.gameObject.SetActive(statusId != null);
            if (statusId != null) statusArt.Play(statusId);
            Vector3 aim = pool.target.transform.position + Vector3.up;
            Vector3 delta = aim - transform.position;
            art.SetFlipX(delta.x > 0);
            if (Kind == EnemyKind.Boss)
            {
                patternClock += Time.deltaTime;
                if (patternClock >= pool.config.bossPatternSeconds)
                {
                    patternClock = 0; pattern = (pattern + 1) % 3;
                    art.Play("boss_skill", loop: false, restart: true);
                    if (pattern == 0) chargeUntil = Time.time + stats.attackSeconds;
                    if (pattern == 1) pool.Shoot(transform.position + Vector3.up, aim - transform.position - Vector3.up, stats.damage, -1, true);
                    if (pattern == 2)
                        for (int i = 0; i < pool.config.bossSummonCount; i++)
                            pool.Spawn(EnemyKind.Melee, transform.position + Vector3.right * i);
                }
            }
            float distance = Kind == EnemyKind.Flying ? delta.magnitude : Mathf.Abs(delta.x);
            if (distance > stats.range)
            {
                Vector3 direction = Kind == EnemyKind.Flying ? delta.normalized : Vector3.right * Mathf.Sign(delta.x);
                transform.position += direction * (stats.speed * speedScale * statusSpeed * Time.deltaTime *
                    (Time.time < chargeUntil ? pool.config.bossChargeMultiplier : 1));
                if (!Hurting && !(Kind == EnemyKind.Boss && art.CurrentId == "boss_skill" && art.IsPlaying))
                    art.Play(MoveAnim);
            }
            else
            {
                // Bị thương xong khi đang đứng đánh => về tư thế đánh (đứng yên frame đầu) thay vì kẹt ở frame bị thương
                if (Kind != EnemyKind.Boss && !Hurting && art.CurrentId == Prefix + "_hurt")
                {
                    art.Play(Prefix + "_attack", loop: false, restart: true);
                    art.SetFrame(0);
                }
                attackClock -= Time.deltaTime * statusSpeed;
                if (attackClock <= 0)
                {
                    attackClock = stats.attackSeconds;
                    art.Play(Kind == EnemyKind.Boss ? "boss_skill" : Prefix + "_attack", loop: false, restart: true);
                    if (Kind == EnemyKind.Ranged) pool.Shoot(transform.position + Vector3.up, aim - transform.position - Vector3.up, stats.damage, 0, true);
                    else pool.target.DamageFromEnemy(stats.damage,
                        Kind == EnemyKind.Flying ? transform.position : transform.position + Vector3.up * .35f);
                }
            }
        }
    }
}
