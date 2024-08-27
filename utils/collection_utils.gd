class_name CollectionUtils

## Finds the next object in [param array] after [param starting_from], wrapping around to `null` if the end of the array is reached.
static func cycle_through(array: Array, starting_from: Variant) -> Variant:
    if array.size() == 0:
        return null
    
    if starting_from == null:
        return array[0]
    
    var index := array.find(starting_from)
    assert(index >= 0, "Cannot find starting_from in array")

    return array[index + 1] if index + 1 < array.size() else null

## Picks a random item from the keys of the given dictionary, with the probability of each item being picked weighted by the corresponding floating-point value.
static func weighted_random_choice(weights: Dictionary) -> Variant:
    var total_weight := 0.0
    for weight: float in weights.values():
        total_weight += weight
    
    var random_value := randf_range(0.0, total_weight)
    var current_weight := 0.0

    for item: Variant in weights:
        current_weight += weights[item]
        if random_value <= current_weight:
            return item
    
    # Probably a floating point imprecision issue; pick the last one
    return weights.keys().back()
