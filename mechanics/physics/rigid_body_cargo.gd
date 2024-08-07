extends Node3D
class_name RigidBodyCargo

## Attaches to a [RigidBody3D] to adjust its mass based on a [CargoHold].

## The cargo hold.
var cargo_hold: CargoHold:
    set(value):
        if value == cargo_hold:
            return
        
        if cargo_hold:
            cargo_hold.changed.disconnect(_on_cargo_changed)
        cargo_hold = value
        if cargo_hold:
            cargo_hold.changed.connect(_on_cargo_changed)

@onready var _rigid_body := get_parent() as RigidBody3D

var _added_mass: float = 0.0:
    set(value):
        if is_equal_approx(_added_mass, value):
            return
        
        self._rigid_body.mass -= _added_mass
        _added_mass = value
        self._rigid_body.mass += _added_mass

func _on_cargo_changed() -> void:
    self._added_mass = self.cargo_hold.get_mass()
