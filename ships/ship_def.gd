extends Resource
class_name ShipDef

## Defines a ship type and its base properties.

## The mass of the ship (in kg), to be applied to the ship's rigidbody.
@export var mass_kg: float

## The max hull strength of the ship, representing the damage it can withstand.
@export var hull: float

## The max shield strength of the ship, representing the damage it can withstand.
@export var shield: float

## The force of the ship's thrust (in N), when the throttle is fully opened.
@export var thrust: float

## The maximum turn speed of the ship (in rad/s).
##
## Despite the name, this is not actually a torque force as such.
@export var torque: float

## When arriving from a hyperspace jump, the ship's position will be randomized around the system center. This is the maximum radius (in m) that the randomized position is allowed to occupy.
@export var hyperspace_arrival_radius: float

## The maximum energy capacity of the ship.
@export var energy: float

## The rate at which the ship's energy recharges per second.
@export var energy_recharge_rate: float

## The amount of energy consumed per second when thrusting at full power.
##
## If available energy is less than this amount, partial thrust will be applied.
@export var thrust_energy_consumption: float

## The amount of energy consumed per second while turning.
##
## Unlike thrust, energy is not consumed proportionally to the amount actually turned; this is a flat rate. If available energy is less than this amount but greater than 0, turning will still work.
@export var turning_energy_consumption: float

## The rate at which shields recharge per second when energy is available, and the corresponding rate at which energy is drained.
##
## If available energy is less than this amount, the shield will not recharge; this is done to reserve power for maneuvering.
@export var shield_recharge_rate: float

## The built-in weapons of this ship.
@export var weapons: Array[Weapon] = []
