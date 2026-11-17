using System.Text;
using UnityEditor;
using UnityEngine;
using Underlab.Core;
using Underlab.Lab;

namespace Underlab.EditorTools.Lab
{
    public static class LabTests
    {
        /// <summary>Kiểm tra phần chấm điểm thí nghiệm đạn lửa (chạy ở edit mode, không cần Play).</summary>
        [MenuItem("Underlab/Lab/Test Fire Scoring", priority = 500)]
        public static void FireScoring()
        {
            var cfg = ScriptableObject.CreateInstance<LabConfig>();
            var log = new StringBuilder("[LabTest] Fire scoring\n");
            bool ok = true;
            float m = 2f * Chem.Mg;                         // 2 mol Mg
            float exact = 1f * cfg.gasMolarVolume;          // cần 1 mol O₂

            var r = FireExperiment.Evaluate(m, exact, cfg);
            ok &= Check(log, r.ok && Mathf.Abs(r.eff - 1f) < 0.001f, $"đúng tỉ lệ 2:1 => đạt, hiệu suất 100% (được {r.eff:P0})");
            r = FireExperiment.Evaluate(m, exact * 1.04f, cfg);
            ok &= Check(log, r.ok && r.eff < 1f && r.eff > cfg.efficiencyAtTolerance, $"thừa O₂ 4% => vẫn đạt, hiệu suất giảm ({r.eff:P0})");
            r = FireExperiment.Evaluate(m, exact * 0.96f, cfg);
            ok &= Check(log, r.ok, "thiếu O₂ 4% => vẫn đạt");
            r = FireExperiment.Evaluate(m, exact * 1.06f, cfg);
            ok &= Check(log, !r.ok, "thừa O₂ 6% => THẤT BẠI");
            r = FireExperiment.Evaluate(m, exact * 0.5f, cfg);
            ok &= Check(log, !r.ok, "chỉ nạp nửa lượng O₂ cần => THẤT BẠI");
            r = FireExperiment.Evaluate(m, exact * 2f, cfg);
            ok &= Check(log, !r.ok, "nhầm tỉ lệ Mg:O₂ = 1:1 => THẤT BẠI");
            r = FireExperiment.Evaluate(m, 0f, cfg);
            ok &= Check(log, !r.ok && r.noOxygen, "không có O₂ => THẤT BẠI (không cháy)");
            ok &= Check(log, Chem.F("O2") == "O<sub>2</sub>" && Chem.F("2MgO") == "2MgO", "viết công thức có chỉ số dưới");

            Object.DestroyImmediate(cfg);
            log.Insert(0, ok ? "PASS " : "FAIL ");
            if (ok) Debug.Log(log.ToString()); else Debug.LogError(log.ToString());
        }

        /// <summary>Mở phòng thí nghiệm trong Play Mode để kiểm tra giao diện dựng không lỗi.</summary>
        [MenuItem("Underlab/Lab/Open Lab (Play Mode)", priority = 501)]
        public static void OpenLab()
        {
            if (!EditorApplication.isPlaying) { Debug.LogError("[LabTest] Bấm Play trước."); return; }
            foreach (var mb in Object.FindObjectsByType<MonoBehaviour>(FindObjectsSortMode.None))
                if (mb.GetType().Name == "GameManager") mb.GetType().GetMethod("StartRun")?.Invoke(mb, null);
            GameEvents.RaisePlayerAtBaseChanged(true);
            GameEvents.RaiseResourcesDeposited(ResourceType.Magnesium, 4);
            var station = Object.FindFirstObjectByType<LabStation>();
            if (station == null) { Debug.LogError("[LabTest] Không có LabStation trong scene."); return; }
            station.SetOpen(true);
            Debug.Log($"[LabTest] Đã mở phòng thí nghiệm. IsOpen={LabStation.IsOpen}");
        }

        private static bool Check(StringBuilder log, bool cond, string what)
        {
            log.AppendLine($"  {(cond ? "OK " : "XX ")} {what}");
            return cond;
        }
    }
}
