extends SaveableResource
class_name Outfit

## Represents a ship outfit or component that can be installed on a ship.

## The human-readable name of this outfit.
@export var name: String

## A human-readable BBCode description of this outfit.
@export var description: String

## The mass of this outfit in kilograms.
@export var mass: float

## The price of this outfit in credits.
@export var price_in_credits: float

## Additional cargo capacity provided, in cubic meters.
@export var additional_cargo_capacity: float = 0

## Additional fuel capacity provided.
@export var additional_fuel_capacity: float = 0

## Additional shield capacity provided.
@export var additional_shield_capacity: float = 0

## A multiplier to apply to shield recharge rate.
@export var shield_recharge_multiplier: float = 1.0

## A weapon provided by this outfit.
@export var weapon: Weapon

## Apply the effects of this outfit to a ship, or returns false if the outfit cannot be installed.
func apply_to_ship(ship: Ship) -> bool:
    if self.weapon:
        var weapon_mount: WeaponMount = null
        for mount in ship.weapon_mounts:
            if not mount.weapon:
                weapon_mount = mount
                break
        
        if not weapon_mount:
            return false
        
        weapon_mount.weapon = self.weapon

    ship.mass += self.mass

    if ship.cargo_hold:
        ship.cargo_hold.max_volume += self.additional_cargo_capacity

    if ship.hyperdrive:
        ship.hyperdrive.max_fuel += self.additional_fuel_capacity

    if ship.shield:
        ship.shield.max_integrity += self.additional_shield_capacity
        ship.shield.recharge_rate *= self.shield_recharge_multiplier
    
    return true

## Remove the effects of this outfit from a ship.
func remove_from_ship(ship: Ship) -> void:
    ship.mass -= self.mass

    if ship.cargo_hold:
        ship.cargo_hold.max_volume -= self.additional_cargo_capacity

    if ship.hyperdrive:
        ship.hyperdrive.max_fuel -= self.additional_fuel_capacity

    if ship.shield:
        ship.shield.max_integrity -= self.additional_shield_capacity
        ship.shield.recharge_rate /= self.shield_recharge_multiplier
    
    if self.weapon:
        for mount in ship.weapon_mounts:
            if mount.weapon == self.weapon:
                mount.weapon = null
                break

## Returns the list of effects provided by this outfit, as BBCode formatted strings.
func get_effects() -> PackedStringArray:
    var effects := PackedStringArray()

    if not is_zero_approx(self.additional_cargo_capacity):
        effects.push_back("[b]Additional cargo capacity:[/b] %s m³" % self.additional_cargo_capacity)

    if not is_zero_approx(self.additional_fuel_capacity):
        effects.push_back("[b]Additional fuel capacity:[/b] %s hyperjumps" % self.additional_fuel_capacity)

    if not is_zero_approx(self.additional_shield_capacity):
        effects.push_back("[b]Additional shield capacity:[/b] %s" % self.additional_shield_capacity)

    if not is_equal_approx(self.shield_recharge_multiplier, 1.0):
        effects.push_back("[b]Shield recharge rate:[/b] %s%%" % [self.shield_recharge_multiplier * 100])

    if self.weapon:
        effects.push_back("[b]Fire interval:[/b] %ss" % [self.weapon.fire_interval])
        effects.push_back("[b]Power consumption per shot:[/b] %s" % [self.weapon.power_consumption])

    return effects
