extends Node3D
class_name RigidBodyCargo

## Attaches to a [RigidBody3D] to adjust its mass based on carried cargo and/or passengers.

## Optional cargo hold to calculate mass from.
var cargo_hold: CargoHold:
    set(value):
        if value == cargo_hold:
            return
        
        if cargo_hold:
            cargo_hold.changed.disconnect(_recalculate_mass)

        cargo_hold = value
        self._recalculate_mass()

        if cargo_hold:
            cargo_hold.changed.connect(_recalculate_mass)

## Optional passenger quarters to calculate mass from.
var passenger_quarters: PassengerQuarters:
    set(value):
        if value == passenger_quarters:
            return
        
        if passenger_quarters:
            passenger_quarters.changed.disconnect(_recalculate_mass)

        passenger_quarters = value
        self._recalculate_mass()

        if passenger_quarters:
            passenger_quarters.changed.connect(_recalculate_mass)

## In-game mass (in kg) of each passenger.
const MASS_PER_PASSENGER = 0.07

@onready var _rigid_body := get_parent() as RigidBody3D

var _added_mass: float = 0.0:
    set(value):
        if is_equal_approx(_added_mass, value):
            return
        
        self._rigid_body.mass -= _added_mass
        _added_mass = value
        self._rigid_body.mass += _added_mass

func _recalculate_mass() -> void:
    var added_mass := 0.0

    if self.cargo_hold:
        added_mass += self.cargo_hold.get_mass()

    if self.passenger_quarters:
        added_mass += self.passenger_quarters.occupied_spaces * MASS_PER_PASSENGER
    
    self._added_mass = added_mass
