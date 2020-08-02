using UnityEngine;

/// <summary>Implements the behaviors of a player (whether or not it is the local player).</summary>
public sealed class PlayerController : MonoBehaviour
{
    public new Rigidbody rigidbody;

    private float rotationDegrees = 0;

    private Inputs inputs;

    const float RotationSpeed = 5f;

    void OnEnable()
    {
        if (inputs == null)
        {
            inputs = new Inputs();
        }

        inputs.Enable();
    }

    void OnDisable()
    {
        inputs.Disable();
    }

    void FixedUpdate()
    {
        float turn = inputs.Player.Turn.ReadValue<float>() * RotationSpeed;
        rigidbody.MoveRotation(rigidbody.rotation * Quaternion.AngleAxis(turn, Vector3.up));
    }
}
