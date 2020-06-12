using UnityEngine;

[CreateAssetMenu(menuName = "Gameplay/Player State")]
public sealed class PlayerStateScriptableObject : ScriptableObject, ITransactionHandler<TradeGoodScriptableObject>
{
    public long credits;

    // TODO: Need to support a fleet
    // TODO: This needs to be synchronized with PlayerShipController
    public ShipScriptableObject flagship;

    void Awake()
    {
        MercDebug.EnforceField(flagship);
    }

    public void Reset()
    {
        credits = 100000;
    }

    public Transaction<TradeGoodScriptableObject>? AttemptTransaction(Transaction<TradeGoodScriptableObject> proposed)
    {
        Debug.Log($"Attempting transaction {proposed}");

        if (proposed.quantity > 0)
        {
            var fundable = (int)(credits / proposed.price);
            int storable = flagship.availableCargoSpace / proposed.transactable.cargoSpaceRequired;

            int maxQuantity = System.Math.Min(fundable, storable);
            if (maxQuantity == 0)
            {
                Debug.Log($"Rejected transaction, can only fund {fundable} or store {storable}");
                return null;
            }

            proposed.quantity = System.Math.Min(proposed.quantity, maxQuantity);

            int added = flagship.AddCargo(proposed.transactable, proposed.quantity);
            MercDebug.Invariant(added == proposed.quantity, $"Cargo added {added} should match calculated transaction {proposed}");
        }
        else if (proposed.quantity < 0)
        {
            int stored = flagship.GetCargo(proposed.transactable);
            if (stored == 0)
            {
                Debug.Log($"Rejected transaction, only have {stored} stored");
                return null;
            }

            proposed.quantity = System.Math.Max(proposed.quantity, -stored);

            int removed = flagship.RemoveCargo(proposed.transactable, -proposed.quantity);
            MercDebug.Invariant(removed == -proposed.quantity, $"Cargo removed {removed} should match calculated transaction {proposed}");
        }

        credits += proposed.proceeds;
        MercDebug.Invariant(credits >= 0, $"Credits negative ({credits}) after transaction {proposed}");

        Debug.Log($"Executed transaction {proposed}");
        return proposed;
    }
}
