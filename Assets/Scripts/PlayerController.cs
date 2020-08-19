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

    [Tooltip("The damageable object representing the player's ship.")]
    public DamageableController damageable;

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

    [Tooltip("Object which renders a pointer to direct players back to the origin. Rotating this object should produce pointers to different directions around the player.")]
    public GameObject pointerIcon;

    /// <summary>The nickname that this player chose when connecting.</summary>
    [HideInInspector, SyncVar(hook = nameof(SetNickname))]
    public string nickname;

    /// <summary>Degrees per second that the ship is able to rotate.</summary>
    const float RotationSpeed = 250f;

    /// <summary>Force applied while thrusting.</summary>
    const float ThrustForce = 10f;

    /// <summary>How much energy thrusting consumes per second.</summary>
    const float ThrustEnergyConsumption = 0.2f;

    /// <summary>Impulse force applied to blaster shots.</summary>
    const float BlasterForce = 1.5f;

    /// <summary>The number of seconds between blaster shots while firing.</summary>
    const float BlasterFireRate = 0.1f;

    /// <summary>How much energy the blaster consumes per second.</summary>
    const float BlasterEnergyConsumption = 0.6f;

    /// <summary>How much energy regenerates per second.</summary>
    const float EnergyRegeneration = 0.1f;

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

    /// <summary>Once the player is this far away from the origin, pointerIcon will be shown to direct them back.</summary>
    const float DistanceForShowingPointer = 25f;

    /// <summary>Vertical canvas offset at which to position player name text, relative to the ship.</summary>
    const float PlayerNameTextYOffset = 25 * 0.02f;

    /// <summary>Constraints to apply to the ship's rigidbody, to prevent undue movement from physics.</summary>
    /// <remarks>This is set in code rather than the editor, because we need to switch them off and back on during hyperspace jumps.</remarks>
    const RigidbodyConstraints DefaultRigidbodyConstraints = RigidbodyConstraints.FreezePositionZ | RigidbodyConstraints.FreezeRotationX;

    /// <summary>Input action map for responding to player controls.</summary>
    private Inputs inputs;

    /// <summary>Set on the server while the player is continuously firing.</summary>
    /// <remarks>This will always be null on a client (as long as it is not a host).</remarks>
    private Coroutine firingCoroutine;

    /// <summary>How much energy the local player's ship has, for thrusting, turning, firing, etc.</summary>
    [SerializeField]
    private float energy = 1f;

    /// <summary>Client-provided round trip time for the server.</summary>
    /// <remarks>This is spoofable. We should consider how to make this more resilient to hacking.</remarks>
    private double rtt;

    /// <summary>Any planet that the player is touching, or null if the player is not touching any.</summary>
    private PlanetController touchingPlanet;

    /// <summary>The active UIController, set for the local player when created.</summary>
    private UIController uiController;

    private sealed class InProgressHyperspaceJump
    {
        public readonly HyperspaceJump jump;
        public bool clientSceneLoaded = false;
        public bool clientPlayerReady = false;

        public InProgressHyperspaceJump(HyperspaceJump jump)
        {
            this.jump = jump;
        }

        public override string ToString()
        {
            return $"InProgressHyperspaceJump(jump = {jump}, clientSceneLoaded = {clientSceneLoaded}, clientPlayerReady = {clientPlayerReady})";
        }
    }

    /// <summary>On the server, represents a hyperspace jump that is in progress.</summary>
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
            inputs.Player.HyperspaceJump.performed += context => CmdStartHyperspaceJump();
            inputs.Player.Land.performed += context => Land();
        }

        inputs.Player.Enable();

        SceneManager.SetActiveScene(gameObject.scene);
        SetUpCamera(MainCameraController.Find());
        uiController = UIController.Find();

        StartCoroutine(KeepServerInformedOfRtt());
    }

    public override void OnStartServer()
    {
        var authData = (MercAuthenticationData)connectionToClient.authenticationData;
        nickname = authData.nickname;
    }

    void Start()
    {
        rigidbody.constraints = DefaultRigidbodyConstraints;
    }

    void OnEnable()
    {
        SetNickname("", nickname);
        inputs?.Player.Enable();
    }

    void OnDisable()
    {
        inputs?.Player.Disable();
    }

    void OnDestroy()
    {
        if (isServer && NetworkServer.active)
        {
            // Respawn
            var player = Instantiate(NetworkManager.singleton.playerPrefab);
            if (!NetworkServer.ReplacePlayerForConnection(connectionToClient, player, false))
            {
                Debug.Log($"Could not replace player object for {connectionToClient}");
            }
        }
    }

    void OnTriggerEnter(Collider collider)
    {
        if (!isLocalPlayer)
        {
            return;
        }

        var planet = collider.GetComponent<PlanetController>();
        if (planet == null)
        {
            return;
        }

        Debug.Log($"Started touching {planet}");
        touchingPlanet = planet;
    }

    void OnTriggerExit(Collider collider)
    {
        if (!isLocalPlayer)
        {
            return;
        }

        var planet = collider.GetComponent<PlanetController>();
        if (planet == null)
        {
            return;
        }

        if (touchingPlanet == planet)
        {
            Debug.Log($"Stopped touching {planet}");
            touchingPlanet = null;
        }
    }

    void FixedUpdate()
    {
        if (!isLocalPlayer)
        {
            return;
        }

        energy = Mathf.Min(energy + EnergyRegeneration * Time.deltaTime, 1);

        var firing = inputs.Player.Fire.ReadValue<float>();
        if (firing > 0)
        {
            float energyUsage = BlasterEnergyConsumption * Time.deltaTime;
            if (energyUsage > energy)
            {
                CmdStopFiring();
            }
            else
            {
                energy -= energyUsage;
            }
        }

        var turn = inputs.Player.Turn.ReadValue<float>() * RotationSpeed * Time.deltaTime;
        rigidbody.MoveRotation(rigidbody.rotation * Quaternion.AngleAxis(turn, Vector3.up));

        var thrust = inputs.Player.Thrust.ReadValue<float>() * ThrustForce;
        if (thrust > 0)
        {
            float energyFactor = ConsumeEnergy(ThrustEnergyConsumption * Time.deltaTime);
            rigidbody.AddRelativeForce(Vector3.forward * thrust * energyFactor);
        }

        Vector2 position2D = rigidbody.position;
        bool showPointerIcon = inProgressHyperspaceJump == null && position2D.magnitude >= DistanceForShowingPointer;
        if (showPointerIcon)
        {
            Vector2 headingTowardOrigin = -rigidbody.position;
            Vector2 directionTowardOrigin = headingTowardOrigin / headingTowardOrigin.magnitude;
            float angle = Vector2.SignedAngle(Vector2.up, directionTowardOrigin);
            pointerIcon.transform.rotation = Quaternion.Euler(0, 0, angle);
        }

        pointerIcon.SetActive(showPointerIcon);
    }

    void Update()
    {
        // If in host mode, and this player should not be visible to the local player, hide the player name text.
        if (NetworkManager.singleton.mode == NetworkManagerMode.Host && !isLocalPlayer && gameObject.scene != NetworkClient.connection.identity.gameObject.scene)
        {
            playerNameText.enabled = false;
        }
        else
        {
            playerNameText.enabled = true;
            playerNameText.transform.position = transform.position + new Vector3(0, PlayerNameTextYOffset, 0);
            playerNameText.transform.rotation = Quaternion.identity;
        }

        if (isLocalPlayer)
        {
            uiController.energyBar.value = energy;
            uiController.hullBar.value = damageable.hull / damageable.maxHull;
            uiController.shieldsBar.value = damageable.shields / damageable.maxShields;
        }
    }

    /// <summary>Attempts to consume the given amount of energy, up to the total remaining amount that the ship has. Returns a percentage [0, 1] of how much of `amount` was actually able to be consumed.</summary>
    private float ConsumeEnergy(float amount)
    {
        float originalEnergy = energy;
        energy = Mathf.Max(energy - amount, 0);
        float usage = originalEnergy - energy;

        return usage / amount;
    }

    /// <summary>Invoked to relocate the player object to another scene on the server side. When done, the server should tell the client to activate the same scene using ActivateSceneMessage.</summary>
    [Server]
    public void MoveToScene(Scene scene)
    {
        if (inProgressHyperspaceJump != null && scene.name == inProgressHyperspaceJump.jump.toSystem)
        {
            inProgressHyperspaceJump.clientSceneLoaded = true;
            FinishHyperspaceJumpIfReady();
            return;
        }

        Debug.Log($"Moving {this} to scene {scene.path}");
        SceneManager.MoveGameObjectToScene(gameObject, scene);
        connectionToClient.Send(new ActivateSceneMessage { sceneNameOrPath = scene.path });
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

            var leftBlasterFire = Instantiate<ProjectileController>(blasterFirePrefab, extrapolatedPosition + rigidbody.transform.TransformDirection(Vector3.left * 0.25f), transform.rotation, transform.parent);
            leftBlasterFire.initialVelocity = rigidbody.velocity;
            leftBlasterFire.firedForce = BlasterForce;
            leftBlasterFire.creatorNetId = netId;
            SceneManager.MoveGameObjectToScene(leftBlasterFire.gameObject, gameObject.scene);
            NetworkServer.Spawn(leftBlasterFire.gameObject);

            yield return new WaitForSeconds(BlasterFireRate / 2);

            var rightBlasterFire = Instantiate<ProjectileController>(blasterFirePrefab, extrapolatedPosition + rigidbody.transform.TransformDirection(Vector3.right * 0.25f), transform.rotation, transform.parent);
            rightBlasterFire.initialVelocity = rigidbody.velocity;
            rightBlasterFire.firedForce = BlasterForce;
            rightBlasterFire.creatorNetId = netId;
            SceneManager.MoveGameObjectToScene(rightBlasterFire.gameObject, gameObject.scene);
            NetworkServer.Spawn(rightBlasterFire.gameObject);

            yield return new WaitForSeconds(BlasterFireRate / 2);
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

    [Command]
    private void CmdStartHyperspaceJump()
    {
        if (inProgressHyperspaceJump != null)
        {
            Debug.Log($"Hyperspace jump for {this} already in progress: {inProgressHyperspaceJump}");
            return;
        }

        var jumpScene = gameObject.scene.name == "Sirius B" ? "Alpha Centauri" : "Sirius B";
        var jump = new HyperspaceJump(gameObject.scene.name, jumpScene);
        inProgressHyperspaceJump = new InProgressHyperspaceJump(jump);
        TargetPrepareForHyperspaceJump(jump);

        // In host mode, the target scene should already be loaded.
        if (isLocalPlayer)
        {
            MoveToScene(SceneManager.GetSceneByName(jump.toSystem));
        }
        else
        {
            connectionToClient.Send(new SceneMessage { sceneName = jumpScene, sceneOperation = SceneOperation.LoadAdditive, customHandling = true });
        }
    }

    [TargetRpc]
    private void TargetPrepareForHyperspaceJump(HyperspaceJump jump)
    {
        StartCoroutine(PrepareForHyperspaceJumpThenNotifyServer(jump));
    }

    [Client]
    private IEnumerator PrepareForHyperspaceJumpThenNotifyServer(HyperspaceJump jump)
    {
        inputs.Player.Disable();

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

        CmdReadyForHyperspaceJump();
    }

    [Command]
    private void CmdReadyForHyperspaceJump()
    {
        if (inProgressHyperspaceJump == null)
        {
            return;
        }

        inProgressHyperspaceJump.clientPlayerReady = true;
        FinishHyperspaceJumpIfReady();
    }

    [Server]
    private void FinishHyperspaceJumpIfReady()
    {
        if (!inProgressHyperspaceJump.clientPlayerReady || !inProgressHyperspaceJump.clientSceneLoaded)
        {
            return;
        }

        HyperspaceJump jump = inProgressHyperspaceJump.jump;
        Scene scene = SceneManager.GetSceneByName(jump.toSystem);
        Debug.Assert(scene.IsValid() && scene.isLoaded, $"Scene for hyperspace jump {jump} is invalid");

        // This needs to be cleared before MoveToScene, because it calls back into this method otherwise.
        inProgressHyperspaceJump = null;
        MoveToScene(scene);

        TargetArriveFromHyperspaceJump(jump);
    }

    [TargetRpc]
    private void TargetArriveFromHyperspaceJump(HyperspaceJump jump)
    {
        StartCoroutine(ArriveFromHyperspaceJump(jump));
    }

    [Client]
    private IEnumerator ArriveFromHyperspaceJump(HyperspaceJump jump)
    {
        Debug.Log($"Arriving from hyperspace jump {jump}");

        Instantiate(hyperspaceArrivalPrefab);
        hyperspaceJumpInSound.Play();

        rigidbody.velocity = Vector3.zero;
        rigidbody.rotation = Quaternion.Euler(-90, 0, 0);
        rigidbody.position = new Vector3(0, -HyperspaceArrivalPositionOffset, HyperspaceEntryZPosition);

        // Returning thrust is applied in the opposite direction of going out (though we don't render that way, because it Looks Dumb)
        Quaternion returnAngle = Quaternion.Euler(HyperspaceEntryZAngle, 180, 180);
        while (rigidbody.position.z > 0)
        {
            yield return new WaitForFixedUpdate();
            rigidbody.AddForce(returnAngle * Vector3.forward * ThrustForce);
        }

        rigidbody.velocity = Vector3.Project(rigidbody.velocity, Vector3.up);
        rigidbody.position = Vector3.Project(rigidbody.position, Vector3.up);
        rigidbody.constraints = DefaultRigidbodyConstraints;

        StopEngineGlow();
        inputs.Player.Enable();

        CmdFinishedArrivingFromHyperspaceJump(jump);
    }

    [Command]
    private void CmdFinishedArrivingFromHyperspaceJump(HyperspaceJump jump)
    {
        // Don't unload any scenes in host mode
        if (!isLocalPlayer)
        {
            connectionToClient.Send(new SceneMessage { sceneName = jump.fromSystem, sceneOperation = SceneOperation.UnloadAdditive, customHandling = true });
        }
    }

    [Client]
    private void Land()
    {
        if (touchingPlanet == null)
        {
            Debug.Log($"Cannot land, no planet nearby");
            return;
        }

        Debug.Log($"Landing on {touchingPlanet}");
        CmdLand();
        uiController.ShowLandingScreen(touchingPlanet, CmdDepart);
    }

    [Command]
    private void CmdLand()
    {
        Debug.Log($"{name} landing");
        gameObject.SetActive(false);
        RpcLand();
    }

    [ClientRpc]
    private void RpcLand()
    {
        Debug.Log($"{name} landing");
        gameObject.SetActive(false);
    }

    [Command]
    private void CmdDepart()
    {
        Debug.Log($"{name} departing");
        gameObject.SetActive(true);
        NetworkServer.Spawn(gameObject, connectionToClient);
        RpcDepart();
    }

    [ClientRpc]
    private void RpcDepart()
    {
        Debug.Log($"{name} departing");

        if (isLocalPlayer)
        {
            rigidbody.velocity = Vector3.zero;
        }

        gameObject.SetActive(true);
    }
}
