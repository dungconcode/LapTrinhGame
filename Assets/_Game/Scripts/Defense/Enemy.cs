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
        private string Prefix => Kind == EnemyKind.Flying ? "enemy_flying" : Kind == EnemyKind.Ranged ? "enemy_ranged" : "enemy_melee";
        public void Initialize(CombatPool owner, EnemyKind kind, float hpScale, float movementScale)
        {
            pool = owner; Kind = kind; stats = pool.config.Stats(kind);
            Maximum = Health = stats.health * hpScale; speedScale = movementScale;
            attackClock = patternClock = chargeUntil = poisonUntil = burnUntil = iceUntil = 0;
            poisonDps = burnDps = 0; slow = 1; pattern = 0;
            art = GetComponent<ArtSprite>();
            if (!statusArt)
            {
                var status = new GameObject("Status", typeof(SpriteRenderer), typeof(ArtSprite));
                status.transform.SetParent(transform); status.transform.localPosition = Vector3.up * 2;
                status.GetComponent<SpriteRenderer>().sortingOrder = 14;
                statusArt = status.GetComponent<ArtSprite>();
            }
            statusArt.gameObject.SetActive(false);
            art.Play(kind == EnemyKind.Boss ? "boss_move" : Prefix + (kind == EnemyKind.Flying ? "_fly" : "_walk"));
        }
        public void Hit(float damage, DefenseConfig.AmmoStats ammo = null, int ammoIndex = 0)
        {
            Health -= damage;
            if (ammo != null)
            {
                if (ammoIndex == 1) { poisonUntil = Time.time + ammo.statusSeconds; poisonDps = ammo.damagePerSecond; }
                if (ammoIndex == 2) { burnUntil = Time.time + ammo.statusSeconds; burnDps = ammo.damagePerSecond; }
                if (ammoIndex == 3) { iceUntil = Time.time + ammo.statusSeconds; slow = ammo.speedMultiplier; }
            }
            if (Health <= 0)
            {
                ArtFx.Spawn("fx_explosion", transform.position);
                if (pool.audioFx) pool.audioFx.Explosion();
                gameObject.SetActive(false);
            }
        }
        private void Update()
        {
            if (!pool.target || pool.target.Current <= 0) return;
            float dot = (Time.time < poisonUntil ? poisonDps : 0) + (Time.time < burnUntil ? burnDps : 0);
            if (dot > 0) { Hit(dot * Time.deltaTime); if (!gameObject.activeSelf) return; }
            float statusSpeed = Time.time < iceUntil ? slow : 1;
            GetComponent<SpriteRenderer>().color = Time.time < iceUntil ? Color.cyan : Time.time < burnUntil ? new Color(1, .5f, .2f) : Time.time < poisonUntil ? Color.green : Color.white;
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
                    art.Play("boss_skill");
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
                art.Play(Kind == EnemyKind.Boss ? "boss_move" : Prefix + (Kind == EnemyKind.Flying ? "_fly" : "_walk"));
            }
            else
            {
                attackClock -= Time.deltaTime * statusSpeed;
                if (attackClock <= 0)
                {
                    attackClock = stats.attackSeconds;
                    art.Play(Kind == EnemyKind.Boss ? "boss_skill" : Prefix + "_attack");
                    if (Kind == EnemyKind.Ranged) pool.Shoot(transform.position + Vector3.up, aim - transform.position - Vector3.up, stats.damage, 0, true);
                    else pool.target.Damage(stats.damage);
                }
            }
        }
    }
}
