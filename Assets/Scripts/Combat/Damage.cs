[System.Serializable]
public struct Damage
{
    public float physical;
    public float energy;

    public override string ToString()
    {
        return $"Damage(physical = {physical}, energy = {energy})";
    }
}
