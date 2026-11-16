using System;
using System.Collections.Generic;
using UnityEngine;

namespace Underlab.Art
{
    /// <summary>
    /// Bảng tra "art id" -> danh sách frame sprite.
    /// File này được TỰ ĐỘNG build bởi editor (Underlab/Art/Rebuild Art Database),
    /// mỗi khi có PNG trong Assets/_Game/Art được thêm / thay / xoá.
    /// Code gameplay KHÔNG kéo thả sprite trực tiếp — chỉ dùng id (xem ArtSprite).
    /// </summary>
    public class ArtDatabase : ScriptableObject
    {
        [Serializable]
        public class Entry
        {
            public string id;
            public float fps = 10f;
            public string status;
            public Sprite[] frames;
        }

        [SerializeField] private List<Entry> entries = new List<Entry>();

        private Dictionary<string, Entry> map;
        private static ArtDatabase instance;

        public IReadOnlyList<Entry> Entries => entries;

        public static ArtDatabase Instance
        {
            get
            {
                if (instance == null) instance = Resources.Load<ArtDatabase>("ArtDatabase");
                return instance;
            }
        }

        /// <summary>Lấy entry theo id; null nếu không có.</summary>
        public static Entry Get(string id)
        {
            if (string.IsNullOrEmpty(id)) return null;
            var db = Instance;
            if (db == null) return null;
            if (db.map == null) db.BuildMap();
            db.map.TryGetValue(id, out var e);
            return e;
        }

        /// <summary>Lấy 1 sprite (mặc định frame 0); null nếu không có.</summary>
        public static Sprite GetSprite(string id, int frame = 0)
        {
            var e = Get(id);
            if (e == null || e.frames == null || e.frames.Length == 0) return null;
            return e.frames[Mathf.Clamp(frame, 0, e.frames.Length - 1)];
        }

        private void OnEnable() => map = null;

        private void BuildMap()
        {
            map = new Dictionary<string, Entry>(StringComparer.OrdinalIgnoreCase);
            foreach (var e in entries)
                if (e != null && !string.IsNullOrEmpty(e.id)) map[e.id] = e;
        }

#if UNITY_EDITOR
        public void SetEntries(List<Entry> newEntries)
        {
            entries = newEntries;
            map = null;
        }
#endif
    }
}
