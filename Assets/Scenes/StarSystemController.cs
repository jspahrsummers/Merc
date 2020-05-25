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
        public float angle;
    }

    public AdjacentSystem[] adjacentSystems;
    public GameObject hyperspaceArrivalPrefab;

    public void JumpToAdjacentSystem(AdjacentSystem system)
    {
        StartCoroutine(LoadSystemAsync(system));
    }

    private IEnumerator LoadSystemAsync(AdjacentSystem system)
    {
        AsyncOperation asyncLoad = SceneManager.LoadSceneAsync(system.name);
        asyncLoad.allowSceneActivation = false;

        while (!asyncLoad.isDone)
        {
            if (asyncLoad.progress >= 0.9f)
            {
                GameObject arrival = Instantiate(hyperspaceArrivalPrefab);
                var arrivalController = arrival.GetComponent<HyperspaceArrivalController>();
                arrivalController.arrivalAngle = system.angle;
                DontDestroyOnLoad(arrival);

                asyncLoad.allowSceneActivation = true;
            }

            yield return null;
        }
    }
}
