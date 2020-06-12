using System.Collections;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.TestTools;

namespace Tests
{
    public class TradeGoodUIControllerTestScript
    {
        private ShipScriptableObject ship;
        private PlanetScriptableObject planet;
        private TradeGoodScriptableObject tradeGood1;
        const long tradeGood1Price = 100;
        private TradeGoodScriptableObject tradeGood2;
        const long tradeGood2Price = 150;

        private sealed class StubTransactionHandler : ITransactionHandler<TradeGoodScriptableObject>
        {
            public delegate Transaction<TradeGoodScriptableObject>? Delegate(Transaction<TradeGoodScriptableObject> proposed);

            public Delegate attemptTransaction = proposed => proposed;

            public Transaction<TradeGoodScriptableObject>? AttemptTransaction(Transaction<TradeGoodScriptableObject> proposed)
            {
                return attemptTransaction(proposed);
            }
        }

        private StubTransactionHandler transactionHandler;


        [SetUp]
        protected void SetUp()
        {
            ship = ScriptableObject.CreateInstance<ShipScriptableObject>();

            tradeGood1 = ScriptableObject.CreateInstance<TradeGoodScriptableObject>();
            tradeGood1.name = "tradeGood1";

            tradeGood2 = ScriptableObject.CreateInstance<TradeGoodScriptableObject>();
            tradeGood2.name = "tradeGood2";

            planet = ScriptableObject.CreateInstance<PlanetScriptableObject>();
            planet.markets.Add(new PlanetScriptableObject.Market { good = tradeGood1, price = tradeGood1Price });
            planet.markets.Add(new PlanetScriptableObject.Market { good = tradeGood2, price = tradeGood2Price });

            transactionHandler = new StubTransactionHandler();
        }

        [UnityTest]
        public IEnumerator LoadController()
        {
            yield return SceneManager.LoadSceneAsync("TradeGoodUIControllerTest");

            var controller = Object.FindObjectOfType<TradeGoodUIController>();
            Assert.IsNotNull(controller);

            controller.ship = ship;
            controller.planet = planet;
            controller.tradeGood = tradeGood1;
            controller.transactionHandler = transactionHandler;
        }
    }
}
