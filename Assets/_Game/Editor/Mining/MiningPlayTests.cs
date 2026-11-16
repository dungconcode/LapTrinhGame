using System.Collections;
using System.Text;
using UnityEditor;
using UnityEngine;
using Underlab.Core;
using Underlab.Mining;

namespace Underlab.EditorTools.Mining
{
    /// <summary>
    /// Test nhanh trong Play Mode (chạy được qua menu, không cần bấm phím).
    /// Kết quả in ra Console với tiền tố [MiningTest] PASS/FAIL.
    /// </summary>
    public static class MiningPlayTests
    {
        [MenuItem("Underlab/Mining/Test Ore Pickup (Play Mode)", priority = 200)]
        public static void OrePickup()
        {
            if (!EditorApplication.isPlaying) { Debug.LogError("[MiningTest] Phải bấm Play trước."); return; }
            var carrier = Object.FindFirstObjectByType<Carrier>();
            if (carrier == null) { Debug.LogError("[MiningTest] Không tìm thấy Carrier/Player."); return; }
            // Chạy coroutine trên object khác: tắt Player sẽ dừng coroutine gắn trên Player.
            var runner = Object.FindFirstObjectByType<TerrainGenerator>();
            runner.StartCoroutine(Run(carrier));
        }

        private static IEnumerator Run(Carrier carrier)
        {
            var log = new StringBuilder("[MiningTest] Ore pickup\n");
            bool ok = true;
            var go = carrier.gameObject;
            var col = go.GetComponent<Collider2D>();
            carrier.TakeAll();
            // Game.unity dừng thời gian ở menu => gọi GameManager.StartRun() (qua reflection, không phụ thuộc code Dev B).
            foreach (var mb in Object.FindObjectsByType<MonoBehaviour>(FindObjectsSortMode.None))
                if (mb.GetType().Name == "GameManager") mb.GetType().GetMethod("StartRun")?.Invoke(mb, null);
            // Ra xa base để DepositZone không tự đổ quặng vào kho giữa chừng.
            go.transform.position = new Vector3(8.5f, 0.1f, 0f);
            yield return new WaitForSeconds(0.5f);

            // 1) Quặng rơi cạnh người, rồi tắt/bật Player (giống lên/xuống pháo) => vẫn phải nhặt được.
            for (int i = 0; i < 3; i++)
                Underlab.Mining.OrePickup.Spawn(ResourceType.Iron, 1, go.transform.position + new Vector3(0.8f + i * 0.3f, 0.6f, 0f), col, 0f, 0.1f);
            yield return null;
            go.SetActive(false);
            yield return null;
            go.SetActive(true);
            yield return new WaitForSeconds(2.5f);
            int iron = carrier.Get(ResourceType.Iron);
            ok &= Check(log, iron == 3, $"nhặt đủ 3 sắt sau khi tắt/bật player (được {iron})");
            ok &= Check(log, Object.FindObjectsByType<Underlab.Mining.OrePickup>(FindObjectsSortMode.None).Length == 0,
                "không còn cục quặng nào nằm lại");

            // 2) Túi gần đầy (còn chỗ nhưng < 1 cục) vẫn nhặt được.
            carrier.TakeAll();
            carrier.Add(ResourceType.Iron, 100); // đổ tới khi đầy
            carrier.Remove(ResourceType.Iron, 1);
            carrier.Add(ResourceType.KCl, 1);   // vd 9 + 1.2 = 10.2 => đầy
            carrier.Remove(ResourceType.Iron, 1); // còn 9.2/10: chỗ trống 0.8 < 1 cục sắt
            float before = carrier.Weight;
            int got = carrier.Add(ResourceType.Iron, 1);
            ok &= Check(log, got == 1, $"túi {before:0.#}/{carrier.MaxWeight:0.#} vẫn nhặt được 1 sắt");
            ok &= Check(log, carrier.IsFull, "sau đó báo TÚI ĐẦY");

            carrier.TakeAll();
            log.Insert(0, ok ? "PASS " : "FAIL ");
            if (ok) Debug.Log(log.ToString()); else Debug.LogError(log.ToString());
        }

        private static bool Check(StringBuilder log, bool cond, string what)
        {
            log.AppendLine($"  {(cond ? "OK " : "XX ")} {what}");
            return cond;
        }
    }
}
