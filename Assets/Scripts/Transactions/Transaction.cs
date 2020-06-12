public struct Transaction<T> where T : ITransactable
{
    public T transactable;

    // Positive quantity to purchase, or negative quantity to sell.
    public int quantity;

    // Price per item, which will always be positive.
    // TODO: Replace with currency-tagged value
    public long price;

    // Total proceeds for the transaction, which will be negative for a purchase and positive for a sale.
    // TODO: Replace with currency-tagged value
    public long proceeds => -quantity * price;

    public override string ToString()
    {
        if (quantity > 0)
        {
            return $"Purchase of {quantity} x {transactable} @ {price} = {proceeds} credits";
        }
        else if (quantity < 0)
        {
            return $"Sale of {-quantity} x {transactable} @ {price} = {proceeds} credits";
        }
        else
        {
            return $"Empty transaction for {transactable} @ {price}";
        }
    }
}