using UnityEngine;

public sealed class PlayerCameraController : MonoBehaviour
{
    [HideInInspector]
    public GameObject playerObject;

    void LateUpdate()
    {
        if (playerObject == null)
        {
            return;
        }

        Vector3 followPosition = playerObject.transform.position;
        transform.position = new Vector3(followPosition.x, followPosition.y, transform.position.z);
    }
}
