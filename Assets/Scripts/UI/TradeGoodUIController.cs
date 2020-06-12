using UnityEngine;
using UnityEngine.UI;

public sealed class TradeGoodUIController : MonoBehaviour
{
    public Text label;
    public Text price;
    public Text cargoCount;

    private LandedState? landedState;
    private PlanetScriptableObject.Market? market;

    private PlayerStateScriptableObject playerState => landedState.Value.playerState;
    // TODO: Support a fleet
    private ShipScriptableObject ship => playerState.flagship;
    private TradeGoodScriptableObject tradeGood => market.Value.good;
    private long marketPrice => market.Value.price;

    void Start()
    {
        MercDebug.EnforceField(label);
        MercDebug.EnforceField(price);
        MercDebug.EnforceField(cargoCount);
    }

    public void Prepare(LandedState state, PlanetScriptableObject.Market market)
    {
        this.landedState = state;
        this.market = market;
    }

    void OnEnable()
    {
        MercDebug.Invariant(landedState != null, $"LandedState not set before trade good UI {this} enabled");
        MercDebug.Invariant(market != null, $"Market not set before trade good UI {this} enabled");

        label.text = tradeGood.name;
        price.text = $"{marketPrice} credits";
        ship.cargoChangedEvent.AddListener(OnCargoChanged);

        int quantity = ship.GetCargo(tradeGood);
        OnCargoChanged(tradeGood, quantity);
    }

    void OnDisable()
    {
        ship.cargoChangedEvent.RemoveListener(OnCargoChanged);

        landedState = null;
        market = null;
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
        var fulfilled = playerState.AttemptTransaction(TransactionForQuantity(quantity));
        return fulfilled?.quantity ?? 0;
    }

    private int RemoveCargo(int quantity)
    {
        var fulfilled = playerState.AttemptTransaction(TransactionForQuantity(-quantity));
        return -fulfilled?.quantity ?? 0;
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
