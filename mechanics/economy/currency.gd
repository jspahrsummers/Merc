extends Resource
class_name Currency

## Represents a currency that can be used to pay for goods and services.

## The human-readable name for this currency.
@export var name: String

## The [b]in-game mass[/b] per one unit of this item, in kg.
##
## This is added to ship mass when the asset is being carried.
@export var mass: float = 0.0

## The volume of one unit of this item, in liters.
@export var volume: float = 0.0

## How many pieces one unit of currency can be subdivided into.
##
## This allows us to use [int]s for computing fractional currency values, without the precision loss of floating-point math.
const GRANULARITY: int = 100;

func _to_string() -> String:
    return "Currency:" + self.name
