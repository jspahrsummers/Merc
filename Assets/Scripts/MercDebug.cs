using UnityEngine;

public static class MercDebug
{
    [System.Diagnostics.Conditional("UNITY_ASSERTIONS")]
    public static void Invariant(bool condition, object message)
    {
        if (condition)
        {
            return;
        }

        Debug.LogAssertion(message);
        Debug.Break();
    }

    public static void EnforceField<T>(T value)
    {
        Invariant(value != null, $"Field of type {typeof(T)} was not initialized");
    }
}