using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;
using Mirror;
using MercExtensions;
using TMPro;

/// <summary>Implements the behaviors of a player (whether or not it is the local player).</summary>
public sealed class PlayerController : NetworkBehaviour
{
    [Tooltip("The rigidbody of the player ship.")]
    public new Rigidbody rigidbody;

    [Tooltip("Renders the engine glow of the ship while thrusting.")]
    public GlowController engineGlowController;

    [Tooltip("Prefab for an object which represents blaster fire.")]
    public ProjectileController blasterFirePrefab;

    [Tooltip("Prefab for a hyperspace arrival effect.")]
    public HyperspaceArrivalController hyperspaceArrivalPrefab;

    [Tooltip("The element which renders the player's name above their ship.")]
    public TMP_Text playerNameText;

    [Tooltip("Sound effect to play when jumping to hyperspace.")]
    public AudioSource hyperspaceJumpOutSound;

    [Tooltip("Sound effect to play when arriving from hyperspace.")]
    public AudioSource hyperspaceJumpInSound;

    /// <summary>The nickname that this player chose when connecting.</summary>
    [HideInInspector, SyncVar(hook = nameof(SetNickname))]
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

    /// <summary>Normalized tolerance for how close the ship's rotation has to be to the desired rotation, in order to jump to hyperspace.</summary>
    const float HyperspaceRotationTolerance = 0.001f;

    /// <summary>Angle that the ship should rotate toward on the Z axis in order to enter hyperspace.</summary>
    const float HyperspaceEntryZAngle = -30f;

    /// <summary>Position on the Z axis that the ship must reach before entering hyperspace.</summary>
    const float HyperspaceEntryZPosition = 50f;

    /// <summary>How far away from the origin to place the ship when arriving from hyperspace, so that it has room to arrive near the system center.</summary>
    const float HyperspaceArrivalPositionOffset = 50f;

    /// <summary>Constraints to apply to the ship's rigidbody, to prevent undue movement from physics.</summary>
    /// <remarks>This is set in code rather than the editor, because we need to switch them off and back on during hyperspace jumps.</remarks>
    const RigidbodyConstraints DefaultRigidbodyConstraints = RigidbodyConstraints.FreezePositionZ | RigidbodyConstraints.FreezeRotationX;

    /// <summary>Saved relative position of the text UI, so the player object's rotation can be counteracted.</summary>
    private Vector3 relativeTextPosition;

    /// <summary>Saved rotation for text UI, so the player object's rotation can be counteracted.</summary>
    private Quaternion textRotation;

    /// <summary>Input action map for responding to player controls.</summary>
    private Inputs inputs;

    /// <summary>Set on the server while the player is continuously firing.</summary>
    /// <remarks>This will always be null on a client (as long as it is not a host).</remarks>
    private Coroutine firingCoroutine;

    /// <summary>Client-provided round trip time for the server.</summary>
    /// <remarks>This is spoofable. We should consider how to make this more resilient to hacking.</remarks>
    private double rtt;

    /// <summary>On the client, represents a hyperspace jump that is in progress.</summary>
    private sealed class InProgressHyperspaceJump
    {
        /// <summary>A description of the hyperspace jump being performed.</summary>
        public readonly HyperspaceJump jump;

        /// <summary>When the hyperspace target scene has started loading, this will be the operation for loading it asynchronously.</summary>
        public AsyncOperation sceneLoadOperation;

        public InProgressHyperspaceJump(HyperspaceJump jump)
        {
            this.jump = jump;
        }

        public override string ToString()
        {
            return $"InProgressHyperspaceJump({jump})";
        }
    }

    /// <summary>On the client, represents a hyperspace jump that is in progress.</summary>
    private InProgressHyperspaceJump inProgressHyperspaceJump;

    public override void OnStartLocalPlayer()
    {
        if (inputs == null)
        {
            inputs = new Inputs();
            inputs.Player.Thrust.started += context => StartEngineGlow();
            inputs.Player.Thrust.canceled += context => StopEngineGlow();
            inputs.Player.Fire.started += context => CmdStartFiring();
            inputs.Player.Fire.canceled += context => CmdStopFiring();
            inputs.Player.HyperspaceJump.performed += context => StartHyperspaceJump();
        }

        inputs.Player.Enable();

        SetUpCamera(MainCameraController.Find());
        StartCoroutine(KeepServerInformedOfRtt());
    }

    public override void OnStartServer()
    {
        var authData = (MercAuthenticationData)connectionToClient.authenticationData;
        nickname = authData.nickname;
    }

    void Awake()
    {
        relativeTextPosition = playerNameText.transform.position - transform.position;
        textRotation = playerNameText.transform.rotation;
    }

    void Start()
    {
        rigidbody.constraints = DefaultRigidbodyConstraints;
    }

    void OnEnable()
    {
        SetNickname("", nickname);
    }

    private void SetNickname(string oldName, string newName)
    {
        playerNameText.text = newName;
        gameObject.name = $"Player ({nickname})";
    }

    [Client]
    private void SetUpCamera(MainCameraController camera)
    {
        camera.followTarget = gameObject;
        camera.audioListener.enabled = true;
    }

    [Client]
    private void StartEngineGlow()
    {
        CmdStartEngineGlow();
        engineGlowController.SetVisible(true);
    }

    [Client]
    private void StopEngineGlow()
    {
        CmdStopEngineGlow();
        engineGlowController.SetVisible(false);
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

    void Update()
    {
        playerNameText.transform.position = transform.position + relativeTextPosition;
        playerNameText.transform.rotation = textRotation;
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
            SceneManager.MoveGameObjectToScene(blasterFire.gameObject, gameObject.scene);
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

    [Client]
    private void StartHyperspaceJump()
    {
        if (inProgressHyperspaceJump != null)
        {
            Debug.Log($"Hyperspace jump already in progress: {inProgressHyperspaceJump}");
            return;
        }

        var jumpScene = gameObject.scene.name == "Sirius B" ? "Alpha Centauri" : "Sirius B";
        var jump = new HyperspaceJump(gameObject.scene.name, jumpScene);
        inProgressHyperspaceJump = new InProgressHyperspaceJump(jump);
        StartCoroutine(PrepareForHyperspaceJumpThenNotifyServer());
    }

    [Client]
    private IEnumerator PrepareForHyperspaceJumpThenNotifyServer()
    {
        Debug.Log($"Starting scene load for hyperspace jump {inProgressHyperspaceJump}");

        string destinationSceneName = inProgressHyperspaceJump.jump.toSystem;
        if (!SceneManager.GetSceneByName(destinationSceneName).isLoaded)
        {
            inProgressHyperspaceJump.sceneLoadOperation = SceneManager.LoadSceneAsync(destinationSceneName, LoadSceneMode.Additive);
            inProgressHyperspaceJump.sceneLoadOperation.allowSceneActivation = false;
        }

        // Disable constraints while animating for hyperspace, as we will now move into the Z axis.
        rigidbody.constraints = RigidbodyConstraints.None;

        Quaternion targetRotation = Quaternion.Euler(HyperspaceEntryZAngle, 0, 0);
        while (!rigidbody.rotation.ApproximatelyEquals(targetRotation, HyperspaceRotationTolerance))
        {
            yield return new WaitForFixedUpdate();
            rigidbody.MoveRotation(Quaternion.RotateTowards(rigidbody.rotation, targetRotation, RotationSpeed * Time.deltaTime));
        }

        StartEngineGlow();
        hyperspaceJumpOutSound.Play();

        while (rigidbody.transform.position.z < HyperspaceEntryZPosition)
        {
            yield return new WaitForFixedUpdate();
            rigidbody.AddRelativeForce(Vector3.forward * ThrustForce);
        }

        if (inProgressHyperspaceJump.sceneLoadOperation != null)
        {
            while (inProgressHyperspaceJump.sceneLoadOperation.progress < 0.9f)
            {
                yield return null;
            }
        }

        CmdMovePlayerForHyperspaceJump(inProgressHyperspaceJump.jump);
    }

    [Command]
    private void CmdMovePlayerForHyperspaceJump(HyperspaceJump jump)
    {
        Debug.Log($"Moving {gameObject.name} for hyperspace jump {jump}");

        Scene destinationScene = SceneManager.GetSceneByName(jump.toSystem);
        SceneManager.MoveGameObjectToScene(gameObject, destinationScene);
        TargetFinishHyperspaceJump();
    }

    [TargetRpc]
    private void TargetFinishHyperspaceJump()
    {
        StartCoroutine(FinishLoadingHyperspaceJumpScene());
    }

    [Client]
    private IEnumerator FinishLoadingHyperspaceJumpScene()
    {
        Debug.Log($"Finishing hyperspace jump {inProgressHyperspaceJump}");

        AsyncOperation operation = inProgressHyperspaceJump.sceneLoadOperation;
        if (operation != null)
        {
            inProgressHyperspaceJump.sceneLoadOperation.allowSceneActivation = true;
            yield return inProgressHyperspaceJump.sceneLoadOperation;
        }

        rigidbody.velocity = Vector3.zero;
        rigidbody.rotation = Quaternion.Euler(-90, 0, 0);
        rigidbody.position = new Vector3(0, -HyperspaceArrivalPositionOffset, HyperspaceEntryZPosition);

        Scene destinationScene = SceneManager.GetSceneByName(inProgressHyperspaceJump.jump.toSystem);
        SceneManager.MoveGameObjectToScene(gameObject, destinationScene);
        SceneManager.SetActiveScene(destinationScene);

        Instantiate(hyperspaceArrivalPrefab);
        SetUpCamera(MainCameraController.Find());

        AsyncOperation unloadOperation = null;
        if (!isServer)
        {
            unloadOperation = SceneManager.UnloadSceneAsync(inProgressHyperspaceJump.jump.fromSystem);
        }

        // Returning thrust is applied in the opposite direction of going out (though we don't render that way, because it Looks Dumb)
        Quaternion returnAngle = Quaternion.Euler(HyperspaceEntryZAngle, 180, 180);
        hyperspaceJumpInSound.Play();

        while (rigidbody.position.z > 0)
        {
            yield return new WaitForFixedUpdate();
            rigidbody.AddForce(returnAngle * Vector3.forward * ThrustForce);
        }

        rigidbody.velocity = Vector3.Project(rigidbody.velocity, Vector3.up);
        rigidbody.position = Vector3.Project(rigidbody.position, Vector3.up);
        rigidbody.constraints = DefaultRigidbodyConstraints;

        StopEngineGlow();

        inProgressHyperspaceJump = null;
        if (unloadOperation != null)
        {
            yield return unloadOperation;
        }
    }
}
