using UnityEngine;
using Mirror;

public sealed class PlayerNetworkController : NetworkBehaviour
{
    public PlayerShipController playerShipController;

    public GameController gameController => GameObject.FindWithTag("GameController").GetComponent<GameController>();

    public override void OnStartLocalPlayer()
    {
        Debug.Log("OnStartLocalPlayer");
        gameController.playerShipController = playerShipController;
    }
}
