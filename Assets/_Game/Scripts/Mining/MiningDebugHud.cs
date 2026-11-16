using System.Collections.Generic;
using UnityEngine;
using Underlab.Core;
using Underlab.Player;

namespace Underlab.Mining
{
    /// <summary>
    /// HUD tạm để test phần đào (chỉ hiện trong Editor). HUD thật là task A09.
    /// "Kho (debug)" đếm từ event ResourcesDeposited — thay bằng ResourceBank (B06) khi Dev B xong.
    /// </summary>
    public class MiningDebugHud : MonoBehaviour
    {
        [SerializeField] private PlayerController player;
        [SerializeField] private Carrier carrier;

        private readonly Dictionary<ResourceType, int> bank = new Dictionary<ResourceType, int>();
        private bool atBase;

        private void OnEnable()
        {
            GameEvents.ResourcesDeposited += OnDeposited;
            GameEvents.PlayerAtBaseChanged += OnAtBase;
        }

        private void OnDisable()
        {
            GameEvents.ResourcesDeposited -= OnDeposited;
            GameEvents.PlayerAtBaseChanged -= OnAtBase;
        }

        private void OnDeposited(ResourceType t, int n) => bank[t] = Bank(t) + n;
        private void OnAtBase(bool v) => atBase = v;
        private int Bank(ResourceType t) => bank.TryGetValue(t, out var n) ? n : 0;

#if UNITY_EDITOR
        private GUIStyle style;

        private void OnGUI()
        {
            if (player == null || carrier == null) return;
            if (style == null)
                style = new GUIStyle(GUI.skin.box) { alignment = TextAnchor.UpperLeft, fontSize = 16, richText = true };

            string text =
                $"<b>Độ sâu</b>: {player.Depth} ô {(atBase ? "  <color=#7f7>[Ở BASE]</color>" : "")}\n" +
                $"<b>Tải</b>: {carrier.Weight:0.#}/{carrier.MaxWeight:0.#}  ({carrier.Load01:P0})\n" +
                $"<b>Tốc độ</b> x{player.SpeedMultiplier:0.00}   <b>Jetpack</b> x{player.ThrustMultiplier:0.00}\n" +
                $"<b>Túi</b>: Sắt {carrier.Get(ResourceType.Iron)} · S {carrier.Get(ResourceType.Sulfur)} · " +
                $"Mg {carrier.Get(ResourceType.Magnesium)} · KCl {carrier.Get(ResourceType.KCl)}\n" +
                $"<b>Kho (debug)</b>: Sắt {Bank(ResourceType.Iron)} · S {Bank(ResourceType.Sulfur)} · " +
                $"Mg {Bank(ResourceType.Magnesium)} · KCl {Bank(ResourceType.KCl)}";
            GUI.Box(new Rect(10, 10, 380, 125), text, style);
        }
#endif
    }
}
