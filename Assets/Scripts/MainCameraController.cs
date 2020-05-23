using UnityEngine;
using UnityEngine.InputSystem;

/// <summary>Controls the main camera so that it follows an object across the scene.</summary>
public sealed class MainCameraController : MonoBehaviour
{
    [Tooltip("The object that the camera should be following.")]
    public GameObject followTarget;

    [Tooltip("The audio listener for this camera. Should be disabled by default.")]
    public AudioListener audioListener;

    /// <summary>Input action map for responding to camera controls.</summary>
    private Inputs inputs;

    /// <summary>The Z position that the camera should be animating movement to.</summary>
    private float targetZoomZ;

    /// <summary>The step size for zooming the game camera, to standardize across different inputs.</summary>
    const float CameraZoomStep = 5;

    const float CameraMinZoom = -20;

    const float CameraMaxZoom = -5;

    /// <summary>Units per second that the camera will zoom in its animation.</summary>
    const float CameraZoomAnimationStep = 15;

    public static MainCameraController Find()
    {
        return Camera.main.GetComponent<MainCameraController>();
    }

    void OnEnable()
    {
        if (inputs == null)
        {
            inputs = new Inputs();
            inputs.Camera.Zoom.performed += Zoom;
        }

        inputs.Camera.Enable();
        targetZoomZ = transform.position.z;
    }

    void OnDisable()
    {
        inputs.Camera.Disable();
    }

    void LateUpdate()
    {
        Vector3 newPosition = transform.position;
        if (followTarget != null)
        {
            Vector3 followPosition = followTarget.transform.position;

            // The camera does not move along the Z axis to follow, only horizontally and vertically relative to the viewport.
            newPosition.x = followPosition.x;
            newPosition.y = followPosition.y;
        }

        // Animate zoom
        newPosition.z = Mathf.MoveTowards(newPosition.z, targetZoomZ, CameraZoomAnimationStep * Time.deltaTime);

        transform.position = newPosition;
    }

    private void Zoom(InputAction.CallbackContext context)
    {
        var change = context.ReadValue<Vector2>();
        targetZoomZ = Mathf.Clamp(targetZoomZ + CameraZoomStep * Mathf.Sign(change.y), CameraMinZoom, CameraMaxZoom);
        Debug.Log($"New zoom: {targetZoomZ}");
    }
}
