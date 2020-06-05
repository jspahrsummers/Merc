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

        public static float AngleToward(this Vector2 from, Vector2 to)
        {
            Vector2 direction = to - from;
            return Mathf.Atan2(direction.y, direction.x) * Mathf.Rad2Deg - 90;
        }
    }
}