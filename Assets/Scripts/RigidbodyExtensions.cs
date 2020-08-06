using UnityEngine;

namespace MercExtensions
{
    static class RigidbodyExtensions
    {
        /// <summary>Calculates the position that this rigidbody will occupy after <paramref name="time"/> seconds have elapsed, assuming its current velocity is maintained.</summary>
        public static Vector3 ExtrapolatePositionAfterTime(this Rigidbody rigidbody, float time)
        {
            return rigidbody.position + rigidbody.velocity * time;
        }
    }
}
