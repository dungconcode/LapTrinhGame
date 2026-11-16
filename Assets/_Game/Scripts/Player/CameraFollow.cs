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

        private void Awake() => cam = GetComponent<Camera>();

        private void LateUpdate()
        {
            if (target == null) return;
            var desired = (Vector3)((Vector2)target.position + offset);
            desired.z = transform.position.z;
            var pos = Vector3.SmoothDamp(transform.position, desired, ref velocity, smoothTime);
            transform.position = Clamp(pos);
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
