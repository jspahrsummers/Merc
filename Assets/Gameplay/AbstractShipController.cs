using UnityEngine;

public abstract class AbstractShipController : MonoBehaviour
{
    public ShipScriptableObject ship;

    public new Rigidbody2D rigidbody => GetComponent<Rigidbody2D>();

    protected void ForciblyRotateToward(float desiredAngle)
    {
        float newAngle = Mathf.MoveTowardsAngle(rigidbody.rotation, desiredAngle, ship.turnSpeed * Time.deltaTime);
        rigidbody.angularVelocity = 0;
        rigidbody.MoveRotation(newAngle);
    }

    protected virtual void Start()
    {
        Debug.Log($"Overriding mass to {ship.mass}");
        rigidbody.mass = ship.mass;
    }
}
