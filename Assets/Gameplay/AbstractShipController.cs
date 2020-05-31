using UnityEngine;

public abstract class AbstractShipController : MonoBehaviour, IDamageable
{
    public ShipScriptableObject ship;
    public Destructible destructible;
    public GameObject explosionPrefab;

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

    // TODO: Share code with ProjectileController.Explode
    private void Explode()
    {
        Destroy(gameObject);
        if (explosionPrefab)
        {
            Instantiate(explosionPrefab, transform.position, transform.rotation, transform.parent);
        }

        // TODO: Damage objects nearby
    }

    public void ApplyDamage(Damage damage)
    {
        destructible.ApplyDamage(damage);
        if (destructible.IsDestroyed())
        {
            Explode();
        }
    }
}
