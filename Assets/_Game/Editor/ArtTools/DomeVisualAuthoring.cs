using System;
using Underlab.Defense;
using Underlab.Mining;
using UnityEditor;
using UnityEngine;

namespace Underlab.EditorTools.Art
{
    public static class DomeVisualAuthoring
    {
        public static void InstallHatch(Transform dome)
        {
            if (dome.Find("DomeHatch")) return;
            var hatch = new GameObject("DomeHatch", typeof(DomeHatch));
            hatch.transform.SetParent(dome, false);
        }

        [MenuItem("Underlab/Art/Update Layered Dome Prefab")]
        public static void UpdatePrefab()
        {
            if (EditorApplication.isPlaying) throw new InvalidOperationException("Stop Play Mode trước khi cập nhật prefab.");
            const string path = "Assets/_Game/Prefabs/Defense/DefenseRoot.prefab";
            var root = PrefabUtility.LoadPrefabContents(path);
            try
            {
                var health = root.GetComponentInChildren<BaseHealth>(true);
                if (!health) throw new InvalidOperationException("DefenseRoot không có BaseHealth.");
                var dome = health.GetComponent<DomeVisual>();
                if (!dome) dome = health.gameObject.AddComponent<DomeVisual>();
                dome.Initialize();
                InstallHatch(health.transform);
                foreach (var renderer in root.GetComponentsInChildren<SpriteRenderer>(true))
                    renderer.sprite = null;
                PrefabUtility.SaveAsPrefabAsset(root, path);
            }
            finally { PrefabUtility.UnloadPrefabContents(root); }
            Debug.Log("[Dome] Đã cập nhật prefab hai tầng với kính và overlay nứt độc lập.");
        }
    }
}
