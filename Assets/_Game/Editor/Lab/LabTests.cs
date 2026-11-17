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

        [MenuItem("Underlab/Lab/Test Ice + Acid Scoring", priority = 502)]
        public static void IceAcidScoring()
        {
            var cfg = ScriptableObject.CreateInstance<LabConfig>();
            var log = new StringBuilder("[LabTest] Ice + Acid scoring\n");
            bool ok = true;

            // --- Băng: 200 g nước cần 68.4 g KCl (độ tan 34.2 g/100 g)
            float w = 200f, need = cfg.kclSolubility * w;
            var r = IceExperiment.Evaluate(need, w, need, cfg);
            ok &= Check(log, r.outcome == IceExperiment.Outcome.Ok && Mathf.Abs(r.eff - 1f) < 0.001f, $"KCl bão hoà đúng, tan hết => đạt 100% (cần {need:0.0} g)");
            r = IceExperiment.Evaluate(need * 1.08f, w, need, cfg);
            ok &= Check(log, r.outcome == IceExperiment.Outcome.Supersaturated, "thừa KCl 8% => QUÁ BÃO HOÀ, thất bại");
            r = IceExperiment.Evaluate(need * 0.9f, w, need * 0.9f, cfg);
            ok &= Check(log, r.outcome == IceExperiment.Outcome.Unsaturated, "thiếu KCl 10% => CHƯA BÃO HOÀ, thất bại");
            r = IceExperiment.Evaluate(need, w, need * 0.5f, cfg);
            ok &= Check(log, r.outcome == IceExperiment.Outcome.NotDissolved, "đúng lượng nhưng mới tan 50% => CHƯA TAN HẾT, thất bại");
            float t = IceExperiment.SolutionTemp(need, w, cfg);
            ok &= Check(log, t < 25f && t > 0f, $"hoà tan thu nhiệt: nhiệt độ tụt còn {t:0.0} °C");

            // --- Axit: tỉ lệ khí
            float vm = cfg.gasMolarVolume;
            var a = AcidExperiment.Evaluate(1f, 1f * vm, 1f, cfg);
            ok &= Check(log, a.ok, "S + O₂ (1 : 1) đúng => đạt");
            a = AcidExperiment.Evaluate(1f, 0.5f * vm, 1f, cfg);
            ok &= Check(log, !a.ok, "đốt S thiếu nửa O₂ => thất bại");
            a = AcidExperiment.Evaluate(2f, 1f * vm, 0.5f, cfg);
            ok &= Check(log, a.ok, "2SO₂ + O₂ (2 mol SO₂ cần 1 mol O₂) => đạt");
            a = AcidExperiment.Evaluate(2f, 2f * vm, 0.5f, cfg);
            ok &= Check(log, !a.ok, "2 mol SO₂ nạp 2 mol O₂ (quên cân bằng) => thất bại");

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
