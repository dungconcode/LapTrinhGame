using Underlab.Art;
using UnityEngine;

namespace Underlab.Defense
{
    // Tạo ArtSprite lúc chạy để prefab không giữ sprite xem trước do ExecuteAlways sinh ra.
    [DefaultExecutionOrder(-200)]
    [RequireComponent(typeof(SpriteRenderer))]
    public class DefenseVisual : MonoBehaviour
    {
        public string artId;
        private void Awake()
        {
            var art = GetComponent<ArtSprite>();
            if (!art) art = gameObject.AddComponent<ArtSprite>();
            art.Play(artId);
        }
    }
}
