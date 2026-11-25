using System.Collections.Generic;
using Underlab.Art;
using Underlab.Player;
using UnityEngine;

namespace Underlab.Mining
{
    public sealed class DomeHatch : MonoBehaviour
    {
        private const float SlideSeconds = .2f;
        private const float ClearanceMargin = .025f;
        private const float SensorHeight = .65f;
        private static readonly Vector3 ClosedLeafPosition = new Vector3(0f, .203125f, 0f);

        private readonly List<Collider2D> overlaps = new List<Collider2D>();
        private PlayerController player;
        private CapsuleCollider2D playerCollider;
        private BoxCollider2D floor, sensor;
        private Transform left, right;
        private float slide, openDistance;

        private void Initialize(float width, float thickness)
        {
            floor = Part<BoxCollider2D>("HatchFloorCollider");
            floor.transform.localPosition = Vector3.down * (thickness * .5f);
            floor.size = new Vector2(width, thickness);
            floor.isTrigger = false;
            floor.enabled = true;

            sensor = Part<BoxCollider2D>("HatchAscentSensor");
            sensor.transform.localPosition = Vector3.down * (thickness + SensorHeight * .5f);
            sensor.size = new Vector2(width, SensorHeight);
            sensor.isTrigger = true;

            left = BuildLeaf("DomeHatch_Left");
            right = BuildLeaf("DomeHatch_Right");
            openDistance = width * .5f;
            slide = 0f;
        }

        private void Start()
        {
            TerrainGenerator terrain = null;
            foreach (var root in gameObject.scene.GetRootGameObjects())
            {
                if (!terrain) terrain = root.GetComponentInChildren<TerrainGenerator>();
                if (!player) player = root.GetComponent<PlayerController>();
            }
            if (!terrain || !terrain.Config.carveBaseEntrance) return;
            if (player) playerCollider = player.GetComponent<CapsuleCollider2D>();
            gameObject.layer = terrain.Tilemap.gameObject.layer;
            transform.position = terrain.Tilemap.transform.TransformPoint(Vector3.right * terrain.Config.entranceCenterX);
            Initialize(terrain.EntranceOpeningWidth, Mathf.Max(.01f, terrain.Config.entranceFloorThickness));
        }

        private void FixedUpdate()
        {
            if (!floor) return;
            if (!playerCollider || !playerCollider.isActiveAndEnabled || !player.isActiveAndEnabled)
            {
                floor.enabled = true;
                return;
            }

            var body = playerCollider.bounds;
            float surface = transform.position.y;
            float halfWidth = floor.size.x * Mathf.Abs(transform.lossyScale.x) * .5f;
            bool fits = Mathf.Abs(body.center.x - transform.position.x) + body.extents.x <= halfWidth;
            bool wantsDown = fits && player.IsGrounded && !player.IsThrusting && player.MoveInput.y < -.5f &&
                body.min.y >= surface - ClearanceMargin && body.min.y <= surface + .08f;
            bool wantsUp = fits && player.IsThrusting && body.min.y < surface &&
                PlayerOverlaps(sensor.transform.localPosition, sensor.size);

            // Đỡ chân ngay khi khe đã trống, kể cả lúc hai cánh còn đang trượt về.
            bool occupied = !floor.enabled && PlayerOverlaps(floor.transform.localPosition,
                floor.size + Vector2.up * (2f * ClearanceMargin));
            floor.enabled = !(wantsDown || wantsUp || occupied);
        }

        private bool PlayerOverlaps(Vector2 center, Vector2 size)
        {
            var filter = new ContactFilter2D { useTriggers = false };
            filter.SetLayerMask(1 << playerCollider.gameObject.layer);
            Vector2 scale = transform.lossyScale;
            size = Vector2.Scale(size, new Vector2(Mathf.Abs(scale.x), Mathf.Abs(scale.y)));
            Physics2D.OverlapBox(transform.TransformPoint(center), size, transform.eulerAngles.z, filter, overlaps);
            return overlaps.Contains(playerCollider);
        }

        private void Update()
        {
            if (!floor) return;
            slide = Mathf.MoveTowards(slide, floor.enabled ? 0f : 1f, Time.deltaTime / SlideSeconds);
            var offset = Vector3.right * (slide * openDistance);
            left.localPosition = ClosedLeafPosition - offset;
            right.localPosition = ClosedLeafPosition + offset;
        }

        private Transform BuildLeaf(string id)
        {
            var leaf = Part<SpriteRenderer>(id);
            leaf.sprite = ArtDatabase.GetSprite(id);
            if (player && player.TryGetComponent<SpriteRenderer>(out var playerRenderer))
                leaf.sortingLayerID = playerRenderer.sortingLayerID;
            leaf.sortingOrder = 9;
            leaf.transform.localPosition = ClosedLeafPosition;
            return leaf.transform;
        }

        private T Part<T>(string partName) where T : Component
        {
            var part = transform.Find(partName);
            if (part) return part.GetComponent<T>();
            var child = new GameObject(partName, typeof(T));
            child.layer = gameObject.layer;
            child.transform.SetParent(transform, false);
            return child.GetComponent<T>();
        }
    }
}
