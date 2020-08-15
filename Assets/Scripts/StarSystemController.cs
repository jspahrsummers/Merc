using UnityEngine;
using UnityEngine.SceneManagement;
using Mirror;

/// <summary>Placed in every star system (scene) to manage scene-specific logic.</summary>
/// <remarks>This class is also responsible for spawning the GameController if one does not exist yet.</remarks>
public sealed class StarSystemController : NetworkBehaviour
{
    [Tooltip("A damageable object to automatically spawn repeatedly, for the player(s) to destroy.")]
    public DamageableController frigatePrefab;

    /// <summary>Spawned objects will be randomly offset between negative and positive values of this number, along X and Y axes.</summary>
    const float RandomTranslationRange = 10;

    public override void OnStartServer()
    {
        SpawnFrigate();
    }

    [Server]
    private void SpawnFrigate()
    {
        var position = new Vector3(Random.Range(-RandomTranslationRange, RandomTranslationRange), Random.Range(-RandomTranslationRange, RandomTranslationRange), 0);
        var rotation = Quaternion.Euler(-90, 0, 0) * Quaternion.AngleAxis(Random.Range(0, 360), Vector3.up);
        var frigate = Instantiate<DamageableController>(frigatePrefab, position, rotation);
        frigate.destroyed.AddListener(FrigateDestroyed);
        SceneManager.MoveGameObjectToScene(frigate.gameObject, gameObject.scene);
        NetworkServer.Spawn(frigate.gameObject);
    }

    /// <summary>Event handler when the spawned frigate has been destroyed by a player.</summary>
    [Server]
    public void FrigateDestroyed(DamageableController controller)
    {
        SpawnFrigate();
    }
}
