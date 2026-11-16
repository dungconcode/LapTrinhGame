using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using UnityEditor;
using UnityEngine;
using UnityEngine.Tilemaps;
using Underlab.Art;

namespace Underlab.EditorTools.Art
{
    /// <summary>
    /// Quét Assets/_Game/Art, ghép với manifest, ghi ra Assets/_Game/Resources/ArtDatabase.asset.
    /// Với type = tile còn tạo Tile asset ở Assets/_Game/Art/_GeneratedTiles/{id}.asset để vẽ Tilemap.
    /// </summary>
    public static class ArtDatabaseBuilder
    {
        public const string DbFolder = "Assets/_Game/Resources";
        public const string DbPath = DbFolder + "/ArtDatabase.asset";
        public const string TilesFolder = "Assets/_Game/Art/_GeneratedTiles";

        private static bool scheduled;

        public static void Schedule()
        {
            if (scheduled) return;
            scheduled = true;
            EditorApplication.delayCall += () =>
            {
                scheduled = false;
                Build(false);
            };
        }

        [MenuItem("Underlab/Art/Rebuild Art Database + Report", priority = 1)]
        private static void BuildMenu() => Build(true);

        /// <summary>Tìm file PNG cho từng id (tên file = id, nằm bất kỳ đâu trong Assets/_Game/Art).</summary>
        public static Dictionary<string, string> FindArtFiles(Dictionary<string, ArtEntry> manifest, bool warnDuplicates)
        {
            var found = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (var guid in AssetDatabase.FindAssets("t:Texture2D", new[] { ArtManifest.ArtRoot.TrimEnd('/') }))
            {
                var path = AssetDatabase.GUIDToAssetPath(guid);
                if (!path.EndsWith(".png", StringComparison.OrdinalIgnoreCase)) continue;
                var id = Path.GetFileNameWithoutExtension(path);
                if (!manifest.ContainsKey(id)) continue;
                if (found.TryGetValue(id, out var other))
                {
                    if (warnDuplicates) Debug.LogWarning($"[Art] id '{id}' có 2 file: {other} và {path} — xoá 1 file.");
                    continue;
                }
                found[id] = path;
            }
            return found;
        }

        public static void Build(bool verbose)
        {
            var manifest = ArtManifest.Load();
            var files = FindArtFiles(manifest, true);

            var db = AssetDatabase.LoadAssetAtPath<ArtDatabase>(DbPath);
            if (db == null)
            {
                EnsureFolder(DbFolder);
                db = ScriptableObject.CreateInstance<ArtDatabase>();
                AssetDatabase.CreateAsset(db, DbPath);
            }

            var entries = new List<ArtDatabase.Entry>();
            var missing = new List<string>();
            var unsliced = new List<string>();

            foreach (var e in manifest.Values)
            {
                if (!files.TryGetValue(e.id, out var path))
                {
                    missing.Add(e.id);
                    continue;
                }
                var sprites = AssetDatabase.LoadAllAssetsAtPath(path).OfType<Sprite>()
                    .OrderBy(s => FrameIndex(s.name)).ToArray();
                if (sprites.Length == 0) continue;
                if (sprites.Length != e.frames) unsliced.Add($"{e.id} ({sprites.Length}/{e.frames})");

                entries.Add(new ArtDatabase.Entry { id = e.id, fps = e.fps, status = e.status, frames = sprites });
                if (e.type == "tile") EnsureTile(e.id, sprites[0]);
            }

            db.SetEntries(entries);
            EditorUtility.SetDirty(db);
            AssetDatabase.SaveAssets();

            if (unsliced.Count > 0)
                Debug.LogWarning("[Art] Số frame không khớp manifest (thử Reimport file): " + string.Join(", ", unsliced));

            if (!verbose) return;

            var sb = new StringBuilder();
            sb.AppendLine($"[Art] Database: {entries.Count}/{manifest.Count} id có file. Thiếu file: {missing.Count}.");
            foreach (var g in manifest.Values.GroupBy(x => string.IsNullOrEmpty(x.status) ? "?" : x.status).OrderBy(g => g.Key))
                sb.AppendLine($"  status {g.Key,-12}: {g.Count()}");
            foreach (var g in manifest.Values.GroupBy(x => x.priority).OrderBy(g => g.Key))
                sb.AppendLine($"  {g.Key}: {g.Count(x => x.status == "final" || x.status == "ai-approved")}/{g.Count()} đã chốt (final / ai-approved)");
            if (missing.Count > 0)
                sb.AppendLine("  Thiếu file (chạy Underlab/Art/Generate Missing Placeholders): " + string.Join(", ", missing));
            Debug.Log(sb.ToString());
        }

        private static void EnsureTile(string id, Sprite sprite)
        {
            EnsureFolder(TilesFolder);
            var path = $"{TilesFolder}/{id}.asset";
            var tile = AssetDatabase.LoadAssetAtPath<Tile>(path);
            if (tile == null)
            {
                tile = ScriptableObject.CreateInstance<Tile>();
                tile.sprite = sprite;
                tile.colliderType = Tile.ColliderType.Grid;
                AssetDatabase.CreateAsset(tile, path);
            }
            else if (tile.sprite != sprite)
            {
                tile.sprite = sprite;
                EditorUtility.SetDirty(tile);
            }
        }

        private static int FrameIndex(string spriteName)
        {
            int us = spriteName.LastIndexOf('_');
            return us >= 0 && int.TryParse(spriteName.Substring(us + 1), out var n) ? n : 0;
        }

        public static void EnsureFolder(string folder)
        {
            if (AssetDatabase.IsValidFolder(folder)) return;
            var parent = Path.GetDirectoryName(folder).Replace('\\', '/');
            EnsureFolder(parent);
            AssetDatabase.CreateFolder(parent, Path.GetFileName(folder));
        }
    }
}
