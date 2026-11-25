using Underlab.Art;
using UnityEngine;

namespace Underlab.Defense
{
    public class Projectile : MonoBehaviour
    {
        private CombatPool pool;
        private Vector3 velocity;
        private float damage, expires;
        private int ammo;
        private bool hostile;
        // Hiệu ứng khi trúng, theo chỉ số đạn (0 thường, 1 axit, 2 lửa, 3 băng)
        private static readonly string[] HitFx = { "fx_hit_normal", "fx_hit_acid", "fx_hit_fire", "fx_hit_ice" };
        public void Initialize(CombatPool owner, Vector3 position, Vector3 direction, float hitDamage, int ammoIndex, bool enemy)
        {
            pool = owner; transform.position = position; velocity = direction.normalized * owner.config.projectileSpeed;
            damage = hitDamage; ammo = ammoIndex; hostile = enemy;
            expires = Time.time + owner.config.projectileLifetime;
            transform.rotation = Quaternion.Euler(0, 0, Mathf.Atan2(direction.y, direction.x) * Mathf.Rad2Deg);
            GetComponent<ArtSprite>().Play(hostile ? (ammoIndex < 0 ? "boss_projectile" : "proj_enemy") : pool.config.ammo[ammo].artId);
        }
        private static float SegmentDistance(Vector3 a, Vector3 b, Vector3 point)
        {
            Vector3 delta = b - a;
            return Vector3.Distance(a + delta * Mathf.Clamp01(Vector3.Dot(point - a, delta) / Mathf.Max(delta.sqrMagnitude, .00001f)), point);
        }
        private void Update()
        {
            Vector3 from = transform.position, to = from + velocity * Time.deltaTime;
            transform.position = to;
            if (hostile)
            {
                if (pool.target.TryTraceHit(from, to, out var contact))
                {
                    pool.target.DamageAtGlass(Mathf.CeilToInt(damage), contact);
                    // axit của quái bắn xa / mảnh pha lê của boss văng vào base
                    if (ammo < 0) ArtFx.Spawn("fx_explosion", contact, 16, 1.2f);
                    else ArtFx.Spawn("fx_hit_acid", contact, 16, 1f);
                    gameObject.SetActive(false);
                }
            }
            else
            {
                // Kiểm tra cả đoạn đường để đạn nhanh không xuyên qua quái.
                Enemy nearest = null; float along = float.MaxValue;
                foreach (var e in pool.Enemies)
                {
                    if (!e.gameObject.activeSelf) continue;
                    Vector3 center = e.transform.position + (e.Kind == EnemyKind.Flying ? Vector3.zero : Vector3.up);
                    if (SegmentDistance(from, to, center) > pool.config.hitRadius * (e.Kind == EnemyKind.Boss ? 3 : 1)) continue;
                    float d = (center - from).sqrMagnitude;
                    if (d < along) { nearest = e; along = d; }
                }
                if (nearest)
                {
                    ArtFx.Spawn(HitFx[Mathf.Clamp(ammo, 0, HitFx.Length - 1)], to, 16, ammo == 2 ? 1.2f : 1f);
                    nearest.Hit(damage, pool.config.ammo[ammo], ammo);
                    gameObject.SetActive(false);
                }
            }
            if (Time.time >= expires) gameObject.SetActive(false);
        }
    }
}
