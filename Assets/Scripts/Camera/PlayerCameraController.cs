using UnityEngine;

public sealed class PlayerCameraController : MonoBehaviour
{
    [HideInInspector]
    public PlayerShipController playerShipController;

    void LateUpdate()
    {
        if (playerShipController == null)
        {
            return;
        }

        Vector3 followPosition = playerShipController.transform.position;
        transform.position = new Vector3(followPosition.x, followPosition.y, transform.position.z);
    }
}
