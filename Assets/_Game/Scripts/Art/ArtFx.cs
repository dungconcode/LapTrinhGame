using UnityEngine;

namespace Underlab.Art
{
    /// <summary>
    /// Hiệu ứng chạy 1 lần rồi tự huỷ, theo art id. Dùng chung cho cả 2 dev:
    ///   ArtFx.Spawn("fx_block_break", pos);
    ///   ArtFx.Spawn("fx_explosion", pos, sortingOrder: 30, scale: 1.5f);
    ///   ArtFx.Spawn("enemy_melee_death", pos, 11, flipX: true, linger: 0.6f); // giữ frame cuối 0.6s rồi mờ dần
    /// </summary>
    public static class ArtFx
    {
        public static GameObject Spawn(string artId, Vector3 position, int sortingOrder = 20, float scale = 1f,
                                       bool flipX = false, float linger = 0f, float rotationZ = 0f)
        {
            var entry = ArtDatabase.Get(artId);
            if (entry == null || entry.frames == null || entry.frames.Length == 0) return null;

            var go = new GameObject(artId);
            go.transform.position = position;
            go.transform.localScale = Vector3.one * scale;
            if (rotationZ != 0f) go.transform.rotation = Quaternion.Euler(0f, 0f, rotationZ);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sortingOrder = sortingOrder;
            sr.flipX = flipX;
            var art = go.AddComponent<ArtSprite>();
            art.Play(artId, loop: false, restart: true);

            float fps = entry.fps > 0f ? entry.fps : 12f;
            float duration = entry.frames.Length / fps;
            if (linger > 0f)
                go.AddComponent<ArtFxFader>().Begin(duration + linger * 0.5f, linger * 0.5f);
            else
                Object.Destroy(go, duration + 0.05f);
            return go;
        }
    }
}
