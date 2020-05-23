using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerShipController : MonoBehaviour
{
    public float turnSpeed;
    public float torque;
    public float thrust;

    private float m_Turning;
    private float m_Thrusting;
    private Vector3 m_Velocity;

    public void OnThrust(InputAction.CallbackContext context)
    {
        m_Thrusting = context.ReadValue<float>();
    }

    public void OnTurn(InputAction.CallbackContext context)
    {
        m_Turning = context.ReadValue<float>();
    }

    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        var rigidbody = gameObject.GetComponent<Rigidbody2D>();

        if (Mathf.Abs(rigidbody.angularVelocity) >= torque)
        {
            rigidbody.AddTorque(m_Turning * torque * Time.deltaTime);
        }
        else
        {
            rigidbody.angularVelocity = 0;
            rigidbody.rotation += m_Turning * turnSpeed * Time.deltaTime;
        }

        rigidbody.AddRelativeForce(Vector2.up * m_Thrusting * thrust * Time.deltaTime);
    }
}
