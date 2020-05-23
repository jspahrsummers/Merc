using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class ShipController : MonoBehaviour
{
    public float rotateSpeed;
    public float thrustAcceleration;

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
        transform.Rotate(0, 0, m_Turning * rotateSpeed * Time.deltaTime);

        m_Velocity += m_Thrusting * transform.up * thrustAcceleration * Time.deltaTime;
        transform.Translate(m_Velocity, Space.World);
    }
}
