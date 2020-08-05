using UnityEngine;
using Mirror;

/// <summary>Implements the behaviors of a player (whether or not it is the local player).</summary>
public sealed class PlayerController : NetworkBehaviour
{
    [Tooltip("The rigidbody of the player ship.")]
    public new Rigidbody rigidbody;

    [Tooltip("Renders the engine glow of the ship while thrusting.")]
    public GlowController engineGlowController;

    /// <summary>Input action map for responding to player controls.</summary>
    private Inputs inputs;

    /// <summary>Degrees per second that the ship is able to rotate.</summary>
    const float RotationSpeed = 250f;

    /// <summary>Force applied while thrusting.</summary>
    const float ThrustForce = 10f;

    public override void OnStartLocalPlayer()
    {
        if (inputs == null)
        {
            inputs = new Inputs();
            inputs.Player.Thrust.started += context => engineGlowController.SetVisible(true);
            inputs.Player.Thrust.canceled += context => engineGlowController.SetVisible(false);
        }

        inputs.Player.Enable();

        MainCameraController.Find().followTarget = gameObject;
    }

    void OnDisable()
    {
        inputs?.Player.Disable();
    }

    void FixedUpdate()
    {
        if (inputs == null)
        {
            return;
        }

        var turn = inputs.Player.Turn.ReadValue<float>() * RotationSpeed * Time.deltaTime;
        rigidbody.MoveRotation(rigidbody.rotation * Quaternion.AngleAxis(turn, Vector3.up));

        var thrust = inputs.Player.Thrust.ReadValue<float>() * ThrustForce;
        rigidbody.AddRelativeForce(Vector3.forward * thrust);
    }
}
