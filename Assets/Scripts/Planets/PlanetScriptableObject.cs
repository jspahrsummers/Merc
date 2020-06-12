using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(menuName = "Gameplay/Planet")]
public sealed class PlanetScriptableObject : ScriptableObject
{
    [System.Serializable]
    public struct Market
    {
        public TradeGoodScriptableObject good;
        public long price;
    }

    public List<Market> markets;
}