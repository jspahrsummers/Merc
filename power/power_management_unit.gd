extends Node
class_name PowerManagementUnit

## Manages power generation and consumption.

## A battery storing power.
@export var battery: Battery

## An optional power generator to automatically recharge the battery.
@export var power_generator: PowerGenerator

func _ready() -> void:
    self.set_physics_process(self.battery != null and self.power_generator != null)

func _physics_process(delta: float) -> void:
    self.battery.power += self.power_generator.rate_of_power * delta
