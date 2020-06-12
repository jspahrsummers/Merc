using UnityEngine;
using UnityEngine.UI;

public sealed class TradeGoodUIController : MonoBehaviour
{
    public ShipScriptableObject ship;
    public PlanetScriptableObject planet;
    public TradeGoodScriptableObject tradeGood;
    public Text label;
    public Text price;
    public Text cargoCount;

    [HideInInspector]
    public ITransactionHandler<TradeGoodScriptableObject> transactionHandler;

    private long marketPrice
    {
        get
        {
            PlanetScriptableObject.Market market = planet.markets.Find(good => good.Equals(tradeGood));
            MercDebug.Invariant(market.good.Equals(tradeGood), $"Could not find market on planet {planet} for {tradeGood}");
            return market.price;
        }
    }

    void Start()
    {
        MercDebug.Invariant(transactionHandler != null, $"Expected transaction handler to be set for {this}");
        label.text = tradeGood.name;
    }

    void OnEnable()
    {
        ship.cargoChangedEvent.AddListener(OnCargoChanged);

        int quantity = ship.GetCargo(tradeGood);
        OnCargoChanged(tradeGood, quantity);
    }

    void OnDisable()
    {
        ship.cargoChangedEvent.RemoveListener(OnCargoChanged);
    }

    private void OnCargoChanged(ITransactable transactable, int newQuantity)
    {
        if (!transactable.Equals(tradeGood))
        {
            return;
        }

        cargoCount.text = newQuantity.ToString();
    }

    private Transaction<TradeGoodScriptableObject> TransactionForQuantity(int quantity)
    {
        return new Transaction<TradeGoodScriptableObject>() { transactable = tradeGood, quantity = quantity, price = marketPrice };
    }

    private int AddCargo(int quantity)
    {
        quantity = ship.AddCargo(tradeGood, quantity);

        var fulfilled = transactionHandler.AttemptTransaction(TransactionForQuantity(quantity));
        int purchasedQuantity = fulfilled?.quantity ?? 0;

        if (purchasedQuantity < quantity)
        {
            ship.RemoveCargo(tradeGood, quantity - purchasedQuantity);
        }

        return purchasedQuantity;
    }

    private int RemoveCargo(int quantity)
    {
        quantity = ship.RemoveCargo(tradeGood, quantity);

        var fulfilled = transactionHandler.AttemptTransaction(TransactionForQuantity(-quantity));
        int soldQuantity = -fulfilled?.quantity ?? 0;

        if (soldQuantity < quantity)
        {
            ship.RemoveCargo(tradeGood, quantity - soldQuantity);
        }

        return soldQuantity;
    }

    public void OnBuy()
    {
        AddCargo(1);
    }

    public void OnBuyAll()
    {
        AddCargo(int.MaxValue);
    }

    public void OnSell()
    {
        RemoveCargo(1);
    }

    public void OnSellAll()
    {
        RemoveCargo(int.MaxValue);
    }
}
