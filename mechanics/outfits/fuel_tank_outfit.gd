extends Outfit
class_name FuelTankOutfit

## The additional fuel capacity provided by this outfit.
@export var additional_capacity: float

func _init() -> void:
    self.type = OutfitType.FUEL_TANK

func apply_to_ship(ship: Ship) -> void:
    if ship.hyperdrive:
        ship.hyperdrive.max_fuel += additional_capacity

func remove_from_ship(ship: Ship) -> void:
    if ship.hyperdrive:
        ship.hyperdrive.max_fuel -= additional_capacity

func get_description() -> String:
    return "Increases fuel capacity by %s units" % additional_capacity