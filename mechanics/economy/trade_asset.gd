extends Resource
class_name TradeAsset

## Represents an asset that can be traded, like a commodity or a currency.

## The human-readable name for this asset.
@export var name: String

## Whether this asset is tangible (i.e., physical in nature), as opposed to entirely digital.
##
## Intangible assets have no mass.
@export var tangible: bool = true

## The volume of one kilogram of this item, in liters.
##
## This should be set to 0 if [member tangible] is false.
@export var volume_per_kg: float

## Whether this asset is considered a currency.
##
## This affects UI/UX more than anything: it's easier for a player to see their currencies at a glance.
@export var currency: bool = false

func _to_string() -> String:
    return "TradeAsset:" + self.name
