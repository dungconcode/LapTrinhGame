using UnityEngine;

namespace Underlab.Art
{
    /// <summary>Giữ hình (frame cuối của animation) một lúc rồi mờ dần và tự huỷ. Dùng cho xác quái.</summary>
    public class ArtFxFader : MonoBehaviour
    {
        private SpriteRenderer sr;
        private float fadeStart, fadeEnd;

        public void Begin(float holdSeconds, float fadeSeconds)
        {
            sr = GetComponent<SpriteRenderer>();
            fadeStart = Time.time + holdSeconds;
            fadeEnd = fadeStart + Mathf.Max(0.01f, fadeSeconds);
        }

        private void Update()
        {
            if (Time.time < fadeStart || sr == null) return;
            float t = Mathf.InverseLerp(fadeStart, fadeEnd, Time.time);
            var c = sr.color;
            c.a = 1f - t;
            sr.color = c;
            if (t >= 1f) Destroy(gameObject);
        }
    }
}
