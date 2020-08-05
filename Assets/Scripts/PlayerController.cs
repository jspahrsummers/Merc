using System.Collections;
using UnityEngine;
using Mirror;

/// <summary>Implements the behaviors of a player (whether or not it is the local player).</summary>
public sealed class PlayerController : NetworkBehaviour
{
    [Tooltip("The rigidbody of the player ship.")]
    public new Rigidbody rigidbody;

    [Tooltip("Renders the engine glow of the ship while thrusting.")]
    public GlowController engineGlowController;

    [Tooltip("Prefab for an object which represents blaster fire.")]
    public Rigidbody blasterFirePrefab;

    /// <summary>Degrees per second that the ship is able to rotate.</summary>
    const float RotationSpeed = 250f;

    /// <summary>Force applied while thrusting.</summary>
    const float ThrustForce = 10f;

    /// <summary>Impulse force applied to blaster shots.</summary>
    const float BlasterForce = 1.5f;

    /// <summary>The number of seconds between blaster shots while firing.</summary>
    const float BlasterFireRate = 0.1f;

    /// <summary>Input action map for responding to player controls.</summary>
    private Inputs inputs;

    /// <summary>Set on the server while the player is continuously firing.</summary>
    /// <remarks>This will always be null on a client (as long as it is not a host).</remarks>
    private Coroutine firingCoroutine;

    public override void OnStartLocalPlayer()
    {
        if (inputs == null)
        {
            inputs = new Inputs();
            inputs.Player.Thrust.started += context => engineGlowController.SetVisible(true);
            inputs.Player.Thrust.canceled += context => engineGlowController.SetVisible(false);
            inputs.Player.Fire.started += context => CmdStartFiring();
            inputs.Player.Fire.canceled += context => CmdStopFiring();
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

    [Command]
    void CmdStartFiring()
    {
        if (firingCoroutine == null)
        {
            firingCoroutine = StartCoroutine(FireRepeatedly());
        }
    }

    [Server]
    IEnumerator FireRepeatedly()
    {
        while (true)
        {
            var blasterFire = Instantiate<Rigidbody>(blasterFirePrefab, transform.position, transform.rotation, transform.parent);
            blasterFire.velocity = rigidbody.velocity;
            blasterFire.AddRelativeForce(Vector3.forward * BlasterForce, ForceMode.Impulse);
            NetworkServer.Spawn(blasterFire.gameObject);

            yield return new WaitForSeconds(BlasterFireRate);
        }
    }

    [Command]
    void CmdStopFiring()
    {
        if (firingCoroutine != null)
        {
            StopCoroutine(firingCoroutine);
            firingCoroutine = null;
        }
    }
}
