using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.SceneManagement;
using Mirror;

// Primarily client-side object.
public sealed class GameController : MonoBehaviour
{
    public GalaxyMapController galaxyMapController;
    public LandingScreenController landingScreenController;
    public PlayerStateScriptableObject playerState;
    public PlayerCameraController playerCameraController;
    public UIController uiController;
    public PlayerInput playerInput;
    public NetworkManager networkManager;
    public SceneController sceneController;

    private PlayerShipController _playerShipController;
    public PlayerShipController playerShipController
    {
        get => _playerShipController;
        set
        {
            _playerShipController = value;
            playerCameraController.playerObject = value.gameObject;
            uiController.playerShipController = value;
        }
    }

    public StarSystemController starSystemController;

    public static GameController Find()
    {
        return GameObject.FindWithTag("GameController").GetComponent<GameController>();
    }

    void Start()
    {
        MercDebug.EnforceField(galaxyMapController);
        MercDebug.EnforceField(landingScreenController);
        MercDebug.EnforceField(playerState);
        MercDebug.EnforceField(playerInput);

        foreach (var actionMap in playerInput.actions.actionMaps)
        {
            actionMap.Enable();
        }

        DontDestroyOnLoad(gameObject);
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

        PlanetScriptableObject selectedPlanet = starSystemController?.selectedPlanet;
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
        if (!context.performed || !playerShipController)
        {
            return;
        }

        if (playerShipController.isJumpingToHyperspace)
        {
            Debug.Log($"Attempting to cancel jump to hyperspace");
            playerShipController.CancelHyperspaceJump();
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
        playerShipController.StartHyperspaceJump(hyperspaceJump);
    }
}
