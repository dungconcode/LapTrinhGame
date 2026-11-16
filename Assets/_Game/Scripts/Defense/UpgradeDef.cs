using UnityEngine;

namespace Underlab.Defense
{
    [CreateAssetMenu(menuName = "Underlab/Defense/Upgrade")]
    public class UpgradeDef : ScriptableObject
    {
        public string id, displayName;
        public int[] ironCosts = { 5, 10, 20, 35, 50 };
        public bool repeatable;
    }
}
