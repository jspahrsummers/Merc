extends TradeAsset
class_name Commodity

## Represents a physical commodity that can be traded.

## The [b]in-game mass[/b] per one unit of this item, in kg.
##
## This is added to ship mass when the asset is being carried. This can also be thought of the scaling factor from "real-world kg" (it usually makes sense to consider 1 unit = 1 real-world kg) to in-game mass for the physics engine.
@export var mass: float = 0.1

## The volume of one unit of this item, in liters.
##
## This can be thought of as the volume per "real-world kg."
@export var volume: float

func _to_string() -> String:
    return "Commodity:" + self.name
