using UnityEngine;

namespace RigidbodyExtensions
{
    public static class Extension
    {
        public static void RotateToward(this Rigidbody2D rigidbody, float desiredAngle, float turnSpeed)
        {
            float newAngle = Mathf.MoveTowardsAngle(rigidbody.rotation, desiredAngle, turnSpeed);
            rigidbody.angularVelocity = 0;
            rigidbody.MoveRotation(newAngle);
        }
    }
}