using System.Collections;
using UnityEngine;
using UnityEngine.InputSystem;

using RigidbodyExtensions;

public sealed class PlayerShipController : AbstractShipController
{
    public GameObject missilePrefab;
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

    private float turning;
    private float thrusting;

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

        ProjectileScriptableObject projectile = ship.weapons[0];
        // TODO: Connect the prefab with the projectile object

        var missile = Instantiate(missilePrefab, transform.position, transform.rotation, transform.parent).GetComponent<Rigidbody2D>();
        missile.velocity = rigidbody.velocity;
        missile.AddRelativeForce(Vector2.up * projectile.launchForce, ForceMode2D.Impulse);

        // TODO: Hack!
        var projectileExplosion = Instantiate(projectileExplosionPrefab, transform);
        projectileExplosion.transform.Translate(Vector3.forward * 10);

        Physics2D.IgnoreCollision(missile.GetComponent<Collider2D>(), GetComponent<Collider2D>());
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
