using UnityEngine;

public sealed class PlayerCameraController : MonoBehaviour
{
    public PlayerShipController followTarget;

    void Start()
    {
        MercDebug.EnforceField(followTarget);
    }

    void LateUpdate()
    {
        Vector3 followPosition = followTarget.transform.position;
        transform.position = new Vector3(followPosition.x, followPosition.y, transform.position.z);
    }
}
