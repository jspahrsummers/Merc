extends Resource
class_name Battery

## Represents a battery that can hold power and be recharged, and from which power can be consumed.

## The maximum power capacity for this battery.
@export var max_power: float:
    set(value):
        assert(value >= 0.0, "Power capacity must be non-negative")
        if is_equal_approx(max_power, value):
            return

        max_power = value
        self.emit_changed()

## The current power level of this battery.
@export var power: float:
    set(value):
        if is_equal_approx(power, value):
            return

        power = clampf(value, 0.0, self.max_power)
        self.emit_changed()

## Consumes up to the given amount of power.
## 
## Returns the amount of power actually consumed, which may be less than requested if the battery does not have the full amount.
func consume_up_to(amount: float) -> float:
    var consumed := minf(amount, self.power)
    self.power -= consumed
    return consumed

## Consumes exactly the requested amount of power, or returns false if the battery does not have enough.
func consume_exactly(amount: float) -> bool:
    if self.power < amount:
        return false
    
    self.power -= amount
    return true

## Recharges the battery by the given amount, up to its maximum capacity.
##
## Returns the amount of power actually recharged, which may be less than requested if the battery does not have enough capacity for the full amount.
func recharge(amount: float) -> float:
    var charged := minf(amount, self.max_power - self.power)
    self.power += charged
    return charged
