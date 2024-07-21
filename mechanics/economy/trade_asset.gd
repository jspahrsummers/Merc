extends Resource
class_name TradeAsset

## Represents any asset that can be traded.

## The human-readable name for this asset.
@export var name: String

## How many pieces one unit of this asset can be subdivided into. Internal representations of amounts of this asset will be multiplied by this value.
##
## This allows us to use [int]s for computing fractional amounts of this asset, without the precision loss of floating-point math.
@export var granularity: int = 1

func _to_string() -> String:
    return "TradeAsset:" + self.name
