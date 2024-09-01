extends Resource
class_name Outfit

## Represents a ship outfit or component that can be installed on a ship.
##
## For game balance, the number of outfits that can be installed on any given ship can be limited in a variety of ways:
## - Weapons are limited by the number of weapon mounts (hardpoints) available.
## - Outfits add to a ship's mass, reducing its ability to accelerate and manuever.
## - Outfits may require power, which is limited by the ship's battery.

# TODO: Heat
# TODO: Power consumption

## The human-readable name of this outfit.
@export var name: String

## A human-readable BBCode description of this outfit.
@export_multiline var description: String

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

## How much of the purchase price is refunded when uninstalling this outfit.
const REFUND_PERCENTAGE = 0.75

## Whether this outfit is able to be installed onto the given ship.
func can_install_onto_ship(ship: Ship) -> bool:
    if self.weapon:
        var mount_available := false
        for mount in ship.weapon_mounts:
            if not mount.weapon:
                mount_available = true
                break
        
        if not mount_available:
            return false
    
    # TODO: Limit other types of outfits (e.g., based on hardpoints), to prevent infinite accumulation of benefits.
    return true

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
