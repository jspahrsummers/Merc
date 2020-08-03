using UnityEngine;

/// <summary>Controls the main camera so that it follows an object across the scene.</summary>
public sealed class MainCameraController : MonoBehaviour
{
    [Tooltip("The object that the camera should be following.")]
    public GameObject followTarget;

    public static MainCameraController Find()
    {
        return Camera.main.GetComponent<MainCameraController>();
    }

    void LateUpdate()
    {
        if (followTarget == null)
        {
            return;
        }

        // The camera does not move along the Z axis to follow, only horizontally and vertically relative to the viewport.
        Vector3 followPosition = followTarget.transform.position;
        transform.position = new Vector3(followPosition.x, followPosition.y, transform.position.z);
    }
}
