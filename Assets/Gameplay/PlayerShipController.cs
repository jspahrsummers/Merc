using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.UI;

public class PlayerShipController : MonoBehaviour
{
    public float turnSpeed;
    public float torque;
    public float thrust;
    public float fuelConsumption;
    public float fuelRegeneration;
    public float hyperspaceThrust;
    public float requiredHyperspaceVelocity;
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

    private float m_Turning;
    private float m_Thrusting;
    private Vector3 m_Velocity;
    private float? m_TurningToJump;

    private new Rigidbody2D rigidbody => GetComponent<Rigidbody2D>();
    private StarSystemController starSystemController => systemBase.GetComponent<StarSystemController>();

    public void OnThrust(InputAction.CallbackContext context)
    {
        m_Thrusting = context.ReadValue<float>();
    }

    public void OnTurn(InputAction.CallbackContext context)
    {
        m_Turning = context.ReadValue<float>();
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
        StartCoroutine(StartHyperspaceJump(starSystemController.adjacentSystems[0]));
    }

    private IEnumerator StartHyperspaceJump(StarSystemController.AdjacentSystem system)
    {
        while (!Mathf.Approximately(rigidbody.rotation, system.angle))
        {
            yield return new WaitForFixedUpdate();

            var newAngle = Mathf.MoveTowardsAngle(rigidbody.rotation, system.angle, turnSpeed * Time.fixedDeltaTime);
            rigidbody.MoveRotation(newAngle);
        }

        while (rigidbody.velocity.magnitude < requiredHyperspaceVelocity)
        {
            yield return new WaitForFixedUpdate();

            rigidbody.AddRelativeForce(Vector2.up * hyperspaceThrust * Time.fixedDeltaTime);
        }

        starSystemController.JumpToAdjacentSystem(system);
    }

    void FixedUpdate()
    {
        if (m_Turning != 0)
        {
            if (Mathf.Abs(rigidbody.angularVelocity) >= torque)
            {
                rigidbody.AddTorque(m_Turning * torque * Time.fixedDeltaTime);
            }
            else
            {
                rigidbody.angularVelocity = 0;
                rigidbody.MoveRotation(rigidbody.rotation + m_Turning * turnSpeed * Time.fixedDeltaTime);
            }
        }

        if (m_Thrusting > 0)
        {
            var neededFuel = fuelConsumption * Time.fixedDeltaTime;
            var beforeFuel = fuel;
            fuel -= neededFuel;
            var consumedFuel = beforeFuel - fuel;

            rigidbody.AddRelativeForce(Vector2.up * m_Thrusting * (consumedFuel / neededFuel) * thrust * Time.fixedDeltaTime);
        }
        else
        {
            fuel += fuelRegeneration * Time.fixedDeltaTime;
        }
    }
}
