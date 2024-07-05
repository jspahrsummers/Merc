extends Resource
class_name PowerGenerator

## Represents a generator of power.

## How much power this generator produces per second.
@export var rate_of_power: float:
    set(value):
        assert(value >= 0.0, "Power generation rate must be non-negative")
        if is_equal_approx(rate_of_power, value):
            return

        rate_of_power = value
        self.emit_changed()
