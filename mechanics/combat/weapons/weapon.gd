extends Resource
class_name Weapon

## Defines the properties of a weapon.

## The minimum interval (in seconds) between the weapon firing successively.
@export var fire_interval: float

## The force with which the weapon fires (in N).
@export var fire_force: float

## The amount of power required to fire the weapon.
##
## If the containing ship's available power is less than this amount, the weapon won't be able to fire.
@export var power_consumption: float

## The projectile that this weapon fires. The root node [b]must[/b] be a [RigidBody3D].
@export var projectile: PackedScene
