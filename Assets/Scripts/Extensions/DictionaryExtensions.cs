using System.Collections.Generic;

namespace DictionaryExtensions
{
    public static class Extension
    {
        public static V GetValueOrDefault<K, V>(this IDictionary<K, V> dictionary, K key, V defaultValue)
        {
            V result;
            if (dictionary.TryGetValue(key, out result))
            {
                return result;
            }
            else
            {
                return defaultValue;
            }
        }
    }
}