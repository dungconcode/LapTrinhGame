using UnityEngine;

namespace Underlab.Art
{
    /// <summary>
    /// Chữ nổi trong thế giới game (vd "+1 Sắt", "-20" damage). Dùng chung cho cả 2 dev:
    ///   FloatingText.Spawn("+1 Sắt", pos, Color.yellow);
    /// Tạo label cố định (không tự bay/huỷ): FloatingText.CreateLabel(...)
    /// Dùng TextMesh có sẵn của Unity (không cần import TMP).
    /// </summary>
    public class FloatingText : MonoBehaviour
    {
        private static Font font;

        private TextMesh mesh;
        private Color baseColor;
        private float life, age;
        private Vector3 velocity;

        public static FloatingText Spawn(string text, Vector3 position, Color color,
                                         float duration = 0.9f, float riseSpeed = 1.2f, float size = 1f)
        {
            var label = CreateLabel(text, position, color, size);
            var ft = label.gameObject.AddComponent<FloatingText>();
            ft.mesh = label;
            ft.baseColor = color;
            ft.life = duration;
            ft.velocity = Vector3.up * riseSpeed;
            return ft;
        }

        public static TextMesh CreateLabel(string text, Vector3 position, Color color, float size = 1f, int sortingOrder = 50)
        {
            if (font == null) font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");

            var go = new GameObject("Text " + text);
            go.transform.position = position;
            var tm = go.AddComponent<TextMesh>();
            tm.text = text;
            tm.font = font;
            tm.fontSize = 64;
            tm.characterSize = 0.05f * size;
            tm.anchor = TextAnchor.MiddleCenter;
            tm.alignment = TextAlignment.Center;
            tm.fontStyle = FontStyle.Bold;
            tm.color = color;
            var mr = go.GetComponent<MeshRenderer>();
            mr.sharedMaterial = font.material;
            mr.sortingOrder = sortingOrder;
            return tm;
        }

        private void Update()
        {
            age += Time.deltaTime;
            transform.position += velocity * Time.deltaTime;
            velocity *= 1f - 2f * Time.deltaTime; // chậm dần
            float t = age / life;
            var c = baseColor;
            c.a = t < 0.6f ? 1f : Mathf.Lerp(1f, 0f, (t - 0.6f) / 0.4f);
            mesh.color = c;
            if (age >= life) Destroy(gameObject);
        }
    }
}
