using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerShipController : MonoBehaviour
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
        var rigidbody = gameObject.GetComponent<Rigidbody2D>();
        rigidbody.rotation += m_Turning * rotateSpeed * Time.deltaTime;
        rigidbody.AddRelativeForce(Vector2.up * m_Thrusting * thrustAcceleration * Time.deltaTime);
    }
}
