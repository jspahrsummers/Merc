extends Outfit
class_name ShieldBoosterOutfit

## The additional shield capacity provided by this outfit.
@export var additional_capacity: float

## The improvement to shield recharge rate (as a multiplier).
@export var recharge_rate_multiplier: float = 1.0

func _init() -> void:
    self.type = OutfitType.SHIELD

func apply_to_ship(ship: Ship) -> void:
    if ship.shield:
        ship.shield.max_integrity += additional_capacity
        ship.shield.recharge_rate *= recharge_rate_multiplier

func remove_from_ship(ship: Ship) -> void:
    if ship.shield:
        ship.shield.max_integrity -= additional_capacity
        ship.shield.recharge_rate /= recharge_rate_multiplier

func get_description() -> String:
    var description = "Increases shield capacity by %s units" % additional_capacity
    if recharge_rate_multiplier != 1.0:
        description += "\nImproves shield recharge rate by %s%%" % ((recharge_rate_multiplier - 1) * 100)
    return description