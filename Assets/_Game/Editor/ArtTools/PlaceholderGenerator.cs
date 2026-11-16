using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace Underlab.EditorTools.Art
{
    /// <summary>
    /// Sinh PNG placeholder (khối màu theo category, đúng kích thước spec, đúng số frame)
    /// cho mọi id trong manifest CHƯA có file. Không bao giờ ghi đè file có sẵn.
    /// => Ngày 1 dev đã có đủ "asset" để code, art thật về chỉ việc chép đè.
    /// </summary>
    public static class PlaceholderGenerator
    {
        private static readonly Dictionary<string, Color32> CategoryColors = new Dictionary<string, Color32>
        {
            { "char", new Color32(80, 170, 255, 255) },
            { "tile", new Color32(140, 100, 70, 255) },
            { "item", new Color32(255, 210, 60, 255) },
            { "bld", new Color32(120, 200, 140, 255) },
            { "proj", new Color32(255, 255, 255, 255) },
            { "enemy", new Color32(230, 70, 70, 255) },
            { "boss", new Color32(160, 40, 160, 255) },
            { "fx", new Color32(255, 150, 40, 255) },
            { "bg", new Color32(40, 50, 80, 255) },
            { "ui", new Color32(70, 90, 110, 255) },
            { "icon", new Color32(200, 200, 220, 255) },
        };

        // Màu riêng cho quặng để phân biệt được ngay khi test.
        private static readonly Dictionary<string, Color32> KeywordColors = new Dictionary<string, Color32>
        {
            { "iron", new Color32(170, 80, 50, 255) },
            { "sulfur", new Color32(240, 220, 40, 255) },
            { "_mg", new Color32(225, 225, 235, 255) },
            { "kcl", new Color32(250, 190, 210, 255) },
            { "acid", new Color32(90, 220, 60, 255) },
            { "fire", new Color32(255, 90, 20, 255) },
            { "ice", new Color32(140, 220, 255, 255) },
            { "dirt_2", new Color32(105, 80, 65, 255) },
            { "dirt_3", new Color32(75, 65, 70, 255) },
            { "bedrock", new Color32(35, 35, 40, 255) },
            { "bar_fill", new Color32(255, 255, 255, 255) }, // code tô màu => placeholder phải trắng
        };

        [MenuItem("Underlab/Art/Generate Missing Placeholders", priority = 0)]
        public static void Generate()
        {
            var manifest = ArtManifest.Load();
            var existing = ArtDatabaseBuilder.FindArtFiles(manifest, false);
            int created = 0;

            foreach (var e in manifest.Values)
            {
                if (existing.ContainsKey(e.id)) continue;
                var dir = ArtManifest.ArtRoot + e.category;
                Directory.CreateDirectory(dir);
                File.WriteAllBytes($"{dir}/{e.id}.png", Draw(e));
                created++;
            }

            AssetDatabase.Refresh();
            Debug.Log($"[Art] Đã tạo {created} placeholder. (Bỏ qua {existing.Count} id đã có file.)");
        }

        private static byte[] Draw(ArtEntry e)
        {
            int fw = Mathf.Max(8, e.specW), fh = Mathf.Max(8, e.specH);
            int w = fw * e.frames;
            var px = new Color32[w * fh];
            var baseCol = PickColor(e);
            bool solid = e.type == "tile" && e.frames == 1 || e.category == "bg" || e.type == "ui";
            var pivot = ArtManifest.PivotOf(e);

            for (int f = 0; f < e.frames; f++)
            {
                int ox = f * fw;
                // Thân: tile / bg / ui phủ kín; còn lại chừa lề 12% để thấy silhouette + pivot.
                int mx = solid ? 0 : fw * 12 / 100;
                int my = solid ? 0 : fh * 12 / 100;
                int bob = solid ? 0 : (f % 2) * Mathf.Max(2, fh / 40); // nhấp nhô để thấy anim chạy
                var col = Shade(baseCol, 1f - 0.08f * (f % 3));
                if (e.id == "tile_crack") col = new Color32(0, 0, 0, 0);

                Fill(px, w, ox + mx, my + bob, fw - 2 * mx, fh - 2 * my, col);
                Border(px, w, ox + mx, my + bob, fw - 2 * mx, fh - 2 * my, Mathf.Max(2, fw / 48), Shade(baseCol, 0.45f));

                if (e.id == "tile_crack") // vết nứt dày dần theo frame
                    for (int k = 0; k <= f; k++)
                        Line(px, w, ox + fw / 2, fh / 2, ox + (k * 37 % fw), (k * 53 + 11) % fh, 3, new Color32(20, 15, 10, 255));

                // Số frame: f+1 vạch nhỏ ở góc trên trái.
                int bar = Mathf.Max(3, fw / 32);
                for (int k = 0; k <= f; k++)
                    Fill(px, w, ox + mx + bar + k * bar * 2, fh - my - bar * 4 + bob, bar, bar * 2, new Color32(255, 255, 255, 255));

                // Đánh dấu pivot.
                int pxv = ox + Mathf.Clamp((int)(pivot.x * fw), 0, fw - 1);
                int pyv = Mathf.Clamp((int)(pivot.y * fh), 0, fh - 1);
                int ps = Mathf.Max(3, fw / 24);
                Fill(px, w, pxv - ps, pyv - ps, ps * 2, ps * 2, new Color32(255, 0, 255, 255));

                // Hướng nhìn: tam giác nhỏ chỉ sang phải (char/proj/bld) hoặc trái (enemy/boss).
                if (!solid && e.category != "item" && e.category != "fx")
                {
                    bool left = e.category == "enemy" || e.category == "boss";
                    int cy = fh / 2 + bob, size = Mathf.Max(4, fh / 8);
                    int tipX = left ? ox + mx + size / 2 : ox + fw - mx - size / 2;
                    for (int d = 0; d < size; d++)
                    {
                        int x = left ? tipX + d : tipX - d;
                        Fill(px, w, x, cy - d / 2, 1, Mathf.Max(1, d), new Color32(20, 20, 20, 255));
                    }
                }
            }

            var tex = new Texture2D(w, fh, TextureFormat.RGBA32, false);
            tex.SetPixels32(px);
            var png = tex.EncodeToPNG();
            Object.DestroyImmediate(tex);
            return png;
        }

        private static Color32 PickColor(ArtEntry e)
        {
            foreach (var kv in KeywordColors)
                if (e.id.Contains(kv.Key)) return kv.Value;
            return CategoryColors.TryGetValue(e.category, out var c) ? c : new Color32(128, 128, 128, 255);
        }

        private static Color32 Shade(Color32 c, float k) =>
            new Color32((byte)Mathf.Clamp(c.r * k, 0, 255), (byte)Mathf.Clamp(c.g * k, 0, 255), (byte)Mathf.Clamp(c.b * k, 0, 255), c.a);

        private static void Fill(Color32[] px, int w, int x, int y, int rw, int rh, Color32 c)
        {
            int h = px.Length / w;
            for (int j = Mathf.Max(0, y); j < Mathf.Min(h, y + rh); j++)
            for (int i = Mathf.Max(0, x); i < Mathf.Min(w, x + rw); i++)
                px[j * w + i] = c;
        }

        private static void Border(Color32[] px, int w, int x, int y, int rw, int rh, int t, Color32 c)
        {
            Fill(px, w, x, y, rw, t, c);
            Fill(px, w, x, y + rh - t, rw, t, c);
            Fill(px, w, x, y, t, rh, c);
            Fill(px, w, x + rw - t, y, t, rh, c);
        }

        private static void Line(Color32[] px, int w, int x0, int y0, int x1, int y1, int t, Color32 c)
        {
            int steps = Mathf.Max(Mathf.Abs(x1 - x0), Mathf.Abs(y1 - y0), 1);
            for (int s = 0; s <= steps; s++)
            {
                int x = x0 + (x1 - x0) * s / steps, y = y0 + (y1 - y0) * s / steps;
                Fill(px, w, x - t / 2, y - t / 2, t, t, c);
            }
        }
    }
}
