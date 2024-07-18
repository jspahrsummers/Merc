class_name ArrayUtils

## Finds the next object in [param array] after [param starting_from], wrapping around to `null` if the end of the array is reached.
static func cycle_through(array: Array, starting_from: Variant) -> Variant:
    if array.size() == 0:
        return null
    
    if starting_from == null:
        return array[0]
    
    var index := array.find(starting_from)
    assert(index >= 0, "Cannot find starting_from in array")

    return array[index + 1] if index + 1 < array.size() else null
