using System.Collections;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.UI;

public sealed class PlayerShipController : MonoBehaviour
{
    public float turnSpeed;
    public float torque;
    public float thrust;
    public float fuelConsumption;
    public float fuelRegeneration;
    public float hyperspaceThrust;
    public float requiredHyperspaceVelocity;
    public float hyperspaceArrivalDistance;
    public GameObject missilePrefab;
    public GameObject systemBase;

    public Slider fuelBar;

    private float _fuel = 1;
    private float fuel
    {
        get { return _fuel; }
        set
        {
            _fuel = Mathf.Clamp01(value);
            fuelBar.value = _fuel;
        }
    }

    private float turning;
    private float thrusting;
    private Vector3 velocity;

    private new Rigidbody2D rigidbody => GetComponent<Rigidbody2D>();
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

        var missile = Instantiate(missilePrefab, transform.position, transform.rotation, transform.parent).GetComponent<Rigidbody2D>();
        missile.velocity = rigidbody.velocity;
        missile.AddRelativeForce(Vector2.up * 10, ForceMode2D.Impulse);

        Physics2D.IgnoreCollision(missile.GetComponent<Collider2D>(), GetComponent<Collider2D>());
    }

    public void OnHyperspaceJump(InputAction.CallbackContext context)
    {
        if (!context.performed)
        {
            return;
        }

        StartCoroutine(StartHyperspaceJump(starSystemController.adjacentSystems[0]));
    }

    public void OnArrivalFromHyperspaceJump(float angle)
    {
        rigidbody.rotation = angle;

        Vector2 entryPoint = rigidbody.GetRelativePoint(Vector2.down * hyperspaceArrivalDistance);
        rigidbody.position = entryPoint;

        rigidbody.AddRelativeForce(Vector2.up * requiredHyperspaceVelocity * rigidbody.mass, ForceMode2D.Impulse);
        Debug.Log($"Arrived from hyperspace: rotation {rigidbody.rotation} position {rigidbody.position} velocity: {rigidbody.velocity} (magnitude: {rigidbody.velocity.magnitude})");
    }

    private IEnumerator StartHyperspaceJump(StarSystemController.AdjacentSystem system)
    {
        playerInput.enabled = false;

        while (!Mathf.Approximately(Mathf.Repeat(rigidbody.rotation, 360), system.angle))
        {
            yield return new WaitForFixedUpdate();

            float newAngle = Mathf.MoveTowardsAngle(rigidbody.rotation, system.angle, turnSpeed * Time.deltaTime);
            rigidbody.angularVelocity = 0;
            rigidbody.MoveRotation(newAngle);
        }

        Debug.Log($"Rotation OK for hyperspace: {rigidbody.rotation}");

        while (Vector2.Dot(rigidbody.velocity, transform.up) < requiredHyperspaceVelocity)
        {
            yield return new WaitForFixedUpdate();

            rigidbody.AddRelativeForce(Vector2.up * hyperspaceThrust * Time.deltaTime);
        }

        Debug.Log($"Velocity OK for hyperspace: {rigidbody.velocity} (magnitude: {rigidbody.velocity.magnitude}");
        starSystemController.JumpToAdjacentSystem(system);
    }

    void FixedUpdate()
    {
        if (turning != 0)
        {
            if (Mathf.Abs(rigidbody.angularVelocity) >= torque)
            {
                rigidbody.AddTorque(turning * torque * Time.deltaTime);
            }
            else
            {
                rigidbody.angularVelocity = 0;
                rigidbody.MoveRotation(rigidbody.rotation + turning * turnSpeed * Time.deltaTime);
            }
        }

        if (thrusting > 0)
        {
            float neededFuel = fuelConsumption * Time.deltaTime;
            float beforeFuel = fuel;
            fuel -= neededFuel;
            float consumedFuel = beforeFuel - fuel;

            rigidbody.AddRelativeForce(Vector2.up * thrusting * (consumedFuel / neededFuel) * thrust * Time.deltaTime);
        }
        else
        {
            fuel += fuelRegeneration * Time.deltaTime;
        }
    }
}
