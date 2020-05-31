using UnityEngine;

[System.Serializable]
public struct Destructible : IDamageable
{
    public float armor;
    public float shields;

    public void ApplyDamage(Damage damage)
    {
        this.shields = Mathf.Max(0, this.shields - damage.energy);
        if (Mathf.Approximately(this.shields, 0))
        {
            this.armor = Mathf.Max(0, this.armor - damage.physical);
        }
    }

    public bool IsDestroyed()
    {
        Debug.Assert(this.shields >= 0);
        Debug.Assert(this.armor >= 0);
        return Mathf.Approximately(this.shields, 0) && Mathf.Approximately(this.armor, 0);
    }

    public override string ToString()
    {
        return $"Destructible(armor = {armor}, shields = {shields})";
    }
}
