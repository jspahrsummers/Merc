using System.Collections;
using UnityEngine;
using UnityEngine.InputSystem;
using Mirror;

using RigidbodyExtensions;

public sealed class PlayerShipController : NetworkBehaviour, IDamageable
{
    public ShipScriptableObject ship;
    public ExplodableController explodable;
    public new Rigidbody2D rigidbody;
    public ProjectileController missilePrefab;
    public GameObject projectileExplosionPrefab;

    private float _fuel = 1;
    public float fuel
    {
        get { return _fuel; }
        private set
        {
            _fuel = Mathf.Clamp01(value);
        }
    }

    private Destructible destructible;
    private float turning;
    private float thrusting;

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
    }

    void Start()
    {
        MercDebug.EnforceField(ship);
        MercDebug.EnforceField(destructible);
        MercDebug.EnforceField(explodable);
        MercDebug.EnforceField(rigidbody);
        MercDebug.EnforceField(missilePrefab);
        MercDebug.EnforceField(projectileExplosionPrefab);

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

    public IEnumerator StartHyperspaceJump(HyperspaceJump hyperspaceJump)
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
    }

    public void OnCompletedHyperspaceJump(HyperspaceJump hyperspaceJump)
    {
        rigidbody.rotation = hyperspaceJump.angle;

        Vector2 entryPoint = rigidbody.GetRelativePoint(Vector2.down * ship.hyperspaceArrivalDistance);
        rigidbody.position = entryPoint;

        rigidbody.AddRelativeForce(Vector2.up * ship.requiredHyperspaceVelocity * rigidbody.mass, ForceMode2D.Impulse);
        Debug.Log($"Arrived from hyperspace jump {hyperspaceJump}: rotation {rigidbody.rotation} position {rigidbody.position} velocity: {rigidbody.velocity} (magnitude: {rigidbody.velocity.magnitude})");
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
