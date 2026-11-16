using UnityEngine;
using Underlab.Art;

namespace Underlab.Mining
{
    /// <summary>
    /// 1 lớp nền parallax. SpriteRenderer ở chế độ Tiled nên ảnh tự lặp, phủ vùng rộng.
    ///   follow = (1,1): dính chặt camera (xa vô cực) · (0,0): đứng yên như vật trong thế giới.
    /// Vị trí = anchor + camera * follow.
    /// </summary>
    [RequireComponent(typeof(SpriteRenderer))]
    public class ParallaxLayer : MonoBehaviour
    {
        [SerializeField] private string artId;
        [SerializeField] private Vector2 follow = new Vector2(0.5f, 0.5f);
        [SerializeField] private Vector2 anchor;
        [Tooltip("Kích thước vùng phủ (đơn vị thế giới)")]
        [SerializeField] private Vector2 size = new Vector2(200f, 60f);
        [SerializeField] private Color tint = Color.white;
        [SerializeField] private Transform cameraTransform;

        private SpriteRenderer sr;

        private void Awake()
        {
            sr = GetComponent<SpriteRenderer>();
            if (cameraTransform == null && Camera.main != null) cameraTransform = Camera.main.transform;
            Apply();
        }

        private void OnValidate()
        {
            if (sr == null) sr = GetComponent<SpriteRenderer>();
#if UNITY_EDITOR
            UnityEditor.EditorApplication.delayCall += () => { if (this != null) Apply(); };
#endif
        }

        private void Apply()
        {
            var sprite = ArtDatabase.GetSprite(artId);
            if (sprite != null) sr.sprite = sprite;
            sr.drawMode = SpriteDrawMode.Tiled;
            sr.tileMode = SpriteTileMode.Continuous;
            sr.size = size;
            sr.color = tint;
            UpdatePosition();
        }

        private void LateUpdate() => UpdatePosition();

        private void UpdatePosition()
        {
            Vector2 cam = cameraTransform != null ? (Vector2)cameraTransform.position : Vector2.zero;
            var p = anchor + Vector2.Scale(cam, follow);
            transform.position = new Vector3(p.x, p.y, transform.position.z);
        }
    }
}
