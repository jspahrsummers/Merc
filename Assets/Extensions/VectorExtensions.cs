using UnityEngine;

namespace VectorExtensions
{
    public static class Extension
    {
        public static float AsTime(this Vector2 timeVector)
        {
            if (timeVector.x >= 0 && timeVector.y >= 0)
            {
                return timeVector.magnitude;
            }
            else
            {
                return Mathf.Infinity;
            }
        }
    }
}