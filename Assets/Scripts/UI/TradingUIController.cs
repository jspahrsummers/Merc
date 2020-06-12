using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public sealed class TradingUIController : MonoBehaviour
{
    public TradeGoodUIController tradeGoodPrefab;
    public VerticalLayoutGroup verticalLayout;

    private LandedState? landedState;
    private List<TradeGoodUIController> tradeGoodControllers = new List<TradeGoodUIController>();

    void Start()
    {
        MercDebug.EnforceField(tradeGoodPrefab);
        MercDebug.EnforceField(verticalLayout);
    }

    public void Prepare(LandedState state)
    {
        this.landedState = state;
    }

    void OnEnable()
    {
        MercDebug.Invariant(landedState != null, $"LandedState not set before trading UI enabled");
        MercDebug.Invariant(tradeGoodControllers.Count == 0, $"Trade good controllers list not empty: {tradeGoodControllers}");

        foreach (var market in landedState.Value.planet.markets)
        {
            TradeGoodUIController controller = Instantiate(tradeGoodPrefab, verticalLayout.transform);
            tradeGoodControllers.Add(controller);

            controller.Prepare(landedState.Value, market);
            controller.enabled = true;
        }
    }

    void OnDisable()
    {
        landedState = null;

        foreach (var controller in tradeGoodControllers)
        {
            Destroy(controller.gameObject);
        }

        tradeGoodControllers.Clear();
    }
}
