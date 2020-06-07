using UnityEngine;

public sealed class PlayerCameraController : MonoBehaviour
{
    public PlayerShipController followTarget;

    void Awake()
    {
        MercDebug.Invariant(followTarget != null, "Player object not set for camera");
    }

    void LateUpdate()
    {
        Vector3 followPosition = followTarget.transform.position;
        transform.position = new Vector3(followPosition.x, followPosition.y, transform.position.z);
    }
}
