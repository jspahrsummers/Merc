[System.Serializable]
public sealed class PlayerState
{
    public string username;
    public long credits = 100000;
    public string currentSystem = "Sol";

    public override string ToString()
    {
        return $"PlayerState(username = {username}, credits = {credits}, currentSystem = {currentSystem})";
    }
}