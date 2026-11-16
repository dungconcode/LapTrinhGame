using UnityEngine;
using Underlab.Art;
using Underlab.Core;

namespace Underlab.Mining
{
    /// <summary>
    /// Cục quặng rơi ra khi phá ô quặng. Có vật lý (rơi, lăn), không va chạm với player.
    /// Carrier (A04) sẽ nhặt: kiểm tra CanPickup rồi gọi Collect().
    /// </summary>
    [RequireComponent(typeof(Rigidbody2D), typeof(CircleCollider2D))]
    public class OrePickup : MonoBehaviour
    {
        public ResourceType Type { get; private set; }
        public int Amount { get; private set; } = 1;
        public bool CanPickup => Time.time >= pickupAt && !collected && waitLeave == null;

        private float pickupAt;
        private bool collected;
        private Transform waitLeave;   // quặng do player tự vứt: chờ player đi xa rồi mới cho nhặt lại
        private float leaveDistance;

        /// <summary>Không cho nhặt lại cho tới khi 'who' đi xa hơn 'distance'.</summary>
        public void BlockUntilLeave(Transform who, float distance)
        {
            waitLeave = who;
            leaveDistance = distance;
        }

        private void Update()
        {
            if (waitLeave != null && Vector2.Distance(waitLeave.position, transform.position) > leaveDistance)
                waitLeave = null;
        }

        public static string ItemArtId(ResourceType t)
        {
            switch (t)
            {
                case ResourceType.Iron: return "item_ore_iron";
                case ResourceType.Sulfur: return "item_ore_sulfur";
                case ResourceType.Magnesium: return "item_ore_mg";
                case ResourceType.KCl: return "item_ore_kcl";
                default: return "item_ore_iron";
            }
        }

        public static OrePickup Spawn(ResourceType type, int amount, Vector3 position, Collider2D ignore,
                                      float popSpeed = 2.5f, float pickupDelay = 0.25f)
        {
            var go = new GameObject($"Ore_{type}");
            go.transform.position = position;

            var sr = go.AddComponent<SpriteRenderer>();
            sr.sortingOrder = 8;
            var art = go.AddComponent<ArtSprite>();
            art.Play(ItemArtId(type));

            var rb = go.AddComponent<Rigidbody2D>();
            rb.gravityScale = 2f;
            rb.interpolation = RigidbodyInterpolation2D.Interpolate;
            var col = go.AddComponent<CircleCollider2D>();
            col.radius = 0.2f;
            if (ignore != null) Physics2D.IgnoreCollision(col, ignore);

            var p = go.AddComponent<OrePickup>();
            p.Type = type;
            p.Amount = Mathf.Max(1, amount);
            p.pickupAt = Time.time + pickupDelay;

            rb.linearVelocity = new Vector2(Random.Range(-0.6f, 0.6f), 1f) * popSpeed;
            rb.angularVelocity = Random.Range(-180f, 180f);
            return p;
        }

        /// <summary>Gọi khi được nhặt. Trả về false nếu đã bị nhặt rồi.</summary>
        public bool Collect()
        {
            if (collected) return false;
            collected = true;
            Destroy(gameObject);
            return true;
        }
    }
}
