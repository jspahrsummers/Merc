extends Node3D

## Presents the in-game galaxy map, showing all star systems.

@export var hyperspace_controller: HyperspaceController

## The galaxy to display.
@export var galaxy: Galaxy

## A scene used to represent star system nodes in the map.
@export var galaxy_map_system: PackedScene

## A scene used to represent hyperlane connections (edges) between star system nodes in the map.
@export var galaxy_map_hyperlane: PackedScene

## The camera observing the 3D galaxy.
@export var camera: GalaxyMapCamera

## Maps from each [member StarSystem.name] to the [GalaxyMapSystem] used to represent it.
var _system_nodes: Dictionary = {}

func _ready() -> void:
    for system in galaxy.systems:
        var system_node: GalaxyMapSystem = self.galaxy_map_system.instantiate()
        self._system_nodes[system.name] = system_node
        system_node.clicked.connect(func(node): self._on_system_clicked(system, node))

        system_node.name = system.name
        system_node.current = (system == self.hyperspace_controller.current_system)
        self.add_child(system_node)

        system_node.transform.origin = system.position

        for connection in system.connections:
            var connected_system := self.galaxy.get_system(connection)
            var hyperlane: GalaxyMapHyperlane = self.galaxy_map_hyperlane.instantiate()
            hyperlane.clicked.connect(func(node): self._on_hyperlane_clicked(system, connected_system, node))

            hyperlane.name = "%s > %s" % [system.name, connection]
            hyperlane.starting_position = system.position
            hyperlane.ending_position = connected_system.position
            self.add_child(hyperlane)

func _on_jump_started(_destination: StarSystem) -> void:
    var current_name = self.hyperspace_controller.current_system.name
    self._system_nodes[current_name].current = false

func _on_jump_finished(new_system: StarSystem) -> void:
    var new_name = new_system.name
    self.camera.center = new_system.position
    self._system_nodes[new_name].current = true

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_galaxy_map"):
        self.get_window().visible = false
        self.get_viewport().set_input_as_handled()

func _on_window_close_requested() -> void:
    self.get_window().visible = false

func _on_system_clicked(star_system: StarSystem, _system_node: GalaxyMapSystem) -> void:
    if self.hyperspace_controller.jumping:
        return

    if star_system.name not in self.hyperspace_controller.current_system.connections:
        return

    self.hyperspace_controller.set_jump_destination(star_system)

func _on_hyperlane_clicked(from_system: StarSystem, to_system: StarSystem, _hyperlane_node: GalaxyMapHyperlane) -> void:
    if self.hyperspace_controller.jumping:
        return
    
    var connection: StarSystem
    if from_system == self.hyperspace_controller.current_system:
        connection = to_system
    elif to_system == self.hyperspace_controller.current_system:
        connection = from_system
    else:
        return

    self.hyperspace_controller.set_jump_destination(connection)
