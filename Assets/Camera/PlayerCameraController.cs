using UnityEngine;

public sealed class PlayerCameraController : MonoBehaviour
{
    private GameObject followTarget => GameObject.FindWithTag("Player");

    void LateUpdate()
    {
        Vector3 followPosition = followTarget.transform.position;
        transform.position = new Vector3(followPosition.x, followPosition.y, transform.position.z);
    }
}
