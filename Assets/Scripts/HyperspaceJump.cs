/// <summary>Describes a hyperspace jump, whether proposed, in progress, or completed.</summary>
[System.Serializable]
public readonly struct HyperspaceJump
{
    /// <summary>The system that the jump originates from.</summary>
    public readonly string fromSystem;

    /// <summary>The system that the jump completes in.</summary>
    public readonly string toSystem;

    public HyperspaceJump(string fromSystem, string toSystem)
    {
        this.fromSystem = fromSystem;
        this.toSystem = toSystem;
    }

    public override string ToString()
    {
        return $"HyperspaceJump(fromSystem = {fromSystem}, toSystem = {toSystem})";
    }
}