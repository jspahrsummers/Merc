class_name MathUtils

## Microseconds per second.
const USEC_PER_SEC = 1000000

## Microseconds per second, floating point.
const USEC_PER_SEC_F = USEC_PER_SEC as float

## Returns a unit vector pointing in a random (2D) angle.
##
## This vector can be multiplied with a desired radius to get a random position within a circle.
static func random_unit_vector() -> Vector3:
    var angle := randf_range(0, 2 * PI)
    return Vector3(cos(angle), 0, sin(angle))

## Converts a relative price (between 0 and 1, inclusive) to an absolute price, given a base price and a maximum deviation.
static func relative_to_absolute_price(relative_price: float, base_price: float, max_deviation: float) -> float:
    assert(relative_price >= 0.0 and relative_price <= 1.0, "Relative price is out of bounds")
    
    var deviation := (relative_price - 0.5) * 2 * max_deviation
    return base_price * (1 + deviation)
