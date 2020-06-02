using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;

public sealed class StarSystemController : MonoBehaviour
{
    public StarSystemScriptableObject starSystem;
    public GameObject hyperspaceArrivalPrefab;

    public void JumpToSystem(StarSystemScriptableObject newSystem)
    {
        StartCoroutine(LoadSystemAsync(newSystem));
    }

    private IEnumerator LoadSystemAsync(StarSystemScriptableObject newSystem)
    {
        AsyncOperation asyncLoad = SceneManager.LoadSceneAsync(newSystem.name);
        asyncLoad.allowSceneActivation = false;

        while (!asyncLoad.isDone)
        {
            if (asyncLoad.progress >= 0.9f)
            {
                GameObject arrival = Instantiate(hyperspaceArrivalPrefab);
                var arrivalController = arrival.GetComponent<HyperspaceArrivalController>();
                arrivalController.arrivalAngle = starSystem.AngleToSystem(newSystem);
                DontDestroyOnLoad(arrival);

                asyncLoad.allowSceneActivation = true;
            }

            yield return null;
        }
    }
}
