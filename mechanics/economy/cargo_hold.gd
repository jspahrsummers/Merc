extends SaveableResource
class_name CargoHold

## Represents a cargo hold on a ship, containing commodities for trade.
##
## Cargo can only be carried in whole units (never fractional).

## The volume of this cargo hold, in cubic meters, determining the maximum amount of cargo that can be carried.
@export var max_volume: float:
    set(value):
        assert(max_volume >= 0.0, "Max volume must be non-negative")
        if is_equal_approx(max_volume, value):
            return
        
        max_volume = value
        self.emit_changed()

## The commodities being carried as cargo, structured as a dictionary of [Commodity] keys to [int] amounts.
@export var commodities: Dictionary = {}

## Returns how much of the hold's volume is currently occupied by cargo, in cubic meters.
func get_occupied_volume() -> float:
    var volume := 0.0
    for commodity: Commodity in self.commodities:
        var amount: int = commodities[commodity]
        volume += float(amount) * commodity.volume
    
    return volume

## Returns the total (in-game) mass of the cargo in the hold, in kg.
func get_mass() -> float:
    var mass := 0.0
    for commodity: Commodity in self.commodities:
        var amount: int = commodities[commodity]
        mass += float(amount) * commodity.mass
    
    return mass

## Adds up to [param amount] of [param commodity] to the hold.
##
## Returns the amount actually added, which may be less than requested if the cargo hold runs out of space.
func add_up_to(commodity: Commodity, amount: int) -> int:
    var available_volume := self.max_volume - self.get_occupied_volume()
    var available_amount := floori(available_volume / commodity.volume)

    var added_amount := mini(amount, available_amount)
    if added_amount == 0:
        return 0

    self.commodities[commodity] = self.commodities.get(commodity, 0) + added_amount
    self.emit_changed()
    return added_amount

## Takes up to [param amount] of [param commodity] from the hold.
##
## Returns the amount actually taken, which may be less than requested if there's not enough of the commodity.
func remove_up_to(commodity: Commodity, amount: int) -> int:
    var available_amount: int = self.commodities.get(commodity, 0)

    var removed_amount := mini(amount, available_amount)
    if removed_amount == 0:
        return 0

    if removed_amount == available_amount:
        self.commodities.erase(commodity)
    else:
        self.commodities[commodity] = available_amount - removed_amount
    
    self.emit_changed()
    return removed_amount

## Attempts to add exactly [param amount] of [param commodity] to the hold, or returns false if there's not enough space.
func add_exactly(commodity: Commodity, amount: int) -> bool:
    var needed_volume := float(amount) * commodity.volume
    if self.get_occupied_volume() + needed_volume > self.max_volume:
        return false
    
    self.commodities[commodity] = self.commodities.get(commodity, 0) + amount
    self.emit_changed()
    return true

## Attempts to take exactly [param amount] of [param commodity] from the hold, or returns false if there's not enough of the commodity.
func remove_exactly(commodity: Commodity, amount: int) -> bool:
    var available_amount: int = self.commodities.get(commodity, 0)
    if available_amount < amount:
        return false
    
    if available_amount == amount:
        self.commodities.erase(commodity)
    else:
        self.commodities[commodity] = available_amount - amount
    
    self.emit_changed()
    return true

# Overridden because dictionaries of resources do not serialize correctly.
func save_to_dict() -> Dictionary:
    var result := {}
    result["max_volume"] = self.max_volume

    var saved_commodities := {}
    for commodity: Commodity in self.commodities:
        saved_commodities[commodity.resource_path] = self.commodities[commodity]

    result["commodities"] = saved_commodities
    return result

func load_from_dict(dict: Dictionary) -> void:
    self.max_volume = dict["max_volume"]
    self.commodities.clear()

    var saved_commodities: Dictionary = dict["commodities"]
    for commodity_path: String in saved_commodities:
        var commodity: Commodity = ResourceUtils.safe_load_resource(commodity_path, "tres")
        self.commodities[commodity] = saved_commodities[commodity_path]
    
    self.emit_changed()
