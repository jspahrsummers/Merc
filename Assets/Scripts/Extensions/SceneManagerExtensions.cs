using UnityEngine;
using UnityEngine.SceneManagement;

namespace MercExtensions
{
    public static class SceneManagerExtensions
    {
        /// <summary>Attempts to look up a loaded scene by its path (first) or else its name, or else returns null.</summary>
        public static Scene? GetSceneByPathOrName(string s)
        {
            Scene scene = SceneManager.GetSceneByPath(s);
            if (scene.IsValid())
            {
                return scene;
            }

            scene = SceneManager.GetSceneByName(s);
            if (scene.IsValid())
            {
                return scene;
            }

            return null;
        }
    }
}
