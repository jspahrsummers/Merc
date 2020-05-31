using UnityEngine;

public abstract class AbstractShipController : MonoBehaviour, IDamageable
{
    public ShipScriptableObject ship;

    private Destructible destructible;
    private ExplodableController explodable => GetComponent<ExplodableController>();
    public new Rigidbody2D rigidbody => GetComponent<Rigidbody2D>();

    protected virtual void Start()
    {
        Debug.Log($"Overriding {rigidbody} mass to {ship.mass}");
        rigidbody.mass = ship.mass;

        destructible = ship.baseDestructible;
        Debug.Assert(!destructible.IsDestroyed());
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
