extends StaticBody3D
class_name GalaxyMapHyperlane

## Represents a hyperspace connection between two star systems (an edge) in the galaxy map.
##
## Although it is not apparent visually, this is a [i]unidirectional[/i] connection. Star systems will generally have bidirectional connections, so the galaxy map will actually superimpose two [GalaxyMapHyperlane]s on top of one another, one for each direction. In future, if unidirectional connections become a useful game mechanic, we may want to create a visual distinction between each direction of hyperlane.

## The position of the origin system, in galaxy space.
@export var starting_position: Vector3

## The position of the destination system, in galaxy space.
@export var ending_position: Vector3

## The mesh controlling this hyperlane's appearance.
##
## This is expected to have a [CylinderMesh] attached.
@export var mesh: MeshInstance3D

## When [member selected] is true, this material overrides the [member mesh]'s material.
@export var selected_material: Material

## Whether this hyperlane is selected.
@export var selected: bool:
    set(value):
        selected = value
        self.mesh.material_override = self.selected_material if value else null

## The shape defining the clickable region of this hyperlane.
##
## This is expected to have a [CylinderShape3D] attached.
@export var collision_shape: CollisionShape3D

## When visible, renders the name of this edge, which can be helpful to identify if specific connections are not rendered correctly.
@export var debugging_label: Label3D

## The radius of the [GalaxySystemNode]s that will appear at either end of this edge.
##
## This is used to ensure that the hyperlane's collider (for object picking) does not obstruct the nodes' own colliders.
@export var node_radius: float

## Fires when this hyperlane is clicked.
signal clicked(hyperlane: GalaxyMapHyperlane)

func _ready() -> void:
    self.debugging_label.text = self.name

    var delta := self.ending_position - self.starting_position
    var distance := delta.length()
    var direction := delta / distance

    var cylinder: CylinderMesh = self.mesh.mesh.duplicate()
    cylinder.height = distance
    self.mesh.mesh = cylinder

    var collider: CylinderShape3D = self.collision_shape.shape.duplicate()
    collider.height = distance - node_radius * 2
    self.collision_shape.shape = collider

    self.global_transform = Transform3D(Basis.looking_at(direction), self.starting_position + delta / 2)

func _input_event(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
    if event is InputEventMouseButton and event.is_pressed():
        self.emit_signal("clicked", self)
