using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using UnityEngine;

namespace Underlab.EditorTools.Art
{
    public class ArtEntry
    {
        public string id, category, type, pivot, priority, status, aiTool, notes;
        public int frames = 1;
        public float fps = 10f;
        public float worldW;
        public int specW = 128, specH = 128;

        public bool IsUi => type == "ui" || worldW <= 0f;

        /// <summary>Các trường ảnh hưởng tới cách import (đổi => phải reimport PNG).</summary>
        public string ImportSignature =>
            string.Join("|", type, frames, worldW.ToString(CultureInfo.InvariantCulture), pivot);
    }

    /// <summary>Đọc Assets/_Game/Art/asset_manifest.csv (nguồn sự thật cho spec của mọi asset).</summary>
    public static class ArtManifest
    {
        public const string ArtRoot = "Assets/_Game/Art/";
        public const string ManifestPath = "Assets/_Game/Art/asset_manifest.csv";
        private const string SignatureCache = "Library/underlab_art_signatures.txt";

        private static Dictionary<string, ArtEntry> cache;
        private static DateTime cacheTime;

        public static Dictionary<string, ArtEntry> Load()
        {
            if (!File.Exists(ManifestPath))
            {
                Debug.LogWarning($"[Art] Không thấy {ManifestPath}");
                return new Dictionary<string, ArtEntry>(StringComparer.OrdinalIgnoreCase);
            }

            var stamp = File.GetLastWriteTimeUtc(ManifestPath);
            if (cache != null && stamp == cacheTime) return cache;

            var dict = new Dictionary<string, ArtEntry>(StringComparer.OrdinalIgnoreCase);
            var lines = File.ReadAllLines(ManifestPath);
            for (int i = 1; i < lines.Length; i++)
            {
                var line = lines[i].Trim();
                if (line.Length == 0 || line.StartsWith("#")) continue;

                var c = line.Split(new[] { ',' }, 12);
                if (c.Length < 8)
                {
                    Debug.LogWarning($"[Art] Dòng {i + 1} trong manifest thiếu cột: {line}");
                    continue;
                }

                var e = new ArtEntry
                {
                    id = c[0].Trim(),
                    category = c[1].Trim().ToLowerInvariant(),
                    type = c[2].Trim().ToLowerInvariant(),
                    pivot = c[6].Trim().ToLowerInvariant(),
                    priority = Col(c, 8),
                    status = Col(c, 9),
                    aiTool = Col(c, 10),
                    notes = Col(c, 11),
                };
                int.TryParse(c[3].Trim(), out e.frames);
                if (e.frames < 1) e.frames = 1;
                float.TryParse(c[4].Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out e.fps);
                float.TryParse(c[5].Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out e.worldW);
                ParseSpec(c[7].Trim(), e);

                if (dict.ContainsKey(e.id)) Debug.LogWarning($"[Art] id bị trùng trong manifest: {e.id}");
                dict[e.id] = e;
            }

            cache = dict;
            cacheTime = stamp;
            return cache;
        }

        public static bool TryGetForAsset(string assetPath, out ArtEntry entry)
        {
            entry = null;
            if (string.IsNullOrEmpty(assetPath)) return false;
            assetPath = assetPath.Replace('\\', '/');
            if (!assetPath.StartsWith(ArtRoot, StringComparison.OrdinalIgnoreCase)) return false;
            if (!assetPath.EndsWith(".png", StringComparison.OrdinalIgnoreCase)) return false;
            return Load().TryGetValue(Path.GetFileNameWithoutExtension(assetPath), out entry);
        }

        public static Vector2 PivotOf(ArtEntry e)
        {
            switch (e.pivot)
            {
                case "bc": return new Vector2(0.5f, 0f);
                case "c": return new Vector2(0.5f, 0.5f);
                case "tc": return new Vector2(0.5f, 1f);
                case "lc": return new Vector2(0f, 0.5f);
                case "rc": return new Vector2(1f, 0.5f);
                case "bl": return new Vector2(0f, 0f);
            }
            var p = e.pivot.Split(';');
            if (p.Length == 2 &&
                float.TryParse(p[0], NumberStyles.Float, CultureInfo.InvariantCulture, out var x) &&
                float.TryParse(p[1], NumberStyles.Float, CultureInfo.InvariantCulture, out var y))
                return new Vector2(x, y);
            return new Vector2(0.5f, 0.5f);
        }

        /// <summary>Đọc width/height từ header PNG (không cần load texture).</summary>
        public static bool TryReadPngSize(string path, out int width, out int height)
        {
            width = height = 0;
            try
            {
                using (var fs = File.OpenRead(path))
                {
                    var buf = new byte[24];
                    if (fs.Read(buf, 0, 24) < 24) return false;
                    if (buf[1] != 'P' || buf[2] != 'N' || buf[3] != 'G') return false;
                    width = (buf[16] << 24) | (buf[17] << 16) | (buf[18] << 8) | buf[19];
                    height = (buf[20] << 24) | (buf[21] << 16) | (buf[22] << 8) | buf[23];
                    return width > 0 && height > 0;
                }
            }
            catch (IOException) { return false; }
        }

        /// <summary>Trả về id có spec import bị đổi so với lần trước (để reimport đúng file).</summary>
        public static List<string> DiffSignatures()
        {
            var now = new Dictionary<string, string>();
            foreach (var e in Load().Values) now[e.id] = e.ImportSignature;

            var changed = new List<string>();
            if (File.Exists(SignatureCache))
            {
                var old = new Dictionary<string, string>();
                foreach (var l in File.ReadAllLines(SignatureCache))
                {
                    int tab = l.IndexOf('\t');
                    if (tab > 0) old[l.Substring(0, tab)] = l.Substring(tab + 1);
                }
                foreach (var kv in now)
                    if (old.TryGetValue(kv.Key, out var sig) && sig != kv.Value) changed.Add(kv.Key);
            }

            var outLines = new List<string>();
            foreach (var kv in now) outLines.Add(kv.Key + "\t" + kv.Value);
            File.WriteAllLines(SignatureCache, outLines);
            return changed;
        }

        private static string Col(string[] c, int i) => i < c.Length ? c[i].Trim() : "";

        private static void ParseSpec(string s, ArtEntry e)
        {
            var p = s.ToLowerInvariant().Split('x');
            if (p.Length == 2 && int.TryParse(p[0], out var w) && int.TryParse(p[1], out var h))
            {
                e.specW = w;
                e.specH = h;
            }
        }
    }
}
