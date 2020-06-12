using System.Collections;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.TestTools;

namespace Tests
{
    public class PlayerShipControllerTestScript
    {
        [UnityTest]
        public IEnumerator TurnsForHyperspace()
        {
            yield return SceneManager.LoadSceneAsync("Sol");

            var playerShipController = Object.FindObjectOfType<PlayerShipController>();
            Assert.IsNotNull(playerShipController);

            var system1 = ScriptableObject.CreateInstance<StarSystemScriptableObject>();
            var system2 = ScriptableObject.CreateInstance<StarSystemScriptableObject>();
            system1.adjacentSystems.Add(system2);
            system2.adjacentSystems.Add(system1);
            system1.galaxyPosition = new Vector2() { x = 0, y = 0 };
            system2.galaxyPosition = new Vector2() { x = -100, y = 0 };

            var hyperspaceJump = new HyperspaceJump() { fromSystem = system1, toSystem = system2 };
            Assert.True(Mathf.Approximately(90, Mathf.Repeat(hyperspaceJump.angle, 360)), $"Unexpected angle: {hyperspaceJump.angle}");

            yield return playerShipController.StartHyperspaceJump(hyperspaceJump);
            Assert.AreEqual(hyperspaceJump.angle, playerShipController.rigidbody.rotation);
        }
    }
}
