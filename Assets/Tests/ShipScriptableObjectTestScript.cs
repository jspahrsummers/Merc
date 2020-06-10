using System.Collections;
using System.Collections.Generic;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;

namespace Tests
{
    public class ShipScriptableObjectTest
    {
        private ShipScriptableObject ship;
        private TradeGoodScriptableObject tradeGood1;
        private TradeGoodScriptableObject tradeGood2;

        [SetUp]
        protected void SetUp()
        {
            ship = ScriptableObject.CreateInstance<ShipScriptableObject>();

            tradeGood1 = ScriptableObject.CreateInstance<TradeGoodScriptableObject>();
            tradeGood1.name = "tradeGood1";

            tradeGood2 = ScriptableObject.CreateInstance<TradeGoodScriptableObject>();
            tradeGood2.name = "tradeGood2";
        }

        [Test]
        public void AddCargo()
        {
            ship.cargoCapacity = 10;

            Assert.IsNull(ship.GetCargo(tradeGood1));
            int added = ship.AddCargo(tradeGood1, 5);
            Assert.AreEqual(5, added);
            Assert.AreEqual(5, ship.GetCargo(tradeGood1));
            Assert.IsNull(ship.GetCargo(tradeGood2));

            added = ship.AddCargo(tradeGood1, 6);
            Assert.AreEqual(5, added);
            Assert.AreEqual(10, ship.GetCargo(tradeGood1));
            Assert.IsNull(ship.GetCargo(tradeGood2));
        }
    }
}
