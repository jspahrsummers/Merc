using UnityEngine;

public sealed class PlayerCameraController : MonoBehaviour
{
    private GameObject followTarget => GameObject.FindWithTag("Player");

    void Awake()
    {
        MercDebug.Invariant(followTarget != null, "Could not locate player object");
    }

    void LateUpdate()
    {
        Vector3 followPosition = followTarget.transform.position;
        transform.position = new Vector3(followPosition.x, followPosition.y, transform.position.z);
    }
}
