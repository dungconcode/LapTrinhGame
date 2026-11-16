using System;
using UnityEngine;
using UnityEngine.UI;

namespace Underlab.Art
{
    /// <summary>
    /// Hiển thị / chạy animation cho 1 art id lên SpriteRenderer hoặc UI Image.
    /// Dùng thay cho việc kéo sprite trực tiếp => khi art được thay (placeholder -> AI -> final)
    /// thì KHÔNG phải sửa prefab hay code.
    ///
    ///   art.Play("enemy_melee_walk");            // loop
    ///   art.Play("enemy_melee_death", loop:false); // chạy 1 lần, bắn OnFinished
    ///   art.SetFrame(2);                          // chọn frame thủ công (vd tile_crack)
    /// </summary>
    [ExecuteAlways]
    [DisallowMultipleComponent]
    public class ArtSprite : MonoBehaviour
    {
        [SerializeField] private string artId;
        [SerializeField] private bool loop = true;
        [SerializeField] private bool playOnEnable = true;
        [SerializeField, Min(0f)] private float speed = 1f;

        /// <summary>Gọi khi animation không-loop chạy xong (tham số = id).</summary>
        public event Action<string> OnFinished;

        public string CurrentId => artId;
        public bool IsPlaying => playing;
        public int Frame => frame;
        public int FrameCount => entry?.frames?.Length ?? 0;
        public float Speed { get => speed; set => speed = Mathf.Max(0f, value); }

        private SpriteRenderer spriteRenderer;
        private Image image;
        private ArtDatabase.Entry entry;
        private float timer;
        private int frame;
        private bool playing;

        private void Awake() => CacheTargets();

        private void OnEnable()
        {
            CacheTargets();
            Resolve();
            frame = 0;
            timer = 0f;
            playing = Application.isPlaying && playOnEnable;
            ApplyFrame();
        }

#if UNITY_EDITOR
        private void OnValidate()
        {
            // Không được set sprite trực tiếp trong OnValidate => đợi 1 nhịp editor.
            UnityEditor.EditorApplication.delayCall += () =>
            {
                if (this == null) return;
                CacheTargets();
                Resolve();
                ApplyFrame();
            };
        }
#endif

        public void Play(string id, bool loop = true, bool restart = false)
        {
            if (!restart && playing && string.Equals(id, artId, StringComparison.OrdinalIgnoreCase))
            {
                this.loop = loop;
                return;
            }
            artId = id;
            this.loop = loop;
            Resolve();
            frame = 0;
            timer = 0f;
            playing = true;
            ApplyFrame();
        }

        public void Stop() => playing = false;

        public void SetFrame(int index)
        {
            playing = false;
            frame = FrameCount == 0 ? 0 : Mathf.Clamp(index, 0, FrameCount - 1);
            ApplyFrame();
        }

        public void SetFlipX(bool flip)
        {
            if (spriteRenderer != null) spriteRenderer.flipX = flip;
        }

        private void Update()
        {
            if (!Application.isPlaying || !playing || entry == null) return;
            int count = FrameCount;
            if (count <= 1 || entry.fps <= 0f) return;

            timer += Time.deltaTime * speed * entry.fps;
            bool changed = false;
            while (timer >= 1f)
            {
                timer -= 1f;
                frame++;
                changed = true;
                if (frame >= count)
                {
                    if (loop) frame = 0;
                    else
                    {
                        frame = count - 1;
                        playing = false;
                        ApplyFrame();
                        OnFinished?.Invoke(artId);
                        return;
                    }
                }
            }
            if (changed) ApplyFrame();
        }

        private void CacheTargets()
        {
            if (spriteRenderer == null) spriteRenderer = GetComponent<SpriteRenderer>();
            if (image == null) image = GetComponent<Image>();
        }

        private void Resolve()
        {
            entry = ArtDatabase.Get(artId);
            if (entry == null && !string.IsNullOrEmpty(artId) && Application.isPlaying)
                Debug.LogWarning($"[ArtSprite] Không tìm thấy art id '{artId}' (kiểm tra asset_manifest.csv / Rebuild Art Database)", this);
        }

        private void ApplyFrame()
        {
            if (entry == null || entry.frames == null || entry.frames.Length == 0) return;
            var sprite = entry.frames[Mathf.Clamp(frame, 0, entry.frames.Length - 1)];
            if (spriteRenderer != null && spriteRenderer.sprite != sprite) spriteRenderer.sprite = sprite;
            if (image != null && image.sprite != sprite) image.sprite = sprite;
        }
    }
}
