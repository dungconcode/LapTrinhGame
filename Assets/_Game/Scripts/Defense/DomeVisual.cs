using Underlab.Art;
using UnityEngine;

namespace Underlab.Defense
{
    /// <summary>Base hai tầng; kính và lớp nứt có renderer riêng để thay shader/overlay độc lập.</summary>
    [DefaultExecutionOrder(-150)]
    [RequireComponent(typeof(SpriteRenderer))]
    public class DomeVisual : MonoBehaviour
    {
        public SpriteRenderer GlassDomeLayer { get; private set; }
        public SpriteRenderer CrackOverlay { get; private set; }
        // Cùng tâm và bán kính với khung bán nguyệt trong art 128 px / 4 ô.
        private const float Radius = 1.875f;
        private static readonly Vector2 ArcCenter = new Vector2(0f, .28125f);
        private SpriteRenderer frame, interior;
        private Vector2[] glassOutline;

        private void Awake() => Initialize();

        public void Initialize()
        {
            // Renderer cũ vẫn phục vụ prefab cũ; base mới chỉ vẽ các layer con qua art id.
            GetComponent<SpriteRenderer>().enabled = false;
            Layer("MainShaft", "bld_dome_shaft", new Vector3(0, -2, 0), 3);
            Layer("UndergroundChamber", "bld_dome_underground", Vector3.zero, 4);
            frame = Layer("DomeFrame", "bld_dome_frame", Vector3.zero, 6);
            interior = Layer("DomeInterior", "bld_dome_interior", Vector3.zero, 7);
            GlassDomeLayer = Layer("GlassDomeLayer", "bld_dome_glass", Vector3.zero, 12);
            CrackOverlay = Layer("GlassCrackOverlay", "bld_dome_cracks", Vector3.zero, 13);
            CrackOverlay.enabled = false;
            BuildGlassCollision();
        }

        private void BuildGlassCollision()
        {
            var shell = GlassDomeLayer.GetComponent<EdgeCollider2D>();
            if (!shell) shell = GlassDomeLayer.gameObject.AddComponent<EdgeCollider2D>();
            const int segments = 24;
            glassOutline = new Vector2[segments + 3];
            for (int i = 0; i <= segments; i++)
            {
                float angle = Mathf.PI * i / segments;
                glassOutline[i + 1] = ArcCenter + Radius * new Vector2(Mathf.Cos(angle), Mathf.Sin(angle));
            }
            // Chôn hai đầu khung qua mặt sàn để không lọt qua chân kính.
            glassOutline[0] = new Vector2(Radius, -.2f);
            glassOutline[glassOutline.Length - 1] = new Vector2(-Radius, -.2f);
            shell.points = glassOutline;
        }

        public Vector3 GlassContact(Vector3 source)
        {
            Vector2 direction = (Vector2)transform.InverseTransformPoint(source) - ArcCenter;
            direction.y = Mathf.Max(0f, direction.y);
            if (direction.sqrMagnitude < .0001f) direction = Vector2.up;
            return transform.TransformPoint(ArcCenter + direction.normalized * Radius);
        }

        public bool TryTraceGlass(Vector3 from, Vector3 to, out Vector3 contact)
        {
            contact = default;
            Vector2 start = transform.InverseTransformPoint(from);
            Vector2 delta = (Vector2)transform.InverseTransformPoint(to) - start;
            float firstHit = float.PositiveInfinity;
            for (int i = 1; i < glassOutline.Length; i++)
            {
                Vector2 edge = glassOutline[i] - glassOutline[i - 1];
                float denominator = Cross(delta, edge);
                if (Mathf.Abs(denominator) < .000001f) continue;
                Vector2 relative = glassOutline[i - 1] - start;
                float shotTime = Cross(relative, edge) / denominator;
                float edgeTime = Cross(relative, delta) / denominator;
                if (shotTime >= 0f && shotTime <= 1f && edgeTime >= 0f && edgeTime <= 1f &&
                    start.y + delta.y * shotTime >= 0f)
                    firstHit = Mathf.Min(firstHit, shotTime);
            }
            if (float.IsPositiveInfinity(firstHit)) return false;
            contact = transform.TransformPoint(start + delta * firstHit);
            return true;
        }

        private static float Cross(Vector2 a, Vector2 b) => a.x * b.y - a.y * b.x;

        private SpriteRenderer Layer(string name, string id, Vector3 position, int order)
        {
            var child = transform.Find(name);
            if (!child)
            {
                child = new GameObject(name, typeof(SpriteRenderer)).transform;
                child.SetParent(transform, false);
            }
            child.localPosition = position;
            var renderer = child.GetComponent<SpriteRenderer>();
            renderer.sortingLayerID = GetComponent<SpriteRenderer>().sortingLayerID;
            renderer.sortingOrder = order;
            // Giữ material sprite mặc định để đồng bộ ánh sáng 2D của màn chơi.
            var visual = child.GetComponent<DefenseVisual>();
            if (!visual) visual = child.gameObject.AddComponent<DefenseVisual>();
            visual.artId = id;
            if (Application.isPlaying)
            {
                var art = child.GetComponent<ArtSprite>();
                if (!art) art = child.gameObject.AddComponent<ArtSprite>();
                art.Play(id);
            }
            return renderer;
        }

        public void SetCondition(int current, int maximum, bool upgraded)
        {
            if (!GlassDomeLayer) Initialize();
            GlassDomeLayer.enabled = current > 0;
            float ratio = maximum > 0 ? (float)current / maximum : 0f;
            CrackOverlay.enabled = current > 0 && ratio < .75f;
            if (CrackOverlay.enabled)
            {
                int stage = ratio < .25f ? 2 : ratio < .5f ? 1 : 0;
                CrackOverlay.GetComponent<ArtSprite>().SetFrame(stage);
                CrackOverlay.color = Color.Lerp(Color.white, new Color(1f, .55f, .4f),
                    Mathf.InverseLerp(.25f, 0f, ratio));
            }
            frame.color = current == 0 ? new Color(.5f, .42f, .56f) :
                upgraded ? new Color(1f, .9f, .8f) : Color.white;
            interior.color = current == 0 ? new Color(.35f, .3f, .4f) : Color.white;
        }
    }
}
