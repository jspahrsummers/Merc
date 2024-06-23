extends Resource
class_name WeaponDef

## Defines a weapon type and its base properties.

## The minimum interval (in ms) between the weapon firing successively.
@export var fire_interval_msec: int

## The force with which the weapon fires (in N).
@export var fire_force: float

## The amount of energy required to fire the weapon.
##
## If the containing ship's available energy is less than this amount, the weapon won't be able to fire.
@export var energy_consumption: float
