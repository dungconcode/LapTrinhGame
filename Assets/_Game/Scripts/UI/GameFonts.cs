using TMPro;
using UnityEngine;

namespace Underlab.UI
{
    /// <summary>
    /// Font dùng chung cho toàn game (Roboto Bold, có đủ dấu tiếng Việt).
    ///   GameFonts.Main     — cho UnityEngine.UI.Text và TextMesh
    ///   GameFonts.MainTMP  — cho TextMeshPro (tạo 1 lần, dùng lại)
    /// Không dùng LegacyRuntime.ttf cho TMP: font đó không có dữ liệu nét => TMP báo lỗi, chữ không hiện.
    /// </summary>
    public static class GameFonts
    {
        private static Font main;
        private static TMP_FontAsset mainTmp;

        public static Font Main
        {
            get
            {
                if (main == null) main = Resources.Load<Font>("Fonts/Roboto-Bold");
                if (main == null) main = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf"); // dự phòng
                return main;
            }
        }

        public static TMP_FontAsset MainTMP
        {
            get
            {
                if (mainTmp == null && Main != null)
                {
                    mainTmp = TMP_FontAsset.CreateFontAsset(Main);
                    // Roboto thiếu mũi tên "→" (cần cho phương trình hoá học) => lấy từ LiberationSans (đi kèm TMP)
                    var fallback = Resources.Load<TMP_FontAsset>("Fonts & Materials/LiberationSans SDF - Fallback");
                    if (mainTmp != null && fallback != null)
                    {
                        if (mainTmp.fallbackFontAssetTable == null)
                            mainTmp.fallbackFontAssetTable = new System.Collections.Generic.List<TMP_FontAsset>();
                        mainTmp.fallbackFontAssetTable.Add(fallback);
                    }
                }
                return mainTmp;
            }
        }
    }
}
