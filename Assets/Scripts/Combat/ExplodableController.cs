using UnityEngine;

public sealed class ExplodableController : MonoBehaviour
{
    public GameObject explosion;
    public Damage damage;

    void Awake()
    {
        MercDebug.Invariant(explosion != null, "Explodables need an explosion type to create");
    }

    public void Explode()
    {
        Destroy(gameObject);
        Instantiate(explosion, transform.position, transform.rotation, transform.parent);
        // TODO: Damage objects nearby (Collider2.Cast?)
    }
}
