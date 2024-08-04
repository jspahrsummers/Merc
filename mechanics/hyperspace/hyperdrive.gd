extends SaveableResource
class_name Hyperdrive

## Represents a hyperspace drive and its fuel.
##
## A single unit of hyperspace fuel represents enough fuel to jump to a neighboring star system.

## The maximum fuel level for this drive.
@export var max_fuel: float:
    set(value):
        assert(value >= 0.0, "Power capacity must be non-negative")
        if is_equal_approx(max_fuel, value):
            return

        max_fuel = value
        self.emit_changed()

## The current fuel level of this drive.
@export var fuel: float:
    set(value):
        if is_equal_approx(fuel, value):
            return

        fuel = clampf(value, 0.0, self.max_fuel)
        self.emit_changed()

## Whether there is enough fuel to make a hyperspace jump.
func can_jump() -> bool:
    return self.fuel >= 1.0

## Consumes fuel for one hyperspace jump, or returns false if there isn't enough fuel.
func consume_for_jump() -> bool:
    if not self.can_jump():
        return false
    
    self.fuel -= 1.0
    return true

## Refuel by the given amount, up to the maximum fuel.
##
## Returns the amount actually refueled, which may be less than requested if there's not enough capacity for the full amount.
func refuel(amount: float) -> float:
    var charged := minf(amount, self.max_fuel - self.fuel)
    self.fuel += charged
    return charged
