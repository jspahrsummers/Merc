extends Node

## Returns a unit vector pointing in a random (2D) angle.
##
## This vector can be multiplied with a desired radius to get a random position within a circle.
func random_unit_vector() -> Vector3:
    var angle := randf_range(0, 2 * PI)
    return Vector3(cos(angle), 0, sin(angle))
