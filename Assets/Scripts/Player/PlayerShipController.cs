using System.Collections;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.SceneManagement;
using Mirror;

using RigidbodyExtensions;

public sealed class PlayerShipController : NetworkBehaviour, IDamageable
{
    public ShipScriptableObject ship;
    public ExplodableController explodable;
    public new Rigidbody2D rigidbody;
    public ProjectileController missilePrefab;
    public GameObject projectileExplosionPrefab;
    public HyperspaceArrivalController hyperspaceArrivalPrefab;

    private float _fuel = 1;
    public float fuel
    {
        get { return _fuel; }
        private set
        {
            _fuel = Mathf.Clamp01(value);
        }
    }

    private ShieldedHull destructible;
    private float turning;
    private float thrusting;

    private class InProgressHyperspaceJump
    {
        public Coroutine rotationCoroutine;
        public HyperspaceJump hyperspaceJump;
        public AsyncOperation sceneLoadOperation;
    }

    private InProgressHyperspaceJump inProgressHyperspaceJump;
    public bool isJumpingToHyperspace => inProgressHyperspaceJump != null;

    private PlayerState _playerState;
    public PlayerState playerState
    {
        get => _playerState;
        private set
        {
            Debug.Log($"Received player state {value} for {this}");
            _playerState = value;
        }
    }

    public override void OnStartClient()
    {
        if (this.IsServerOrHasAuthority())
        {
            return;
        }

        rigidbody.bodyType = RigidbodyType2D.Kinematic;
    }

    public override void OnStartLocalPlayer()
    {
        Debug.Log("OnStartLocalPlayer");
        var gameController = GameController.Find();
        gameController.playerShipController = this;

        playerState = (PlayerState)connectionToServer.authenticationData;
        MercDebug.EnforceField(playerState);
    }

    public override void OnStartServer()
    {
        playerState = (PlayerState)connectionToClient.authenticationData;
        MercDebug.EnforceField(playerState);
    }

    void Start()
    {
        MercDebug.EnforceField(ship);
        MercDebug.EnforceField(destructible);
        MercDebug.EnforceField(explodable);
        MercDebug.EnforceField(rigidbody);
        MercDebug.EnforceField(missilePrefab);
        MercDebug.EnforceField(projectileExplosionPrefab);
        MercDebug.EnforceField(hyperspaceArrivalPrefab);

        destructible = ShipUtilities.InitializeShip(ship, rigidbody);
    }

    public void ApplyDamage(Damage damage)
    {
        destructible.ApplyDamage(damage);
        if (destructible.IsDestroyed())
        {
            explodable.Explode();
        }
    }

    public void OnThrust(InputAction.CallbackContext context)
    {
        thrusting = context.ReadValue<float>();
    }

    public void OnTurn(InputAction.CallbackContext context)
    {
        turning = context.ReadValue<float>();
    }

    public void OnFire(InputAction.CallbackContext context)
    {
        if (!context.performed)
        {
            return;
        }

        CmdFireMissile(NetworkTime.rtt);
    }

    [Command]
    private void CmdFireMissile(double rtt)
    {
        MercDebug.Invariant(rtt >= 0, $"Round-trip time should not be less than zero: {rtt}");

        // Estimate where the player will be by the time the spawn message reaches them
        double returnTime = rtt / 2;
        Vector2 velocity = rigidbody.velocity;
        var position = new Vector3(
            (float)(transform.position.x + velocity.x * returnTime),
            (float)(transform.position.y + velocity.y * returnTime),
            transform.position.z);

        ProjectileScriptableObject projectile = ship.weapons[0];
        var missile = Instantiate<ProjectileController>(missilePrefab, position, transform.rotation, transform.parent);
        missile.rigidbody.velocity = velocity;
        missile.rigidbody.AddRelativeForce(Vector2.up * projectile.launchForce, ForceMode2D.Impulse);
        missile.spawnerNetId = netId;
        NetworkServer.Spawn(missile.gameObject);

        // TODO: Hack!
        var projectileExplosion = Instantiate(projectileExplosionPrefab, transform);
        projectileExplosion.transform.Translate(Vector3.forward * 10);
    }

    [Client]
    public void StartHyperspaceJump(HyperspaceJump hyperspaceJump)
    {
        MercDebug.Invariant(inProgressHyperspaceJump == null, $"Cannot start new hyperspace jump {hyperspaceJump} while one is in progress: {inProgressHyperspaceJump}");

        inProgressHyperspaceJump = new InProgressHyperspaceJump { hyperspaceJump = hyperspaceJump };
        inProgressHyperspaceJump.rotationCoroutine = StartCoroutine(PrepareForHyperspaceJump(hyperspaceJump));
    }

    [Client]
    public bool CancelHyperspaceJump()
    {
        MercDebug.Invariant(inProgressHyperspaceJump != null, "No hyperspace jump in progress");

        if (inProgressHyperspaceJump.sceneLoadOperation != null)
        {
            Debug.Log("Cannot cancel hyperspace jump, new scene already loaded");
            return false;
        }

        Coroutine coro = inProgressHyperspaceJump.rotationCoroutine;
        if (coro != null)
        {
            StopCoroutine(coro);
        }

        inProgressHyperspaceJump = null;
        return true;
    }

    [Client]
    public IEnumerator PrepareForHyperspaceJump(HyperspaceJump hyperspaceJump)
    {
        Debug.Log($"Ship starting jump {hyperspaceJump}");

        float angle = hyperspaceJump.angle;
        while (!rigidbody.IsRotatedToward(angle, ship.hyperspaceAngleTolerance))
        {
            yield return new WaitForFixedUpdate();
            rigidbody.RotateToward(angle, ship.turnSpeed * Time.deltaTime);
        }

        Debug.Log($"Rotation OK for hyperspace: {rigidbody.rotation}");

        while (Vector2.Dot(rigidbody.velocity, transform.up) < ship.requiredHyperspaceVelocity)
        {
            yield return new WaitForFixedUpdate();

            rigidbody.AddRelativeForce(Vector2.up * ship.hyperspaceThrust);
        }

        Debug.Log($"Velocity OK for hyperspace: {rigidbody.velocity} (magnitude: {rigidbody.velocity.magnitude}");
        inProgressHyperspaceJump.sceneLoadOperation = SceneManager.LoadSceneAsync(hyperspaceJump.toSystem.name, LoadSceneMode.Additive);
        inProgressHyperspaceJump.sceneLoadOperation.allowSceneActivation = false;
        CmdHyperspaceJump(hyperspaceJump.toSystem.name);
    }

    [Command]
    private void CmdHyperspaceJump(string destinationSceneName)
    {
        // Host mode will just behave like a client
        if (!isClient)
        {
            Scene scene = SceneManager.GetSceneByName(destinationSceneName);
            MercDebug.Invariant(scene.isLoaded, $"Expected {scene} to already be loaded on server");

            SceneManager.MoveGameObjectToScene(gameObject, scene);
        }

        RpcFinishHyperspaceJump();
    }

    [ClientRpc]
    private void RpcFinishHyperspaceJump()
    {
        MercDebug.Invariant(inProgressHyperspaceJump != null, "Server asked to finish hyperspace jump, but none is in progress");
        StartCoroutine(FinishHyperspaceJump());
    }

    [Client]
    private IEnumerator FinishHyperspaceJump()
    {
        inProgressHyperspaceJump.sceneLoadOperation.allowSceneActivation = true;
        yield return inProgressHyperspaceJump.sceneLoadOperation;

        HyperspaceJump hyperspaceJump = inProgressHyperspaceJump.hyperspaceJump;

        Scene newScene = SceneManager.GetSceneByName(hyperspaceJump.toSystem.name);
        Scene previousScene = SceneManager.GetActiveScene();
        MercDebug.Invariant(previousScene != newScene, $"Expected hyperspace jump to give different scene, not {newScene} again");

        SceneManager.SetActiveScene(newScene);
        SceneManager.MoveGameObjectToScene(gameObject, newScene);
        AsyncOperation unloadOperation = SceneManager.UnloadSceneAsync(previousScene);

        var arrivalController = Instantiate<HyperspaceArrivalController>(hyperspaceArrivalPrefab);
        arrivalController.hyperspaceJump = hyperspaceJump;

        rigidbody.rotation = hyperspaceJump.angle;

        Vector2 entryPoint = rigidbody.GetRelativePoint(Vector2.down * ship.hyperspaceArrivalDistance);
        rigidbody.position = entryPoint;

        rigidbody.AddRelativeForce(Vector2.up * ship.requiredHyperspaceVelocity * rigidbody.mass, ForceMode2D.Impulse);
        Debug.Log($"Arrived from hyperspace jump {hyperspaceJump}: rotation {rigidbody.rotation} position {rigidbody.position} velocity: {rigidbody.velocity} (magnitude: {rigidbody.velocity.magnitude})");

        yield return unloadOperation;
        inProgressHyperspaceJump = null;
    }

    void FixedUpdate()
    {
        if (turning != 0)
        {
            if (Mathf.Abs(rigidbody.angularVelocity) >= ship.torque)
            {
                rigidbody.AddTorque(turning * ship.torque);
            }
            else
            {
                rigidbody.angularVelocity = 0;
                rigidbody.MoveRotation(rigidbody.rotation + turning * ship.turnSpeed * Time.deltaTime);
            }
        }

        fuel += ship.fuelRegeneration * Time.deltaTime;

        if (thrusting > 0)
        {
            float neededFuel = ship.fuelConsumption * Time.deltaTime;
            float beforeFuel = fuel;
            fuel -= neededFuel;
            float consumedFuel = beforeFuel - fuel;

            rigidbody.AddRelativeForce(Vector2.up * thrusting * (consumedFuel / neededFuel) * ship.thrust);
        }
    }
}
