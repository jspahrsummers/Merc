using UnityEngine;

[CreateAssetMenu(menuName = "Gameplay/Projectile")]
public class ProjectileScriptableObject : ScriptableObject
{
    public ShieldedHull baseDestructible;

    [Tooltip("Mass of this projectile in tonnes (used in physics calculations)")]
    public float mass = 1;

    [Tooltip("Damage applied upon direct hit")]
    public Damage groundZeroDamage;

    [Tooltip("Amount by which damage applied is reduced, per meter of distance away from an object")]
    public Damage damageDropoffByDistance;

    [Tooltip("Number of seconds before this projectile dies if it has not hit a target")]
    public float lifetime = Mathf.Infinity;

    // TODO: Move this to a weapon definition, not here
    [Tooltip("How many kilonewtons of force are applied to this projectile when launched")]
    public float launchForce;
}
