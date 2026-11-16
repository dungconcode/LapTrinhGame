using System.Collections.Generic;
using Underlab.Art;
using UnityEngine;

namespace Underlab.Defense
{
    public class CombatPool : MonoBehaviour
    {
        public DefenseConfig config;
        public BaseHealth target;
        public DefenseAudio audioFx;
        public readonly List<Enemy> Enemies = new List<Enemy>();
        private readonly List<Projectile> projectiles = new List<Projectile>();
        public Enemy Spawn(EnemyKind kind, Vector3 position, float healthScale = 1, float speedScale = 1)
        {
            var enemy = Enemies.Find(e => !e.gameObject.activeSelf);
            if (!enemy)
            {
                var go = new GameObject("Enemy", typeof(SpriteRenderer), typeof(ArtSprite));
                go.transform.SetParent(transform);
                go.GetComponent<SpriteRenderer>().sortingOrder = 12;
                enemy = go.AddComponent<Enemy>();
                Enemies.Add(enemy);
            }
            enemy.transform.position = position;
            enemy.Initialize(this, kind, healthScale, speedScale);
            enemy.gameObject.SetActive(true);
            return enemy;
        }
        public void Shoot(Vector3 position, Vector3 direction, float damage, int ammoIndex, bool hostile)
        {
            var projectile = projectiles.Find(p => !p.gameObject.activeSelf);
            if (!projectile)
            {
                var go = new GameObject("Projectile", typeof(SpriteRenderer), typeof(ArtSprite));
                go.transform.SetParent(transform);
                go.GetComponent<SpriteRenderer>().sortingOrder = 15;
                projectile = go.AddComponent<Projectile>();
                projectiles.Add(projectile);
            }
            projectile.Initialize(this, position, direction, damage, ammoIndex, hostile);
            projectile.gameObject.SetActive(true);
        }
        public int Alive => Enemies.FindAll(e => e.gameObject.activeSelf).Count;
        public void Clear()
        {
            foreach (var e in Enemies) e.gameObject.SetActive(false);
            foreach (var p in projectiles) p.gameObject.SetActive(false);
        }
    }
}
