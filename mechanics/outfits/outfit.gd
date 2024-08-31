extends Resource
class_name Outfit

## Represents a ship outfit or component that can be installed on a ship.

## The human-readable name of this outfit.
@export var name: String

## The mass of this outfit in kilograms.
@export var mass: float

## The volume this outfit occupies in cubic meters.
@export var volume: float

## The power consumption of this outfit in watts.
@export var power_consumption: float

## The cost of this outfit in credits.
@export var cost: int

## The type of this outfit (e.g., weapon, cargo hold, fuel tank, shield, engine).
enum OutfitType {
    WEAPON,
    CARGO_HOLD,
    FUEL_TANK,
    SHIELD,
    ENGINE,
    MISCELLANEOUS
}
@export var type: OutfitType

## Apply the effects of this outfit to a ship.
## This method should be overridden by specific outfit types.
func apply_to_ship(_ship: Ship) -> void:
    pass

## Remove the effects of this outfit from a ship.
## This method should be overridden by specific outfit types.
func remove_from_ship(_ship: Ship) -> void:
    pass

## Returns a description of the outfit's effects.
## This method should be overridden by specific outfit types.
func get_description() -> String:
    return "A ship outfit."