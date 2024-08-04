extends Node3D
class_name PowerManagementUnit

## Manages power generation and consumption.

## An optional power generator to automatically recharge the battery.
@export var power_generator: PowerGenerator:
    set(value):
        power_generator = value
        self.set_physics_process(self.battery != null and power_generator != null)

## A battery storing power.
var battery: Battery:
    set(value):
        battery = value
        self.set_physics_process(battery != null and self.power_generator != null)

func _physics_process(delta: float) -> void:
    self.battery.recharge(self.power_generator.rate_of_power * delta)
