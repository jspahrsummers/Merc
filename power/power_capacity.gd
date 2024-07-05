extends Resource
class_name PowerCapacity

## Represents the capacity something has for holding power.

## The power capacity.
@export var capacity: float:
    set(value):
        assert(value >= 0.0, "Power capacity must be non-negative")
        if is_equal_approx(capacity, value):
            return

        capacity = value
        self.emit_changed()
