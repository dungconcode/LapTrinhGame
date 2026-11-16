using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.U2D.Sprites;
using UnityEngine;

namespace Underlab.EditorTools.Art
{
    /// <summary>
    /// Mọi PNG trong Assets/_Game/Art có tên trùng 1 id trong manifest sẽ được tự cấu hình:
    ///  - Sprite, không mipmap, Bilinear (style vẽ tay)
    ///  - Pixels Per Unit = (độ rộng 1 frame) / world_w  => ảnh 64px hay 2048px đều hiện CÙNG KÍCH THƯỚC trong game
    ///  - Pivot theo manifest
    ///  - frames > 1: tự cắt dải ngang thành N frame tên id_0..id_N-1
    /// Vì vậy thay art chỉ cần chép đè file PNG cùng tên. Không cần chỉnh gì trong Unity.
    /// </summary>
    public class ArtImportPostprocessor : AssetPostprocessor
    {
        private void OnPreprocessTexture()
        {
            if (!ArtManifest.TryGetForAsset(assetPath, out var e)) return;
            var ti = (TextureImporter)assetImporter;

            if (!ArtManifest.TryReadPngSize(assetPath, out int w, out int h))
            {
                Debug.LogWarning($"[Art] Không đọc được kích thước PNG: {assetPath}");
                return;
            }
            if (w % e.frames != 0)
                Debug.LogWarning($"[Art] {e.id}: rộng {w}px không chia hết cho {e.frames} frame. " +
                                 "Ảnh phải là DẢI NGANG các frame bằng nhau.");

            int frameW = Mathf.Max(1, w / e.frames);
            var pivot = ArtManifest.PivotOf(e);

            ti.textureType = TextureImporterType.Sprite;
            ti.spriteImportMode = e.frames > 1 ? SpriteImportMode.Multiple : SpriteImportMode.Single;
            ti.spritePixelsPerUnit = e.IsUi ? 100f : frameW / e.worldW;
            ti.mipmapEnabled = false;
            ti.alphaIsTransparency = true;
            ti.filterMode = FilterMode.Bilinear;
            ti.wrapMode = TextureWrapMode.Clamp;
            ti.maxTextureSize = NextPow2(Mathf.Max(w, h));

            var settings = new TextureImporterSettings();
            ti.ReadTextureSettings(settings);
            settings.spriteMeshType = SpriteMeshType.FullRect;
            settings.spriteAlignment = (int)SpriteAlignment.Custom;
            settings.spritePivot = pivot;
            settings.spriteExtrude = e.type == "tile" ? 0u : 1u;
            // 9-slice: viền khai báo theo kích thước spec => quy đổi theo kích thước ảnh thật.
            var border = e.BorderPx;
            if (e.frames == 1 && border != Vector4.zero)
            {
                float sx = e.specW > 0 ? (float)w / e.specW : 1f, sy = e.specH > 0 ? (float)h / e.specH : 1f;
                settings.spriteBorder = new Vector4(border.x * sx, border.y * sy, border.z * sx, border.w * sy);
            }
            ti.SetTextureSettings(settings);

            if (e.frames > 1) SliceStrip(ti, e, h, frameW, pivot);
        }

        private static void SliceStrip(TextureImporter ti, ArtEntry e, int h, int frameW, Vector2 pivot)
        {
            var factory = new SpriteDataProviderFactories();
            factory.Init();
            var dp = factory.GetSpriteEditorDataProviderFromObject(ti);
            dp.InitSpriteEditorDataProvider();

            // Giữ nguyên spriteID cũ theo tên => tham chiếu cũ không bị gãy.
            var oldIds = new Dictionary<string, GUID>();
            foreach (var r in dp.GetSpriteRects()) oldIds[r.name] = r.spriteID;

            var rects = new SpriteRect[e.frames];
            var pairs = new List<SpriteNameFileIdPair>();
            for (int i = 0; i < e.frames; i++)
            {
                var name = $"{e.id}_{i}";
                rects[i] = new SpriteRect
                {
                    name = name,
                    rect = new Rect(i * frameW, 0, frameW, h),
                    alignment = SpriteAlignment.Custom,
                    pivot = pivot,
                    spriteID = oldIds.TryGetValue(name, out var id) ? id : GUID.Generate(),
                };
                pairs.Add(new SpriteNameFileIdPair(name, rects[i].spriteID));
            }

            dp.SetSpriteRects(rects);
            dp.GetDataProvider<ISpriteNameFileIdDataProvider>()?.SetNameFileIdPairs(pairs);
            dp.Apply();
        }

        private static void OnPostprocessAllAssets(string[] imported, string[] deleted, string[] moved, string[] movedFrom)
        {
            bool artChanged = false, manifestChanged = false;
            foreach (var list in new[] { imported, deleted, moved, movedFrom })
            foreach (var p in list)
            {
                var path = p.Replace('\\', '/');
                if (path.Equals(ArtManifest.ManifestPath, StringComparison.OrdinalIgnoreCase)) manifestChanged = true;
                else if (path.StartsWith(ArtManifest.ArtRoot, StringComparison.OrdinalIgnoreCase) &&
                         path.EndsWith(".png", StringComparison.OrdinalIgnoreCase)) artChanged = true;
            }

            if (manifestChanged)
            {
                // Sửa frames / world_w / pivot / type trong CSV => reimport đúng các PNG bị ảnh hưởng.
                var changedIds = ArtManifest.DiffSignatures();
                if (changedIds.Count > 0) EditorApplication.delayCall += () => ReimportIds(changedIds);
            }
            if (artChanged || manifestChanged) ArtDatabaseBuilder.Schedule();
        }

        private static void ReimportIds(List<string> ids)
        {
            var set = new HashSet<string>(ids, StringComparer.OrdinalIgnoreCase);
            foreach (var guid in AssetDatabase.FindAssets("t:Texture2D", new[] { ArtManifest.ArtRoot.TrimEnd('/') }))
            {
                var path = AssetDatabase.GUIDToAssetPath(guid);
                if (set.Contains(Path.GetFileNameWithoutExtension(path)))
                    AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate);
            }
            Debug.Log($"[Art] Spec đổi trong manifest => đã reimport: {string.Join(", ", ids)}");
        }

        private static int NextPow2(int v)
        {
            int p = 32;
            while (p < v && p < 8192) p <<= 1;
            return p;
        }
    }
}
