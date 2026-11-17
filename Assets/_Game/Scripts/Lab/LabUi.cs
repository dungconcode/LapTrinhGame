using TMPro;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.UI;
using Underlab.Art;
using Underlab.UI;

namespace Underlab.Lab
{
    /// <summary>Hàm dựng uGUI + đọc chuột dùng chung cho phòng thí nghiệm (khung 1280x720).</summary>
    public static class LabUi
    {
        public static readonly Color Teal = new Color(0.25f, 0.88f, 0.82f);
        public static readonly Color Gold = new Color(0.95f, 0.83f, 0.36f);
        public static readonly Color Red = new Color(1f, 0.35f, 0.29f);
        public static readonly Color Green = new Color(0.45f, 0.95f, 0.5f);
        public static readonly Color Dim = new Color(1f, 1f, 1f, 0.6f);

        public static RectTransform Rect(Transform parent, string name, Vector2 anchor, Vector2 pos, Vector2 size, Vector2? pivot = null)
        {
            var go = new GameObject(name, typeof(RectTransform));
            go.transform.SetParent(parent, false);
            var rt = (RectTransform)go.transform;
            rt.anchorMin = rt.anchorMax = anchor;
            rt.pivot = pivot ?? new Vector2(0, 1);
            rt.anchoredPosition = pos;
            rt.sizeDelta = size;
            return rt;
        }

        public static Image Img(Transform parent, string name, string artId, Vector2 anchor, Vector2 pos, Vector2 size,
                                Vector2? pivot = null, Color? color = null, bool sliced = false, float ppuMul = 1f)
        {
            var rt = Rect(parent, name, anchor, pos, size, pivot);
            var img = rt.gameObject.AddComponent<Image>();
            if (artId != null) img.sprite = ArtDatabase.GetSprite(artId);
            if (color.HasValue) img.color = color.Value;
            if (sliced) { img.type = Image.Type.Sliced; img.pixelsPerUnitMultiplier = ppuMul; }
            img.raycastTarget = false;
            return img;
        }

        public static TextMeshProUGUI Txt(Transform parent, string name, string text, float size, Color color,
                                          TextAlignmentOptions align, Vector2 anchor, Vector2 pos, Vector2 box, Vector2? pivot = null)
        {
            var rt = Rect(parent, name, anchor, pos, box, pivot);
            var t = rt.gameObject.AddComponent<TextMeshProUGUI>();
            t.font = GameFonts.MainTMP;
            t.fontSize = size;
            t.color = color;
            t.alignment = align;
            t.richText = true;
            t.raycastTarget = false;
            t.text = text;
            return t;
        }

        public static Button Btn(Transform parent, string label, Vector2 anchor, Vector2 pos, Vector2 size,
                                 UnityEngine.Events.UnityAction onClick, Vector2? pivot = null, float fontSize = 18f)
        {
            var img = Img(parent, label, "ui_button", anchor, pos, size, pivot, null, true, 2.5f);
            img.raycastTarget = true;
            var b = img.gameObject.AddComponent<Button>();
            b.targetGraphic = img;
            var c = b.colors;
            c.highlightedColor = new Color(1.15f, 1.15f, 1.15f);
            c.pressedColor = new Color(0.75f, 0.75f, 0.8f);
            c.disabledColor = new Color(0.45f, 0.45f, 0.5f, 0.8f);
            c.colorMultiplier = 1.2f;
            b.colors = c;
            b.onClick.AddListener(onClick);
            Txt(img.transform, "Label", label, fontSize, Color.white, TextAlignmentOptions.Center,
                new Vector2(0.5f, 0.5f), Vector2.zero, size, new Vector2(0.5f, 0.5f));
            return b;
        }

        public static void SetLabel(Button b, string text) => b.GetComponentInChildren<TextMeshProUGUI>().text = text;

        // ---------------- chuột ----------------
        public static Vector2 MousePos => Mouse.current != null ? Mouse.current.position.ReadValue() : Vector2.zero;
        public static bool Over(RectTransform rt) => RectTransformUtility.RectangleContainsScreenPoint(rt, MousePos, null);
        public static bool LeftDown => Mouse.current != null && Mouse.current.leftButton.wasPressedThisFrame;
        public static bool LeftHeld => Mouse.current != null && Mouse.current.leftButton.isPressed;
        public static bool RightDown => Mouse.current != null && Mouse.current.rightButton.wasPressedThisFrame;
        public static bool Shift => Keyboard.current != null && Keyboard.current.shiftKey.isPressed;
    }
}
