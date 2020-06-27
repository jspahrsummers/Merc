[System.Serializable]
public readonly struct Damage
{
    public readonly float physical;
    public readonly float energy;

    public override string ToString()
    {
        return $"Damage(physical = {physical}, energy = {energy})";
    }
}
