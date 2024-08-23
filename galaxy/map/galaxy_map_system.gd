extends StaticBody3D
class_name GalaxyMapSystem

## Represents a single star system (a node) in the galaxy map.

## Renders the name of the star system for the player to read.
@export var name_label: Label3D

## The mesh controlling this system node's appearance.
@export var mesh: MeshInstance3D

## When [member current] is true, this material overrides the [member mesh]'s material.
@export var current_node_material: Material

## Whether the system represented by this node is the player's current system or part of the current hyperspace path.
@export var current: bool:
    set(value):
        current = value
        self.mesh.material_override = self.current_node_material if value else null

## When [member selected] is true, this sprite is shown.
@export var selected_sprite: Sprite3D

## Whether this system is currently selected by the player in the galaxy map.
@export var selected: bool:
    set(value):
        selected = value
        self.selected_sprite.visible = value

## Fires when this system node is clicked.
signal clicked(system: GalaxyMapSystem)

func _ready() -> void:
    self.selected_sprite.visible = false
    self.name_label.text = self.name

func _input_event(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
    if event is InputEventMouseButton and event.is_pressed():
        self.emit_signal("clicked", self)
