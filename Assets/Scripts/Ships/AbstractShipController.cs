using UnityEngine;

[RequireComponent(typeof(ExplodableController), typeof(Rigidbody2D), typeof(Collider2D))]
public abstract class AbstractShipController : MonoBehaviour, IDamageable
{
    public ShipScriptableObject ship;
    public Destructible destructible;

    private ExplodableController explodable => GetComponent<ExplodableController>();
    public new Rigidbody2D rigidbody => GetComponent<Rigidbody2D>();

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
