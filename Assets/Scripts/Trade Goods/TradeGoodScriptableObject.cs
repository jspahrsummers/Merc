using UnityEngine;

[CreateAssetMenu(menuName = "Gameplay/Trade Good")]
public sealed class TradeGoodScriptableObject : ScriptableObject
{
    public override int GetHashCode()
    {
        return name.GetHashCode();
    }

    public override bool Equals(object other)
    {
        return name == (other as TradeGoodScriptableObject).name;
    }
}