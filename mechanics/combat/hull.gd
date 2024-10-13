extends SaveableResource
class_name Hull

## Represents a hull that can take damage.

## The maximum possible integrity for this hull.
@export var max_integrity: float:
    set(value):
        value = maxf(0.0, value)
        if is_equal_approx(max_integrity, value):
            return
        
        max_integrity = value
        self.emit_changed()

## The current hull integrity.
@export var integrity: float:
    set(value):
        value = clampf(value, 0.0, self.max_integrity)
        if is_equal_approx(integrity, value):
            return
        
        integrity = value
        self.emit_changed()

        if integrity <= 0.01:
            self.hull_destroyed.emit(self)

## Fires when the hull is destroyed (i.e., its integrity reaches zero).
##
## Note that the node will not be automatically removed from the scene tree.
signal hull_destroyed(hull: Hull)

## Whether this hull has been destroyed.
func is_destroyed() -> bool:
    return self.integrity <= 0.01
