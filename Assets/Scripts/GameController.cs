using System.Collections;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.SceneManagement;

[RequireComponent(typeof(PlayerInput))]
public sealed class GameController : MonoBehaviour
{
    public GalaxyMapController galaxyMapController;
    public LandingScreenController landingScreenController;
    public StarSystemController starSystemController;
    public PlayerShipController playerShipController;
    public HyperspaceArrivalController hyperspaceArrivalPrefab;

    private PlayerInput playerInput => GetComponent<PlayerInput>();
    private Coroutine hyperspaceCoroutine;

    void Start()
    {
        foreach (var actionMap in playerInput.actions.actionMaps)
        {
            actionMap.Enable();
        }
    }

    public void OnToggleMap(InputAction.CallbackContext context)
    {
        if (!context.performed)
        {
            return;
        }

        GameObject galaxyMap = galaxyMapController.gameObject;
        galaxyMap.SetActive(!galaxyMap.activeSelf);
    }

    public void OnLand(InputAction.CallbackContext context)
    {
        if (!context.performed)
        {
            return;
        }

        PlanetScriptableObject selectedPlanet = starSystemController.selectedPlanet;
        if (!selectedPlanet)
        {
            Debug.Log("No planet selected");
            return;
        }

        // TODO: Check distance to planet
        landingScreenController.planet = selectedPlanet;
        landingScreenController.gameObject.SetActive(true);
    }

    public void OnHyperspaceJump(InputAction.CallbackContext context)
    {
        if (!context.performed)
        {
            return;
        }

        if (hyperspaceCoroutine != null)
        {
            Debug.Log($"Cancelling jump to hyperspace");
            StopCoroutine(hyperspaceCoroutine);
            hyperspaceCoroutine = null;
            return;
        }

        string selectedSystem = galaxyMapController.selectedSystem;
        StarSystemScriptableObject jumpSystem = starSystemController.starSystem.adjacentSystems.Find(candidate => candidate.name == selectedSystem);
        if (jumpSystem == null)
        {
            Debug.Log($"No system selected for hyperspace jump");
            return;
        }

        Debug.Log($"Preparing jump to {jumpSystem}");
        var hyperspaceJump = new HyperspaceJump() { fromSystem = starSystemController.starSystem, toSystem = jumpSystem };
        hyperspaceCoroutine = StartCoroutine(StartHyperspaceJump(hyperspaceJump));
    }

    private IEnumerator StartHyperspaceJump(HyperspaceJump hyperspaceJump)
    {
        yield return playerShipController.StartHyperspaceJump(hyperspaceJump);
        yield return LoadHyperspaceJumpAsync(hyperspaceJump);
    }

    private IEnumerator LoadHyperspaceJumpAsync(HyperspaceJump hyperspaceJump)
    {
        AsyncOperation asyncLoad = SceneManager.LoadSceneAsync(hyperspaceJump.toSystem.name);
        asyncLoad.allowSceneActivation = false;

        while (!asyncLoad.isDone)
        {
            if (asyncLoad.progress >= 0.9f)
            {
                var arrivalController = Instantiate<HyperspaceArrivalController>(hyperspaceArrivalPrefab);
                arrivalController.hyperspaceJump = hyperspaceJump;
                DontDestroyOnLoad(arrivalController.gameObject);

                asyncLoad.allowSceneActivation = true;
            }

            yield return null;
        }
    }

    public void OnCompletedHyperspaceJump(HyperspaceJump hyperspaceJump)
    {
        float arrivalAngle = hyperspaceJump.fromSystem.AngleToSystem(hyperspaceJump.toSystem);
        playerShipController.OnCompletedHyperspaceJump(hyperspaceJump);
    }
}
