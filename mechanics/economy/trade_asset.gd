extends Resource
class_name TradeAsset

## Represents an asset that can be traded, like a commodity or a currency.

## The human-readable name for this asset.
@export var name: String

## The [b]in-game mass[/b] per one unit of this item, in kg.
##
## This is added to ship mass when the asset is being carried. This can also be thought of the scaling factor from "real-world kg" (it usually makes sense to consider 1 unit = 1 real-world kg) to in-game mass for the physics engine.
@export var mass: float = 0.1

## The volume of one unit of this item, in liters.
##
## This can be thought of as the volume per "real-world kg."
@export var volume: float

## Whether this asset is considered a currency.
##
## This affects UI/UX more than anything: it's easier for a player to see their currencies at a glance.
@export var currency: bool = false

func _to_string() -> String:
    return "TradeAsset:" + self.name
