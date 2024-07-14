extends Control

@export var background: NinePatchRect
@export var fill: NinePatchRect

const PIP_WIDTH = 10

var max_fuel: float:
    set(value):
        max_fuel = value
        self.background.custom_minimum_size.x = self.max_fuel * PIP_WIDTH

var fuel: float:
    set(value):
        fuel = value
        self.fill.size.x = self.fuel * PIP_WIDTH

func _on_player_hyperdrive_changed(_player: Player, hyperdrive: Hyperdrive) -> void:
    self.max_fuel = hyperdrive.max_fuel
    self.fuel = hyperdrive.fuel
