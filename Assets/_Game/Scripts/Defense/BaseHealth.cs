using Underlab.Art;
using Underlab.Core;
using UnityEngine;

namespace Underlab.Defense
{
    public class BaseHealth : MonoBehaviour
    {
        public DefenseConfig config;
        public ArtSprite art;
        public int Current { get; private set; }
        public int Maximum { get; private set; }
        private DomeVisual dome;
        private void Awake()
        {
            dome = GetComponent<DomeVisual>();
            Maximum = config.baseHealth;
            Current = Maximum;
        }
        private void Start() { if (!art) art = GetComponent<ArtSprite>(); Publish(); }
        public void Damage(int damage) => ApplyDamage(damage);

        public void DamageFromEnemy(int damage, Vector3 source)
        {
            if (dome) DamageAtGlass(damage, dome.GlassContact(source));
            else ApplyDamage(damage);
        }

        public bool TryTraceHit(Vector3 from, Vector3 to, out Vector3 contact)
        {
            if (dome) return dome.TryTraceGlass(from, to, out contact);
            contact = to;
            Vector3 delta = to - from;
            Vector3 center = transform.position + Vector3.up;
            Vector3 nearest = from + delta * Mathf.Clamp01(Vector3.Dot(center - from, delta) /
                Mathf.Max(delta.sqrMagnitude, .00001f));
            return Vector3.Distance(nearest, center) <= config.hitRadius;
        }

        public void DamageAtGlass(int damage, Vector3 contact)
        {
            if (Current > 0 && damage > 0 && dome)
            {
                ArtFx.Spawn("fx_drill_spark", contact, 20, .75f);
                ArtFx.Spawn("fx_hit_ice", contact, 19, .55f);
            }
            ApplyDamage(damage);
        }

        private void ApplyDamage(int damage)
        {
            if (Current <= 0 || damage <= 0) return;
            Current = Mathf.Max(0, Current - damage);
            Publish();
        }
        public void Repair() { if (Current <= 0) return; Current = Mathf.Min(Maximum, Current + config.repairAmount); Publish(); }
        public void Upgrade() { Maximum += config.baseHealthBonus; Current += config.baseHealthBonus; Publish(); }
        public void Restore() { Current = Maximum; Publish(); }
        private void Publish()
        {
            // Đã mua thêm máu base và còn khoẻ => hiện bản nâng cấp
            string healthy = Maximum > config.baseHealth ? "bld_base_upgraded" : "bld_base_normal";
            if (dome) dome.SetCondition(Current, Maximum, Maximum > config.baseHealth);
            else if (art) art.Play(Current == 0 ? "bld_base_destroyed" : Current * 2 < Maximum ? "bld_base_damaged" : healthy);
            GameEvents.RaiseBaseHpChanged(Current, Maximum);
        }
    }
}
