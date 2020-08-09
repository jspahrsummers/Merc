using UnityEngine;
using Mirror;

/// <summary>Enables or disables the ping display for a client.</summary>
public sealed class PingDisplayController : MonoBehaviour
{
    void Start()
    {
        if (NetworkManager.singleton.mode != NetworkManagerMode.ClientOnly)
        {
            gameObject.SetActive(false);
        }
    }
}
