using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class ShipController : MonoBehaviour
{
    public float rotateSpeed;
    public float thrustAcceleration;

    public Vector3 m_Velocity;

    public void OnThrust(InputAction.CallbackContext context)
    {
        m_Velocity += transform.up * thrustAcceleration * Time.deltaTime;
    }

    public void OnTurn(InputAction.CallbackContext context)
    {
        transform.Rotate(0, 0, context.ReadValue<float>() * rotateSpeed * Time.deltaTime);
    }

    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        transform.Translate(m_Velocity, Space.World);
    }
}
