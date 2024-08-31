extends Outfit
class_name WeaponOutfit

## The damage dealt by this weapon.
@export var damage: float

## The range of this weapon in meters.
@export var range: float

## The rate of fire in shots per second.
@export var fire_rate: float

func _init() -> void:
    self.type = OutfitType.WEAPON

func apply_to_ship(ship: Ship) -> void:
    # TODO: Implement adding weapon to ship's weapon systems
    pass

func remove_from_ship(ship: Ship) -> void:
    # TODO: Implement removing weapon from ship's weapon systems
    pass

func get_description() -> String:
    return "Damage: %s\nRange: %s m\nFire Rate: %s shots/s" % [damage, range, fire_rate]