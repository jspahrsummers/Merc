using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(PlayerInput))]
public class GameController : MonoBehaviour
{
    public GalaxyMapController galaxyMapController;
    public PlanetLandingController landingScreenController;

    private PlayerInput playerInput => GetComponent<PlayerInput>();

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
}
