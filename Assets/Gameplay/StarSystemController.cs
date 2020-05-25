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
    public GameObject hyperspaceFadePrefab;

    public void JumpToAdjacentSystem(AdjacentSystem system)
    {
        StartCoroutine(LoadSceneAsync(system.name));
    }

    private IEnumerator LoadSceneAsync(string sceneName)
    {
        AsyncOperation asyncLoad = SceneManager.LoadSceneAsync(sceneName);
        asyncLoad.allowSceneActivation = false;

        while (!asyncLoad.isDone)
        {
            if (asyncLoad.progress >= 0.9f)
            {
                DontDestroyOnLoad(Instantiate(hyperspaceFadePrefab));
                asyncLoad.allowSceneActivation = true;
            }

            yield return null;
        }
    }
}
