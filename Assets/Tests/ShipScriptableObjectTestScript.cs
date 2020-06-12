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

            Assert.AreEqual(0, ship.GetCargo(tradeGood1));
            Assert.AreEqual(0, ship.occupiedCargoSpace);
            Assert.AreEqual(10, ship.availableCargoSpace);

            int added = ship.AddCargo(tradeGood1, 5);
            Assert.AreEqual(5, added);
            Assert.AreEqual(5, ship.GetCargo(tradeGood1));
            Assert.AreEqual(0, ship.GetCargo(tradeGood2));
            Assert.AreEqual(5, ship.occupiedCargoSpace);
            Assert.AreEqual(5, ship.availableCargoSpace);

            added = ship.AddCargo(tradeGood1, 6);
            Assert.AreEqual(5, added);
            Assert.AreEqual(10, ship.GetCargo(tradeGood1));
            Assert.AreEqual(0, ship.GetCargo(tradeGood2));
            Assert.AreEqual(10, ship.occupiedCargoSpace);
            Assert.AreEqual(0, ship.availableCargoSpace);
        }

        [Test]
        public void RemoveCargo()
        {
            ship.cargoCapacity = 10;

            int added = ship.AddCargo(tradeGood1, 5);
            Assert.AreEqual(5, added);
            Assert.AreEqual(5, ship.GetCargo(tradeGood1));

            int removed = ship.RemoveCargo(tradeGood1, 3);
            Assert.AreEqual(3, removed);
            Assert.AreEqual(2, ship.GetCargo(tradeGood1));
            Assert.AreEqual(0, ship.GetCargo(tradeGood2));
            Assert.AreEqual(2, ship.occupiedCargoSpace);
            Assert.AreEqual(8, ship.availableCargoSpace);

            removed = ship.RemoveCargo(tradeGood1, 4);
            Assert.AreEqual(2, removed);
            Assert.AreEqual(0, ship.GetCargo(tradeGood1));
            Assert.AreEqual(0, ship.GetCargo(tradeGood2));
            Assert.AreEqual(0, ship.occupiedCargoSpace);
            Assert.AreEqual(10, ship.availableCargoSpace);
        }

        [Test]
        public void MultipleCargoTypes()
        {
            ship.cargoCapacity = 15;

            int added1 = ship.AddCargo(tradeGood1, 7);
            int added2 = ship.AddCargo(tradeGood2, 8);
            Assert.AreEqual(7, added1);
            Assert.AreEqual(8, added2);
            Assert.AreEqual(7, ship.GetCargo(tradeGood1));
            Assert.AreEqual(8, ship.GetCargo(tradeGood2));
            Assert.AreEqual(15, ship.occupiedCargoSpace);
            Assert.AreEqual(0, ship.availableCargoSpace);

            int removed1 = ship.RemoveCargo(tradeGood1, 3);
            Assert.AreEqual(3, removed1);
            Assert.AreEqual(4, ship.GetCargo(tradeGood1));
            Assert.AreEqual(8, ship.GetCargo(tradeGood2));
            Assert.AreEqual(12, ship.occupiedCargoSpace);
            Assert.AreEqual(3, ship.availableCargoSpace);

            added2 = ship.AddCargo(tradeGood2, 10);
            Assert.AreEqual(3, added2);
            Assert.AreEqual(4, ship.GetCargo(tradeGood1));
            Assert.AreEqual(11, ship.GetCargo(tradeGood2));
            Assert.AreEqual(15, ship.occupiedCargoSpace);
            Assert.AreEqual(0, ship.availableCargoSpace);
        }
    }
}
