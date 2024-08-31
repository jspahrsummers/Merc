extends Outfit
class_name CargoHoldExpansionOutfit

## The additional cargo capacity provided by this outfit in cubic meters.
@export var additional_capacity: float

func _init() -> void:
    self.type = OutfitType.CARGO_HOLD

func apply_to_ship(ship: Ship) -> void:
    if ship.cargo_hold:
        ship.cargo_hold.max_volume += additional_capacity

func remove_from_ship(ship: Ship) -> void:
    if ship.cargo_hold:
        ship.cargo_hold.max_volume -= additional_capacity

func get_description() -> String:
    return "Increases cargo capacity by %s m³" % additional_capacity