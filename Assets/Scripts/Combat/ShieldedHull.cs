using UnityEngine;

[System.Serializable]
public struct ShieldedHull : IDamageable
{
    public float hull;
    public float shields;

    public void ApplyDamage(Damage damage)
    {
        this.shields = Mathf.Max(0, this.shields - damage.energy);
        if (Mathf.Approximately(this.shields, 0))
        {
            this.hull = Mathf.Max(0, this.hull - damage.physical);
        }
    }

    public bool IsDestroyed()
    {
        Debug.Assert(this.shields >= 0);
        Debug.Assert(this.hull >= 0);
        return Mathf.Approximately(this.shields, 0) && Mathf.Approximately(this.hull, 0);
    }

    public override string ToString()
    {
        return $"ShieldedHull(hull = {hull}, shields = {shields})";
    }
}
