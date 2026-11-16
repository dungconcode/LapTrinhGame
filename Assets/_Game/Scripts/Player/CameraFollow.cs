using UnityEngine;
using Underlab.Mining;

namespace Underlab.Player
{
    /// <summary>Camera bám theo player, mượt, không đi ra ngoài map.</summary>
    [RequireComponent(typeof(Camera))]
    public class CameraFollow : MonoBehaviour
    {
        [SerializeField] private Transform target;
        [SerializeField] private TerrainGenerator terrain;
        [SerializeField] private Vector2 offset = new Vector2(0f, 0.5f);
        [SerializeField, Min(0f)] private float smoothTime = 0.15f;
        [Tooltip("Cho camera nhìn lên trời bao nhiêu ô phía trên mặt đất")]
        [SerializeField] private float skyMargin = 6f;

        private Camera cam;
        private Vector3 velocity;

        public Transform Target { get => target; set => target = value; }

        private Vector3 basePos;
        private float shakeAmp, shakeTime, shakeDuration;

        private void Awake()
        {
            cam = GetComponent<Camera>();
            basePos = transform.position;
        }

        /// <summary>Rung camera (vd cảnh báo wave, nổ). amplitude tính bằng ô.</summary>
        public void Shake(float amplitude, float duration)
        {
            if (amplitude >= shakeAmp * (shakeTime / Mathf.Max(0.0001f, shakeDuration)))
            {
                shakeAmp = amplitude;
                shakeTime = shakeDuration = duration;
            }
        }

        private void LateUpdate()
        {
            if (target == null) return;
            var desired = (Vector3)((Vector2)target.position + offset);
            desired.z = transform.position.z;
            basePos = Clamp(Vector3.SmoothDamp(basePos, desired, ref velocity, smoothTime));

            var shake = Vector3.zero;
            if (shakeTime > 0f)
            {
                shakeTime -= Time.deltaTime;
                float k = shakeAmp * Mathf.Clamp01(shakeTime / shakeDuration);
                shake = (Vector3)(Random.insideUnitCircle * k);
            }
            transform.position = basePos + shake;
        }

        private Vector3 Clamp(Vector3 p)
        {
            if (terrain == null || !cam.orthographic) return p;
            var b = terrain.WorldBounds;
            float halfH = cam.orthographicSize, halfW = halfH * cam.aspect;

            float minX = b.min.x + halfW, maxX = b.max.x - halfW;
            float minY = b.min.y + halfH, maxY = b.max.y + skyMargin - halfH;
            p.x = minX > maxX ? b.center.x : Mathf.Clamp(p.x, minX, maxX);
            p.y = minY > maxY ? b.center.y : Mathf.Clamp(p.y, minY, maxY);
            return p;
        }
    }
}
