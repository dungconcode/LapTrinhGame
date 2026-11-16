using UnityEngine;
using Underlab.Core;
using Underlab.Player;

namespace Underlab.Mining
{
    /// <summary>
    /// HUD tạm để test phần đào (chỉ hiện trong Editor). HUD thật là task A09.
    /// </summary>
    public class MiningDebugHud : MonoBehaviour
    {
        [SerializeField] private PlayerController player;
        [SerializeField] private Carrier carrier;

#if UNITY_EDITOR
        private GUIStyle style;

        private void OnGUI()
        {
            if (player == null || carrier == null) return;
            if (style == null)
                style = new GUIStyle(GUI.skin.box) { alignment = TextAnchor.UpperLeft, fontSize = 16, richText = true };

            string text =
                $"<b>Độ sâu</b>: {player.Depth} ô\n" +
                $"<b>Tải</b>: {carrier.Weight:0.#}/{carrier.MaxWeight:0.#}  ({carrier.Load01:P0})\n" +
                $"<b>Tốc độ</b> x{player.SpeedMultiplier:0.00}   <b>Jetpack</b> x{player.ThrustMultiplier:0.00}\n" +
                $"Sắt {carrier.Get(ResourceType.Iron)} · S {carrier.Get(ResourceType.Sulfur)} · " +
                $"Mg {carrier.Get(ResourceType.Magnesium)} · KCl {carrier.Get(ResourceType.KCl)}";
            GUI.Box(new Rect(10, 10, 340, 100), text, style);
        }
#endif
    }
}
