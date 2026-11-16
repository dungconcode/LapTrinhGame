using System.Collections;
using UnityEngine;

namespace Underlab.Defense
{
    public class WaveSpawner : MonoBehaviour
    {
        public WaveConfig config;
        public CombatPool pool;
        public bool Spawning { get; private set; }
        public void Begin(int index) { StopAllCoroutines(); StartCoroutine(Spawn(config.waves[index])); }
        public void Stop() { StopAllCoroutines(); Spawning = false; pool.Clear(); }
        private IEnumerator Spawn(WaveConfig.Wave wave)
        {
            Spawning = true;
            int[] counts = { wave.melee, wave.flying, wave.ranged, wave.bosses };
            int side = 1;
            for (int kind = 0; kind < counts.Length; kind++)
                for (int i = 0; i < counts[kind]; i++)
                {
                    pool.Spawn((EnemyKind)kind, new Vector3(side * config.spawnDistance, kind == 1 ? config.flyingHeight : 0, 0), wave.healthScale, wave.speedScale);
                    side = -side;
                    yield return new WaitForSeconds(wave.spawnDelay);
                }
            Spawning = false;
        }
    }
}
