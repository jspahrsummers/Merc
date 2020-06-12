using UnityEngine;

public abstract class AbstractShipController : MonoBehaviour, IDamageable
{
    public ShipScriptableObject ship;
    public Destructible destructible;
    public ExplodableController explodable;
    public new Rigidbody2D rigidbody;

    protected virtual void Start()
    {
        Debug.Log($"Overriding {rigidbody} mass to {ship.mass}");
        rigidbody.mass = ship.mass;

        if (destructible.IsDestroyed())
        {
            destructible = ship.baseDestructible;
            Debug.Assert(!destructible.IsDestroyed());
        }
    }

    public void ApplyDamage(Damage damage)
    {
        destructible.ApplyDamage(damage);
        if (destructible.IsDestroyed())
        {
            explodable.Explode();
        }
    }
}
