using UnityEngine;

namespace MercExtensions
{
    public static class QuaternionExtensions
    {
        /// <summary>Approximately compares two Quaternions for equality, where `tolerance` is a normalized distance (between 0 and 1).</summary>
        public static bool ApproximatelyEquals(this Quaternion first, Quaternion second, float tolerance)
        {
            return 1 - Mathf.Abs(Quaternion.Dot(first, second)) <= tolerance;
        }
    }
}
