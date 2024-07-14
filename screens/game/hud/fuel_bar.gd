extends Control

@export var background: NinePatchRect
@export var fill: NinePatchRect

const PIP_WIDTH = 8

var max_fuel: float:
    set(value):
        max_fuel = value
        self.background.size.x = self.max_fuel * PIP_WIDTH

var fuel: float:
    set(value):
        fuel = value
        self.fill.size.x = self.fuel * PIP_WIDTH

func _ready() -> void:
    self.max_fuel = 11.5
    self.fuel = 5.2
