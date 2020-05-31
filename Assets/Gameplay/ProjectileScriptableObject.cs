using UnityEngine;

[CreateAssetMenu(fileName = "Projectile", menuName = "Gameplay/Projectile")]
public class ProjectileScriptableObject : ScriptableObject
{
    public Destructible baseDestructible;
    public float mass = 1;
    public Damage groundZeroDamage;
    public Damage damageDropoffByDistance;
    public float lifetime = Mathf.Infinity;
}