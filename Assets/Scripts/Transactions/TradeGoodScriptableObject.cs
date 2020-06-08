using UnityEngine;

[CreateAssetMenu(menuName = "Gameplay/Trade Good")]
public sealed class TradeGoodScriptableObject : ScriptableObject, ITransactable
{
    public int cargoSpaceRequired => 1;

    public override int GetHashCode()
    {
        return name.GetHashCode();
    }

    public override bool Equals(object other)
    {
        TradeGoodScriptableObject tradeGood = other as TradeGoodScriptableObject;
        if (tradeGood == null)
        {
            return false;
        }

        return name == tradeGood.name;
    }
}