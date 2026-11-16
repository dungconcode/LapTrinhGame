using UnityEngine;
using Underlab.Art;
using Underlab.Core;

namespace Underlab.Mining
{
    /// <summary>
    /// Phản hồi hình ảnh cho túi quặng:
    ///  - "+1 Sắt" bay lên mỗi lần nhặt
    ///  - "TÚI ĐẦY" nhấp nháy trên đầu khi không nhặt thêm được
    /// </summary>
    [RequireComponent(typeof(Carrier))]
    public class CarrierFeedback : MonoBehaviour
    {
        [SerializeField] private Vector3 textOffset = new Vector3(0f, 1.1f, 0f);
        [SerializeField] private float blinkSpeed = 4f;

        private Carrier carrier;
        private TextMesh fullLabel;

        public static string DisplayName(ResourceType t)
        {
            switch (t)
            {
                case ResourceType.Iron: return "Sắt";
                case ResourceType.Sulfur: return "Lưu huỳnh";
                case ResourceType.Magnesium: return "Mg";
                case ResourceType.KCl: return "KCl";
                default: return t.ToString();
            }
        }

        public static Color DisplayColor(ResourceType t)
        {
            switch (t)
            {
                case ResourceType.Iron: return new Color(1f, 0.6f, 0.45f);
                case ResourceType.Sulfur: return new Color(1f, 0.92f, 0.3f);
                case ResourceType.Magnesium: return new Color(0.92f, 0.92f, 1f);
                case ResourceType.KCl: return new Color(1f, 0.75f, 0.85f);
                default: return Color.white;
            }
        }

        private void Awake()
        {
            carrier = GetComponent<Carrier>();
            fullLabel = FloatingText.CreateLabel("TÚI ĐẦY", transform.position + textOffset, new Color(1f, 0.35f, 0.3f), 0.8f);
            fullLabel.transform.SetParent(transform, true);
            fullLabel.gameObject.SetActive(false);
        }

        private void OnEnable() => carrier.PickedUp += OnPickedUp;
        private void OnDisable() => carrier.PickedUp -= OnPickedUp;

        private void OnPickedUp(ResourceType type, int amount)
        {
            FloatingText.Spawn($"+{amount} {DisplayName(type)}", transform.position + textOffset, DisplayColor(type));
        }

        private void Update()
        {
            bool full = carrier.IsFull;
            if (fullLabel.gameObject.activeSelf != full) fullLabel.gameObject.SetActive(full);
            if (!full) return;

            var c = fullLabel.color;
            c.a = 0.55f + 0.45f * Mathf.Sin(Time.time * blinkSpeed * Mathf.PI);
            fullLabel.color = c;
        }
    }
}
