using System;
using Underlab.Core;
using UnityEngine;

namespace Underlab.Defense
{
    public class ResourceBank : MonoBehaviour
    {
        private readonly int[] balances = new int[4];
        public int Balance(ResourceType type) => balances[(int)type];
        private void OnEnable() => GameEvents.ResourcesDeposited += Deposit;
        private void OnDisable() => GameEvents.ResourcesDeposited -= Deposit;
        private void Start() { foreach (ResourceType t in Enum.GetValues(typeof(ResourceType))) GameEvents.RaiseBankChanged(t, Balance(t)); }
        private void Deposit(ResourceType type, int count)
        {
            if (count <= 0) return;
            balances[(int)type] += count;
            GameEvents.RaiseBankChanged(type, Balance(type));
        }
        public bool Spend(ResourceType type, int count)
        {
            if (count < 0 || Balance(type) < count) return false;
            balances[(int)type] -= count;
            GameEvents.RaiseBankChanged(type, Balance(type));
            return true;
        }
    }
}
