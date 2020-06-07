public struct HyperspaceJump
{
    public StarSystemScriptableObject fromSystem;
    public StarSystemScriptableObject toSystem;

    public float angle => fromSystem.AngleToSystem(toSystem);

    public override string ToString()
    {
        return $"HyperspaceJump(from {fromSystem} to {toSystem})";
    }
}
