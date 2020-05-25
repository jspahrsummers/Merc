using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class StarSystemController : MonoBehaviour
{
    [System.Serializable]
    public struct AdjacentSystem
    {
        public string name;
        public float eulerAngle;
    }

    public AdjacentSystem[] adjacentSystems;

    public void JumpToAdjacentSystem(AdjacentSystem system)
    {
        StartCoroutine(LoadSceneAsync(system.name));
    }

    private IEnumerator LoadSceneAsync(string sceneName)
    {
        AsyncOperation asyncLoad = SceneManager.LoadSceneAsync(sceneName);

        while (!asyncLoad.isDone)
        {
            yield return null;
        }
    }
}
