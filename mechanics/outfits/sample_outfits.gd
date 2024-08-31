extends Node

## Generate a set of sample outfits for testing purposes.
static func generate_sample_outfits() -> Array[Outfit]:
    var outfits: Array[Outfit] = []
    
    var cargo_expansion = CargoHoldExpansionOutfit.new()
    cargo_expansion.name = "Cargo Hold Expansion"
    cargo_expansion.additional_capacity = 5.0
    cargo_expansion.mass = 1.0
    cargo_expansion.volume = 5.0
    cargo_expansion.power_consumption = 0.0
    cargo_expansion.cost = 5000
    outfits.append(cargo_expansion)
    
    var fuel_tank = FuelTankOutfit.new()
    fuel_tank.name = "Extra Fuel Tank"
    fuel_tank.additional_capacity = 2.0
    fuel_tank.mass = 0.5
    fuel_tank.volume = 2.0
    fuel_tank.power_consumption = 0.0
    fuel_tank.cost = 3000
    outfits.append(fuel_tank)
    
    var shield_booster = ShieldBoosterOutfit.new()
    shield_booster.name = "Shield Booster"
    shield_booster.additional_capacity = 50.0
    shield_booster.recharge_rate_multiplier = 1.2
    shield_booster.mass = 0.3
    shield_booster.volume = 0.5
    shield_booster.power_consumption = 5.0
    shield_booster.cost = 8000
    outfits.append(shield_booster)
    
    var laser = WeaponOutfit.new()
    laser.name = "Basic Laser"
    laser.damage = 10.0
    laser.range = 500.0
    laser.fire_rate = 2.0
    laser.mass = 0.2
    laser.volume = 0.3
    laser.power_consumption = 10.0
    laser.cost = 5000
    outfits.append(laser)
    
    return outfits

## Add sample outfits to a port for testing purposes.
static func add_sample_outfits_to_port(port: Port) -> void:
    port.available_outfits = generate_sample_outfits()