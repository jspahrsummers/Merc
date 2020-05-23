/// <summary>Encapsulates all of the different kinds of damage that can be applied (e.g., by a weapon).</summary>
[System.Serializable]
public struct Damage
{
    /// <summary>Damage to shields.</summary>
    public float shields;

    /// <summary>Damage to a physical hull.</summary>
    public float hull;

    public static implicit operator bool(Damage damage)
    {
        return damage.shields > 0 || damage.hull > 0;
    }
}
