using UnityEngine;

public sealed class ExplodableController : MonoBehaviour
{
    public GameObject explosion;
    public Damage damage;

    void Start()
    {
        MercDebug.EnforceField(explosion);
    }

    public void Explode()
    {
        Destroy(gameObject);
        Instantiate(explosion, transform.position, transform.rotation, transform.parent);
        // TODO: Damage objects nearby (Collider2.Cast?)
    }
}
