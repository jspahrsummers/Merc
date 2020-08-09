using System.Collections;
using UnityEngine;
using Mirror;
using MercExtensions;

/// <summary>Implements the behaviors of a player (whether or not it is the local player).</summary>
public sealed class PlayerController : NetworkBehaviour
{
    [Tooltip("The rigidbody of the player ship.")]
    public new Rigidbody rigidbody;

    [Tooltip("Renders the engine glow of the ship while thrusting.")]
    public GlowController engineGlowController;

    [Tooltip("Prefab for an object which represents blaster fire.")]
    public ProjectileController blasterFirePrefab;

    /// <summary>The nickname that this player chose when connecting.</summary>
    [SyncVar]
    public string nickname;

    /// <summary>Degrees per second that the ship is able to rotate.</summary>
    const float RotationSpeed = 250f;

    /// <summary>Force applied while thrusting.</summary>
    const float ThrustForce = 10f;

    /// <summary>Impulse force applied to blaster shots.</summary>
    const float BlasterForce = 1.5f;

    /// <summary>The number of seconds between blaster shots while firing.</summary>
    const float BlasterFireRate = 0.1f;

    /// <summary>How many seconds between informing the server of a new calculated round trip time.</summary>
    const float RttUpdateInterval = 2f;

    /// <summary>Input action map for responding to player controls.</summary>
    private Inputs inputs;

    /// <summary>Set on the server while the player is continuously firing.</summary>
    /// <remarks>This will always be null on a client (as long as it is not a host).</remarks>
    private Coroutine firingCoroutine;

    /// <summary>Client-provided round trip time for the server.</summary>
    /// <remarks>This is spoofable. We should consider how to make this more resilient to hacking.</remarks>
    private double rtt;

    public override void OnStartLocalPlayer()
    {
        if (inputs == null)
        {
            inputs = new Inputs();
            inputs.Player.Thrust.started += context =>
            {
                CmdStartEngineGlow();
                engineGlowController.SetVisible(true);
            };
            inputs.Player.Thrust.canceled += context =>
            {
                CmdStopEngineGlow();
                engineGlowController.SetVisible(false);
            };
            inputs.Player.Fire.started += context => CmdStartFiring();
            inputs.Player.Fire.canceled += context => CmdStopFiring();
        }

        inputs.Player.Enable();

        MainCameraController.Find().followTarget = gameObject;

        StartCoroutine(KeepServerInformedOfRtt());
    }

    public override void OnStartServer()
    {
        var authData = (MercAuthenticationData)connectionToClient.authenticationData;
        nickname = authData.nickname;
        gameObject.name = $"Player ({nickname})";
    }

    [Client]
    private IEnumerator KeepServerInformedOfRtt()
    {
        while (true)
        {
            yield return new WaitForSeconds(RttUpdateInterval);
            CmdUpdateRtt(NetworkTime.rtt);
        }
    }

    [Command(channel = Channels.DefaultUnreliable)]
    private void CmdUpdateRtt(double rtt)
    {
        this.rtt = rtt;
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
    private void CmdStartFiring()
    {
        if (firingCoroutine == null)
        {
            firingCoroutine = StartCoroutine(FireRepeatedly());
        }
    }

    [Server]
    private IEnumerator FireRepeatedly()
    {
        while (true)
        {
            // Assume that the client will have continued moving during the time
            // it takes this spawn message to reach them. We want to spawn the
            // projectile at the place _they_ will see themselves once the
            // message arrives.
            Vector3 extrapolatedPosition = rigidbody.ExtrapolatePositionAfterTime((float)rtt);

            var blasterFire = Instantiate<ProjectileController>(blasterFirePrefab, extrapolatedPosition, transform.rotation, transform.parent);
            blasterFire.initialVelocity = rigidbody.velocity;
            blasterFire.firedForce = BlasterForce;
            blasterFire.creatorNetId = netId;
            NetworkServer.Spawn(blasterFire.gameObject);

            yield return new WaitForSeconds(BlasterFireRate);
        }
    }

    [Command]
    private void CmdStopFiring()
    {
        if (firingCoroutine != null)
        {
            StopCoroutine(firingCoroutine);
            firingCoroutine = null;
        }
    }

    [Command(channel = Channels.DefaultUnreliable)]
    private void CmdStartEngineGlow()
    {
        RpcStartEngineGlow();
    }

    [ClientRpc(excludeOwner = true, channel = Channels.DefaultUnreliable)]
    private void RpcStartEngineGlow()
    {
        engineGlowController.SetVisible(true);
    }

    [Command]
    private void CmdStopEngineGlow()
    {
        RpcStopEngineGlow();
    }

    [ClientRpc(excludeOwner = true)]
    private void RpcStopEngineGlow()
    {
        engineGlowController.SetVisible(false);
    }
}
