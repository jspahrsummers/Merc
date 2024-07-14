extends Node3D
class_name PlanetInstance

## Defines properties and facilities for this planet.
##
## If not set, the planet is assumed uninhabitable and cannot be landed upon.
@export var planet: Planet

## An overlay to show if the player is targeting this planet.
@export var target_overlay: Node3D

## Whether this planet is being targeted by the player.
var targeted_by_player: bool:
    set(value):
        targeted_by_player = value
        self.target_overlay.visible = targeted_by_player

func _enter_tree() -> void:
    self.targeted_by_player = false

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
    if event is InputEventMouseButton:
        InputEventBroadcaster.broadcast(self, event)
