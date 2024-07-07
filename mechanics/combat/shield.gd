extends Resource
class_name Shield

## Represents shields that can take damage.

## The maximum possible integrity for this shield.
@export var max_integrity: float:
    set(value):
        value = maxf(0.0, value)
        if is_equal_approx(max_integrity, value):
            return
        
        max_integrity = value
        self.emit_changed()

## The current shield integrity.
@export var integrity: float:
    set(value):
        value = clampf(value, 0.0, self.max_integrity)
        if is_equal_approx(integrity, value):
            return
        
        integrity = value
        self.emit_changed()

## The rate (integrity per second) at which this shield recharges when powered.
##
## Can be set to 0 to disable recharge.
@export var recharge_rate: float:
    set(value):
        value = maxf(0.0, value)
        if is_equal_approx(recharge_rate, value):
            return
        
        recharge_rate = value
        self.emit_changed()

## The efficiency of this shield's power consumption, expressed as a ratio of shield integrity to power.
##
## For recharging, this is how much shield integrity will increase for each unit of power.
@export_range(0.0, 10.0, 0.5, "or_greater") var power_efficiency: float = 1.0:
    set(value):
        value = maxf(0.0, value)
        if is_equal_approx(power_efficiency, value):
            return
        
        power_efficiency = value
        self.emit_changed()
