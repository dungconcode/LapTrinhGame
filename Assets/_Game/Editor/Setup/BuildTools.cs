using System.IO;
using System.Linq;
using System.Text;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

namespace Underlab.EditorTools
{
    /// <summary>
    /// Build Windows 1 nút. Kết quả: Builds/Windows/Underlab.exe, báo cáo: Logs/BuildReport.txt.
    /// Scene lấy từ Build Settings (Game.unity phải đứng đầu).
    /// </summary>
    public static class BuildTools
    {
        private const string OutDir = "Builds/Windows";
        private const string ReportPath = "Logs/BuildReport.txt";

        [MenuItem("Underlab/Build/Windows", priority = 400)]
        public static void BuildWindows() => Build(false);

        [MenuItem("Underlab/Build/Windows (Development + log)", priority = 401)]
        public static void BuildWindowsDev() => Build(true);

        private static void Build(bool development)
        {
            var scenes = EditorBuildSettings.scenes.Where(s => s.enabled).Select(s => s.path).ToArray();
            var sb = new StringBuilder();
            if (scenes.Length == 0 || !scenes[0].EndsWith("Game.unity"))
            {
                sb.AppendLine("FAIL: Build Settings phải có Assets/_Game/Scenes/Game.unity ở vị trí đầu.");
                Write(sb);
                return;
            }

            Directory.CreateDirectory(OutDir);
            var options = new BuildPlayerOptions
            {
                scenes = scenes,
                locationPathName = Path.Combine(OutDir, "Underlab.exe"),
                target = BuildTarget.StandaloneWindows64,
                options = development ? BuildOptions.Development : BuildOptions.None,
            };

            var report = BuildPipeline.BuildPlayer(options);
            var s = report.summary;
            sb.AppendLine($"{(s.result == BuildResult.Succeeded ? "PASS" : "FAIL")} {s.result}");
            sb.AppendLine($"Thời gian: {s.totalTime:mm\\:ss}  ·  Dung lượng: {s.totalSize / (1024f * 1024f):0.0} MB  ·  Lỗi: {s.totalErrors}  ·  Cảnh báo: {s.totalWarnings}");
            sb.AppendLine($"Output: {Path.GetFullPath(options.locationPathName)}");
            sb.AppendLine($"Scenes: {string.Join(", ", scenes)}");
            foreach (var step in report.steps)
            foreach (var m in step.messages)
                if (m.type == LogType.Error || m.type == LogType.Exception)
                    sb.AppendLine($"[{m.type}] {m.content}");
            Write(sb);
        }

        private static void Write(StringBuilder sb)
        {
            Directory.CreateDirectory(Path.GetDirectoryName(ReportPath));
            File.WriteAllText(ReportPath, sb.ToString());
            Debug.Log("[Build] " + sb);
        }
    }
}
