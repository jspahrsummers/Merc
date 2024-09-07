extends Resource
class_name Outfit

## Represents a ship outfit or component that can be installed on a ship.
##
## For game balance, the number of outfits that can be installed on any given ship can be limited in a variety of ways:
## - Weapons are limited by the number of weapon mounts (hardpoints) available.
## - Outfits add to a ship's mass, reducing its ability to accelerate and manuever.
## - Outfits may require constant power, which is limited by the ship's power generator.
## - Outfits may consume cargo space, which could otherwise be used to carry more trade or mission commodities.

## The human-readable name of this outfit.
@export var name: String

## A human-readable BBCode description of this outfit.
@export_multiline var description: String

## The mass of this outfit in kilograms.
@export var mass: float

## The price of this outfit in credits.
@export var price_in_credits: float

## A modification this outfit makes to cargo capacity, in cubic meters.
##
## If negative, the capacity of the ship's [CargoHold] will be reduced. The outfit cannot be installed if the available space in the cargo hold is insufficient.
@export var modified_cargo_capacity: float = 0

## A modification this outfit makes to passenger quarters capacity.
##
## If negative, the capacity of the ship's [PassengerQuarters] will be reduced. The outfit cannot be installed if the available space in the passenger quarters is insufficient.
@export var modified_passenger_capacity: int = 0

## A modification this outfit makes to fuel capacity.
##
## If negative, the fuel capacity of the ship's [Hyperdrive] will be reduced. The outfit cannot be installed if the available fuel capacity is insufficient.
@export var modified_fuel_capacity: float = 0

## A modification this outfit makes to maximum hull integrity.
##
## If negative, the maximum integrity of the ship's [Hull] will be reduced. The outfit cannot be installed if the maximum hull integrity is insufficient.
@export var modified_hull_capacity: float = 0

## A modification this outfit makes to shield capacity.
##
## If negative, the maximum integrity of the ship's [Shield] will be reduced. The outfit cannot be installed if the maximum shield integrity is insufficient.
@export var modified_shield_capacity: float = 0

## A multiplier to apply to shield recharge rate.
@export var shield_recharge_multiplier: float = 1.0

## A modification to the ship's power generation, as an amount added or removed per second.
##
## If negative, the output of the ship's [PowerGenerator] will be reduced by this amount. The outfit cannot be installed if the [PowerGenerator] is insufficient.
@export var modified_power_generation: float = 0

## A modification this outfit makes to heat sink capacity.
##
## If negative, the capacity of the ship's [HeatSink] will be reduced. The outfit cannot be installed if the available heat capacity is insufficient.
@export var modified_heat_capacity: float = 0

## A weapon provided by this outfit.
@export var weapon: Weapon

## How much of the purchase price is refunded when uninstalling this outfit.
const REFUND_PERCENTAGE = 0.75

## Whether this outfit is able to be installed onto the given ship.
func can_install_onto_ship(ship: Ship) -> bool:
    if not is_zero_approx(self.modified_cargo_capacity):
        var cargo_hold := ship.cargo_hold
        if not cargo_hold:
            return false
        
        var available_volume := cargo_hold.max_volume - cargo_hold.get_occupied_volume()
        if available_volume + self.modified_cargo_capacity < 0:
            return false
    
    if self.modified_passenger_capacity != 0:
        var passenger_quarters := ship.passenger_quarters
        if not passenger_quarters:
            return false
        
        var available_spaces := passenger_quarters.total_spaces - passenger_quarters.occupied_spaces
        if available_spaces + self.modified_passenger_capacity < 0:
            return false
    
    if not is_zero_approx(self.modified_fuel_capacity):
        var hyperdrive := ship.hyperdrive
        if not hyperdrive:
            return false
        
        if hyperdrive.max_fuel + self.modified_fuel_capacity < 0:
            return false

    if not is_zero_approx(self.modified_hull_capacity):
        # Include some epsilon so the ship doesn't end up with 0 hull and automatically destruct
        if ship.hull.max_integrity + self.modified_hull_capacity < 0.01:
            return false
        
    if not is_zero_approx(self.modified_shield_capacity):
        var shield := ship.shield
        if not shield:
            return false
        
        if shield.max_integrity + self.modified_shield_capacity < 0:
            return false
    
    if not is_zero_approx(self.modified_power_generation):
        var generator := ship.power_management_unit.power_generator
        if not generator:
            return false
        
        if generator.rate_of_power < self.modified_power_generation:
            return false
    
    if not is_zero_approx(self.modified_heat_capacity):
        # Include some epsilon so the ship doesn't end up overheated and inoperable
        if ship.heat_sink.max_heat + self.modified_heat_capacity < 0.01:
            return false

    if self.weapon:
        var mount_available := false
        for mount in ship.weapon_mounts:
            if not mount.weapon:
                mount_available = true
                break
        
        if not mount_available:
            return false

    return true

## Apply the effects of this outfit to a ship, or returns false if the outfit cannot be installed.
func apply_to_ship(ship: Ship) -> void:
    assert(self.can_install_onto_ship(ship), "Outfit is not installable onto the ship")

    ship.mass += self.mass

    if ship.cargo_hold:
        ship.cargo_hold.max_volume += self.modified_cargo_capacity

    if ship.passenger_quarters:
        ship.passenger_quarters.total_spaces += self.modified_passenger_capacity

    if ship.hyperdrive:
        ship.hyperdrive.max_fuel += self.modified_fuel_capacity

    if ship.shield:
        ship.shield.max_integrity += self.modified_shield_capacity
        ship.shield.recharge_rate *= self.shield_recharge_multiplier
    
    ship.hull.max_integrity += self.modified_hull_capacity
    ship.heat_sink.max_heat += self.modified_heat_capacity
    
    if ship.power_management_unit.power_generator:
        ship.power_management_unit.power_generator.rate_of_power += self.modified_power_generation

    if self.weapon:
        var weapon_mount: WeaponMount = null
        for mount in ship.weapon_mounts:
            if not mount.weapon:
                weapon_mount = mount
                break
        
        assert(weapon_mount, "Could not find weapon mount")
        weapon_mount.weapon = self.weapon

## Remove the effects of this outfit from a ship.
func remove_from_ship(ship: Ship) -> void:
    ship.mass -= self.mass

    if ship.cargo_hold:
        ship.cargo_hold.max_volume -= self.modified_cargo_capacity

    if ship.passenger_quarters:
        ship.passenger_quarters.total_spaces -= self.modified_passenger_capacity

    if ship.hyperdrive:
        ship.hyperdrive.max_fuel -= self.modified_fuel_capacity

    if ship.shield:
        ship.shield.max_integrity -= self.modified_shield_capacity
        ship.shield.recharge_rate /= self.shield_recharge_multiplier
    
    ship.hull.max_integrity -= self.modified_hull_capacity
    ship.heat_sink.max_heat -= self.modified_heat_capacity
    
    if ship.power_management_unit.power_generator:
        ship.power_management_unit.power_generator.rate_of_power -= self.modified_power_generation

    if self.weapon:
        for mount in ship.weapon_mounts:
            if mount.weapon == self.weapon:
                mount.weapon = null
                break

## Returns the list of effects provided by this outfit, as BBCode formatted strings.
func get_effects() -> PackedStringArray:
    var effects := PackedStringArray()

    if not is_zero_approx(self.mass):
        effects.push_back("[b]Mass:[/b] %s kg" % self.mass)

    if not is_zero_approx(self.modified_power_generation):
        if self.modified_power_generation > 0:
            effects.push_back("[b]Power generation:[/b] %s/s" % self.modified_power_generation)
        else:
            effects.push_back("[b]Power requirement:[/b] %s/s" % -self.modified_power_generation)

    if not is_zero_approx(self.modified_cargo_capacity):
        effects.push_back("[b]Cargo capacity:[/b] %s m³" % self._signed_string(self.modified_cargo_capacity))

    if self.modified_passenger_capacity != 0:
        effects.push_back("[b]Passenger capacity:[/b] %s" % self._signed_string(self.modified_passenger_capacity))

    if not is_zero_approx(self.modified_fuel_capacity):
        effects.push_back("[b]Fuel capacity:[/b] %s" % self._signed_string(self.modified_fuel_capacity))

    if not is_zero_approx(self.modified_hull_capacity):
        effects.push_back("[b]Maximum hull integrity:[/b] %s" % self._signed_string(self.modified_hull_capacity))

    if not is_zero_approx(self.modified_shield_capacity):
        effects.push_back("[b]Shield capacity:[/b] %s" % self._signed_string(self.modified_shield_capacity))

    if not is_equal_approx(self.shield_recharge_multiplier, 1.0):
        effects.push_back("[b]Shield recharge rate:[/b] %s%%" % [self.shield_recharge_multiplier * 100])

    if self.weapon:
        effects.push_back("[b]Fire interval:[/b] %ss" % [self.weapon.fire_interval])
        effects.push_back("[b]Power consumption per shot:[/b] %s" % [self.weapon.power_consumption])

    if not is_zero_approx(self.modified_heat_capacity):
        effects.push_back("[b]Heat:[/b] %s" % self._signed_string(-self.modified_heat_capacity))

    return effects

func _signed_string(value: float) -> String:
    if is_zero_approx(value):
        return "0"
    elif value < 0:
        return "%s" % value
    else:
        return "+%s" % value
