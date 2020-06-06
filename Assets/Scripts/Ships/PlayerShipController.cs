using System.Collections;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.UI;

using RigidbodyExtensions;

public sealed class PlayerShipController : AbstractShipController
{
    public GameObject missilePrefab;
    public GameObject projectileExplosionPrefab;
    public GameObject systemBase;
    public GalaxyMapController galaxyMapController;
    public PlanetLandingController planetLandingController;

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

    private StarSystemController starSystemController => systemBase.GetComponent<StarSystemController>();
    private PlayerInput playerInput => GetComponent<PlayerInput>();

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

    public void OnToggleMap(InputAction.CallbackContext context)
    {
        if (!context.performed)
        {
            return;
        }

        GameObject galaxyMap = galaxyMapController.gameObject;
        galaxyMap.SetActive(!galaxyMap.activeSelf);
    }

    public void OnHyperspaceJump(InputAction.CallbackContext context)
    {
        if (!context.performed)
        {
            return;
        }

        string selectedSystem = galaxyMapController.selectedSystem;
        StarSystemScriptableObject jumpSystem = starSystemController.starSystem.adjacentSystems.Find(candidate => candidate.name == selectedSystem);
        if (jumpSystem != null)
        {
            StartCoroutine(StartHyperspaceJump(jumpSystem));
        }
    }

    public void OnLand(InputAction.CallbackContext context)
    {
        if (!context.performed)
        {
            return;
        }

        PlanetScriptableObject selectedPlanet = starSystemController.selectedPlanet;
        if (!selectedPlanet)
        {
            Debug.Log("No planet selected");
            return;
        }

        // TODO: Check distance to planet
        planetLandingController.planet = selectedPlanet;
        planetLandingController.gameObject.SetActive(true);
    }

    public void OnArrivalFromHyperspaceJump(float angle)
    {
        rigidbody.rotation = angle;

        Vector2 entryPoint = rigidbody.GetRelativePoint(Vector2.down * ship.hyperspaceArrivalDistance);
        rigidbody.position = entryPoint;

        rigidbody.AddRelativeForce(Vector2.up * ship.requiredHyperspaceVelocity * rigidbody.mass, ForceMode2D.Impulse);
        Debug.Log($"Arrived from hyperspace: rotation {rigidbody.rotation} position {rigidbody.position} velocity: {rigidbody.velocity} (magnitude: {rigidbody.velocity.magnitude})");
    }

    private IEnumerator StartHyperspaceJump(StarSystemScriptableObject system)
    {
        playerInput.enabled = false;

        float angle = starSystemController.starSystem.AngleToSystem(system);
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
        starSystemController.JumpToSystem(system);
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
