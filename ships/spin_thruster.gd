extends Resource
class_name SpinThruster

## Defines a thruster that spins a ship.

## The maximum turning rate, in rad/s.
@export var turning_rate: float

## How much power the thruster consumes per second when turning at full speed.
@export var power_consumption_rate: float
