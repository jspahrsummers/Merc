extends Resource
class_name Damage

## Represents an amount of damage to be dealt.

## How much damage will be done to shields.
##
## If a damageable object has shields, damage is applied to the shields first, then the hull, in proportion.
@export var shield_damage: float

## How much damage will be done to a hull.
##
## If a damageable object has shields, damage is applied to the shields first, then the hull, in proportion.
@export var hull_damage: float

## How much heat will be inflicted on the target.
##
## Heat is not directly damaging, but can result in a ship becoming disabled.
@export var heat: float
