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

    void Start()
    {
        MercDebug.Invariant(transactionHandler != null, $"Expected transaction handler to be set for {this}");
        label.text = tradeGood.name;
    }

    void OnEnable()
    {
        ship.cargoChangedEvent.AddListener(OnCargoChanged);

        int quantity = ship.GetCargo(tradeGood) ?? 0;
        OnCargoChanged(tradeGood, quantity);
    }

    void OnDisable()
    {
        ship.cargoChangedEvent.RemoveListener(OnCargoChanged);
    }

    private void OnCargoChanged(ITransactable transactable, int newQuantity)
    {
        // TODO
    }

    private int AddCargo(int quantity)
    {
        // TODO
        return -1;
    }

    private int RemoveCargo(int quantity)
    {
        // TODO
        return -1;
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
