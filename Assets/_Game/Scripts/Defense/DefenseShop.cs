using System.Collections.Generic;
using Underlab.Core;
using UnityEngine;

namespace Underlab.Defense
{
    public class DefenseShop : MonoBehaviour
    {
        public ResourceBank bank;
        public BaseHealth baseHealth;
        public UpgradeDef[] upgrades;
        public bool AtBase { get; private set; }
        public bool Open { get; set; }
        public GamePhase Phase { get; private set; }
        private readonly Dictionary<string, int> levels = new Dictionary<string, int>();
        public int Level(string id) => levels.TryGetValue(id, out int n) ? n : 0;
        public bool Available => AtBase && Phase == GamePhase.Mining;
        private void OnEnable() { GameEvents.PlayerAtBaseChanged += OnBase; GameEvents.PhaseChanged += OnPhase; GameEvents.UpgradePurchased += Purchased; }
        private void OnDisable() { GameEvents.PlayerAtBaseChanged -= OnBase; GameEvents.PhaseChanged -= OnPhase; GameEvents.UpgradePurchased -= Purchased; }
        private void OnBase(bool value) { AtBase = value; if (!value) Open = false; }
        private void OnPhase(GamePhase value) { Phase = value; if (value != GamePhase.Mining) Open = false; }
        private void Purchased(string id) => levels[id] = Level(id) + 1;
        public bool CanBuy(UpgradeDef def)
        {
            if (!Available || def.ironCosts == null || def.ironCosts.Length == 0) return false;
            var mining = Underlab.Mining.MiningUpgrades.Instance;
            if (IsMiningUpgrade(def.id) && (mining == null || !mining.CanUpgrade(def.id))) return false;
            if (!def.repeatable && Level(def.id) >= def.ironCosts.Length) return false;
            if (def.id == "repair" && baseHealth.Current >= baseHealth.Maximum) return false;
            return bank.Balance(ResourceType.Iron) >= Price(def);
        }
        private static bool IsMiningUpgrade(string id) => id == UpgradeIds.Drill || id == UpgradeIds.Move || id == UpgradeIds.Carry || id == UpgradeIds.Jetpack;
        public int Price(UpgradeDef def) => def.ironCosts[Mathf.Min(Level(def.id), def.ironCosts.Length - 1)];
        public int MaxLevel(UpgradeDef def)
        {
            var mining = Underlab.Mining.MiningUpgrades.Instance;
            return IsMiningUpgrade(def.id) && mining != null ? Mathf.Min(def.ironCosts.Length, mining.MaxLevel(def.id)) : def.ironCosts.Length;
        }
        public bool Buy(UpgradeDef def)
        {
            if (!CanBuy(def) || !bank.Spend(ResourceType.Iron, Price(def))) return false;
            GameEvents.RaiseUpgradePurchased(def.id);
            if (def.id == "base_hp") baseHealth.Upgrade();
            if (def.id == "repair") baseHealth.Repair();
            return true;
        }
    }
}
