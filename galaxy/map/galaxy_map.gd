extends Window
class_name GalaxyMap

## Presents the in-game galaxy map, showing all star systems.

## The 3D node displaying the galaxy map visualization.
@export var galaxy_map_3d: Node3D

## The galaxy to display.
@export var galaxy: Galaxy

## A scene used to represent star system nodes in the map.
@export var galaxy_map_system: PackedScene

## A scene used to represent hyperlane connections (edges) between star system nodes in the map.
@export var galaxy_map_hyperlane: PackedScene

## The camera observing the 3D galaxy.
@export var camera: GalaxyMapCamera

@export var current_or_destination_heading: Label
@export var system_name_label: Label
@export var ports_label: Label

## The player's [HyperdriveSystem]. Must be set before displaying.
var hyperdrive_system: HyperdriveSystem

## Maps from each [member StarSystem.name] to the [GalaxyMapSystem] used to represent it.
var _system_nodes: Dictionary = {}

func _ready() -> void:
    self.hyperdrive_system.jumping_changed.connect(_on_jumping_changed)
    self.hyperdrive_system.jump_destination_changed.connect(_on_jump_destination_changed)

    var current_system := self.hyperdrive_system.current_system()

    for system in galaxy.systems:
        var system_node: GalaxyMapSystem = self.galaxy_map_system.instantiate()
        self._system_nodes[system.name] = system_node
        system_node.clicked.connect(func(node: GalaxyMapSystem) -> void: self._on_system_clicked(system, node))

        system_node.name = system.name
        system_node.current = (system == current_system)
        self.galaxy_map_3d.add_child(system_node)

        system_node.transform.origin = system.position

        for connection in system.connections:
            var connected_system := self.galaxy.get_system(connection)
            var hyperlane: GalaxyMapHyperlane = self.galaxy_map_hyperlane.instantiate()
            hyperlane.clicked.connect(func(node: GalaxyMapHyperlane) -> void: self._on_hyperlane_clicked(system, connected_system, node))

            hyperlane.name = "%s > %s" % [system.name, connection]
            hyperlane.starting_position = system.position
            hyperlane.ending_position = connected_system.position
            self.galaxy_map_3d.add_child(hyperlane)
    
    self._update_selection_state()

func _on_jumping_changed(_hyperdrive_system: HyperdriveSystem) -> void:
    assert(self.hyperdrive_system == _hyperdrive_system)

    if self.hyperdrive_system.jumping:
        var current_name := self.hyperdrive_system.current_system().name
        self._system_nodes[current_name].current = false
    else:
        var new_system := self.hyperdrive_system.current_system()
        self.camera.center = new_system.position
        self._system_nodes[new_system.name].current = true

func _on_jump_destination_changed(_hyperdrive_system: HyperdriveSystem) -> void:
    assert(self.hyperdrive_system == _hyperdrive_system)
    self._update_selection_state()

func _update_selection_state() -> void:
    for system_name: String in self._system_nodes:
        var node: GalaxyMapSystem = self._system_nodes[system_name]
        node.selected = self.hyperdrive_system.jump_destination and self.hyperdrive_system.jump_destination.name == system_name
    
    var presented_system: StarSystem
    if self.hyperdrive_system.jump_destination:
        presented_system = self.hyperdrive_system.jump_destination
        self.current_or_destination_heading.text = "DESTINATION SYSTEM"
    else:
        presented_system = self.hyperdrive_system.current_system()
        self.current_or_destination_heading.text = "CURRENT SYSTEM"

    self.system_name_label.text = presented_system.name
    if presented_system.planets:
        self.ports_label.text = "\n".join(PackedStringArray(presented_system.planets.map(func(planet: Planet) -> String:
            return planet.name)))
    else:
        self.ports_label.text = "(none)"

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_galaxy_map"):
        self.get_viewport().set_input_as_handled()
        self.queue_free()

func _on_window_close_requested() -> void:
    self.queue_free()

func _on_system_clicked(star_system: StarSystem, _system_node: GalaxyMapSystem) -> void:
    if not is_instance_valid(self.hyperdrive_system) or self.hyperdrive_system.jumping:
        return

    if star_system == self.hyperdrive_system.current_system():
        self.hyperdrive_system.jump_destination = null
        return

    if star_system.name not in self.hyperdrive_system.current_system().connections:
        return

    self.hyperdrive_system.jump_destination = star_system

func _on_hyperlane_clicked(from_system: StarSystem, to_system: StarSystem, _hyperlane_node: GalaxyMapHyperlane) -> void:
    if not is_instance_valid(self.hyperdrive_system) or self.hyperdrive_system.jumping:
        return

    var current_system := self.hyperdrive_system.current_system()
    var connection: StarSystem
    if from_system == current_system:
        connection = to_system
    elif to_system == current_system:
        connection = from_system
    else:
        return

    self.hyperdrive_system.jump_destination = connection
