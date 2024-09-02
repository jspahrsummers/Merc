extends Node3D
class_name PowerManagementUnit

## Manages power generation and consumption.

## An optional power generator to automatically recharge the battery.
@export var power_generator: PowerGenerator:
    set(value):
        power_generator = value
        self.set_physics_process(power_generator != null)

## A battery storing power.
var battery: Battery

## A sink for absorbing heat.
var heat_sink: HeatSink

func _physics_process(delta: float) -> void:
    self.battery.recharge(self.power_generator.rate_of_power * delta)
    self.heat_sink.heat += self.power_generator.rate_of_heat * delta
