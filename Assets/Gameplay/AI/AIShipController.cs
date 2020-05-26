using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AIShipController : MonoBehaviour
{
    public float turnSpeed;
    public float thrust;
    public float speedTolerance;
    public float rotationTolerance;

    private new Rigidbody2D rigidbody => GetComponent<Rigidbody2D>();

    void Start()
    {
        StartCoroutine(DecelerateAndStop());
    }

    void OnCollisionEnter2D(Collision2D other)
    {
        Debug.Log($"Collision between {this} and {other}");
        StartCoroutine(DecelerateAndStop());
    }

    private IEnumerator DecelerateAndStop()
    {
        while (Mathf.Abs(rigidbody.velocity.magnitude) > speedTolerance)
        {
            yield return new WaitForFixedUpdate();

            float velocityAngle = Vector2.SignedAngle(Vector2.up, rigidbody.velocity);
            float desiredAngle = velocityAngle + 180;
            Debug.Log($"Velocity angled at {velocityAngle}");

            if (Mathf.Repeat(rigidbody.rotation - desiredAngle, 360) > rotationTolerance)
            {
                float newAngle = Mathf.MoveTowardsAngle(rigidbody.rotation, desiredAngle, turnSpeed * Time.fixedDeltaTime);
                rigidbody.angularVelocity = 0;
                rigidbody.MoveRotation(newAngle);
            }
            else
            {
                rigidbody.AddRelativeForce(Vector2.up * thrust * Time.fixedDeltaTime);
            }
        }

        Debug.Log("Decelerated to a stop");
    }
}
