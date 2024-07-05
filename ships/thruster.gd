extends Resource
class_name Thruster

## Defines a thruster for a ship.

## The force of the thruster (in N), when the throttle is fully opened.
@export var thrust_force: float

## How much power the thruster consumes per second when thrusting at full power.
@export var power_consumption_rate: float
