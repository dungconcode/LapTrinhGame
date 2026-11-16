using UnityEngine;

namespace Underlab.Art
{
    /// <summary>
    /// Hiệu ứng chạy 1 lần rồi tự huỷ, theo art id. Dùng chung cho cả 2 dev:
    ///   ArtFx.Spawn("fx_block_break", pos);
    ///   ArtFx.Spawn("fx_explosion", pos, sortingOrder: 30, scale: 1.5f);
    /// (Nhiều fx cùng lúc thì sau này có thể đổi sang pool — API giữ nguyên.)
    /// </summary>
    public static class ArtFx
    {
        public static GameObject Spawn(string artId, Vector3 position, int sortingOrder = 20, float scale = 1f, bool flipX = false)
        {
            var entry = ArtDatabase.Get(artId);
            if (entry == null || entry.frames == null || entry.frames.Length == 0) return null;

            var go = new GameObject(artId);
            go.transform.position = position;
            go.transform.localScale = Vector3.one * scale;
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sortingOrder = sortingOrder;
            sr.flipX = flipX;
            var art = go.AddComponent<ArtSprite>();
            art.Play(artId, loop: false, restart: true);

            float fps = entry.fps > 0f ? entry.fps : 12f;
            Object.Destroy(go, entry.frames.Length / fps + 0.05f);
            return go;
        }
    }
}
