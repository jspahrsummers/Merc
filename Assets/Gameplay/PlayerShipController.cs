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
    public GameObject missilePrefab;

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

    private new Rigidbody2D rigidbody => GetComponent<Rigidbody2D>();

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

    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        if (Mathf.Abs(rigidbody.angularVelocity) >= torque)
        {
            rigidbody.AddTorque(m_Turning * torque * Time.deltaTime);
        }
        else
        {
            rigidbody.angularVelocity = 0;
            rigidbody.rotation += m_Turning * turnSpeed * Time.deltaTime;
        }

        if (m_Thrusting > 0)
        {
            var neededFuel = fuelConsumption * Time.deltaTime;
            var beforeFuel = fuel;
            fuel -= neededFuel;
            var consumedFuel = beforeFuel - fuel;

            rigidbody.AddRelativeForce(Vector2.up * m_Thrusting * (consumedFuel / neededFuel) * thrust * Time.deltaTime);
        }
        else
        {
            fuel += fuelRegeneration * Time.deltaTime;
        }
    }
}
