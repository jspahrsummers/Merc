using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.SceneManagement;
using Mirror;

public sealed class GameController : MonoBehaviour
{
    public GalaxyMapController galaxyMapController;
    public LandingScreenController landingScreenController;
    public HyperspaceArrivalController hyperspaceArrivalPrefab;
    public PlayerStateScriptableObject playerState;
    public PlayerCameraController playerCameraController;
    public UIController uiController;
    public PlayerInput playerInput;
    public NetworkManager networkManager;

    private Dictionary<Scene, StarSystemController> starSystemControllers = new Dictionary<Scene, StarSystemController>();

    private PlayerShipController _playerShipController;
    public PlayerShipController playerShipController
    {
        get => _playerShipController;
        set
        {
            _playerShipController = value;
            playerCameraController.playerShipController = value;
            uiController.playerShipController = value;
        }
    }

    private StarSystemController playerStarSystemController => starSystemForObject(playerShipController.gameObject);

    private Coroutine hyperspaceCoroutine;

    public static GameController Find()
    {
        return GameObject.FindWithTag("GameController").GetComponent<GameController>();
    }

    void Start()
    {
        MercDebug.EnforceField(galaxyMapController);
        MercDebug.EnforceField(landingScreenController);
        MercDebug.EnforceField(hyperspaceArrivalPrefab);
        MercDebug.EnforceField(playerState);
        MercDebug.EnforceField(playerInput);

        foreach (var actionMap in playerInput.actions.actionMaps)
        {
            actionMap.Enable();
        }
    }

    public void AddStarSystemController(StarSystemController controller)
    {
        starSystemControllers.Add(controller.gameObject.scene, controller);
    }

    public void RemoveStarSystemController(StarSystemController controller)
    {
        Scene scene = controller.gameObject.scene;
        MercDebug.Invariant(starSystemControllers.ContainsKey(scene), $"Controller {controller} was not registered to scene {scene}");
        starSystemControllers.Remove(scene);
    }

    private StarSystemController starSystemForObject(GameObject gameObject)
    {
        return starSystemControllers[gameObject.scene];
    }

    public void OnThrust(InputAction.CallbackContext context)
    {
        playerShipController.OnThrust(context);
    }

    public void OnTurn(InputAction.CallbackContext context)
    {
        playerShipController.OnTurn(context);
    }

    public void OnFire(InputAction.CallbackContext context)
    {
        playerShipController.OnFire(context);
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

        PlanetScriptableObject selectedPlanet = playerStarSystemController.selectedPlanet;
        if (!selectedPlanet)
        {
            Debug.Log("No planet selected");
            return;
        }

        var landedState = new LandedState { planet = selectedPlanet, playerState = playerState };
        landingScreenController.Prepare(landedState);
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
        StarSystemScriptableObject jumpSystem = playerStarSystemController.starSystem.adjacentSystems.Find(candidate => candidate.name == selectedSystem);
        if (jumpSystem == null)
        {
            Debug.Log($"No system selected for hyperspace jump");
            return;
        }

        Debug.Log($"Preparing jump to {jumpSystem}");
        var hyperspaceJump = new HyperspaceJump() { fromSystem = playerStarSystemController.starSystem, toSystem = jumpSystem };
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
