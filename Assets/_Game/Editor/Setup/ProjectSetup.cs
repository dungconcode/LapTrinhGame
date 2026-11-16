using System.IO;
using UnityEditor;
using UnityEngine;

namespace Underlab.EditorTools
{
    public static class ProjectSetup
    {
        private const string TmpPackage = "Packages/com.unity.ugui/Package Resources/TMP Essential Resources.unitypackage";

        /// <summary>
        /// TextMeshPro cần "TMP Essential Resources" (TMP Settings, shader, font mặc định) trong Assets.
        /// Thiếu => mọi chữ TMP lỗi NullReference ở TMP_Settings. Lệnh này import không cần bấm hộp thoại.
        /// </summary>
        [MenuItem("Underlab/Setup/Import TMP Essential Resources", priority = 300)]
        public static void ImportTmpEssentials()
        {
            if (File.Exists("Assets/TextMesh Pro/Resources/TMP Settings.asset"))
            {
                Debug.Log("[Setup] TMP Essential Resources đã có.");
                return;
            }
            AssetDatabase.ImportPackage(TmpPackage, false);
            Debug.Log("[Setup] Đã import TMP Essential Resources.");
        }
    }
}
