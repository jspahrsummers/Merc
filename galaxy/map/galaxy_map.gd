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
@export var facilities_heading: Label
@export var facilities_label: Label
@export var currency_heading: Label
@export var currency_label: Label
@export var commodities_heading: Label
@export var commodities_label: Label

## The player's [HyperdriveSystem]. Must be set before displaying.
var hyperdrive_system: HyperdriveSystem

## Maps from each [member StarSystem.name] to the [GalaxyMapSystem] used to represent it.
var _system_nodes: Dictionary = {}

## Maps from a hyperlane's name to the [GalaxyMapHyperlane] used to represent it.
##
## Hyperlane names are formatted as "from > to".
var _hyperlane_nodes: Dictionary = {}

func _ready() -> void:
    self.hyperdrive_system.jumping_changed.connect(_on_jumping_changed)
    self.hyperdrive_system.jump_path_changed.connect(_on_jump_path_changed)

    var current_system := self.hyperdrive_system.current_system()

    for system in galaxy.systems:
        var system_node: GalaxyMapSystem = self.galaxy_map_system.instantiate()
        system_node.clicked.connect(func(_node: GalaxyMapSystem) -> void: self._on_system_clicked(system))
        system_node.name = system.name
        system_node.current = (system == current_system)
        self._system_nodes[system.name] = system_node
        self.galaxy_map_3d.add_child(system_node)

        system_node.transform.origin = system.position

        for connection in system.connections:
            var reverse_name := "%s > %s" % [connection, system.name]
            if reverse_name in self._hyperlane_nodes:
                # Only create one lane even if it's bidirectional
                continue

            var connected_system := self.galaxy.get_system(connection)
            var hyperlane: GalaxyMapHyperlane = self.galaxy_map_hyperlane.instantiate()
            hyperlane.clicked.connect(func(_node: GalaxyMapHyperlane) -> void: self._on_hyperlane_clicked(system, connected_system))
            hyperlane.name = "%s > %s" % [system.name, connection]
            hyperlane.starting_position = system.position
            hyperlane.ending_position = connected_system.position
            self._hyperlane_nodes[hyperlane.name] = hyperlane
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

func _on_jump_path_changed(_hyperdrive_system: HyperdriveSystem) -> void:
    assert(self.hyperdrive_system == _hyperdrive_system)
    self._update_selection_state()

func _update_selection_state() -> void:
    var current_system := self.hyperdrive_system.current_system()

    var jump_path := self.hyperdrive_system.get_jump_path()
    var jump_names := jump_path.map(func(system: StarSystem) -> StringName: return system.name)
    for system_name: String in self._system_nodes:
        var node: GalaxyMapSystem = self._system_nodes[system_name]
        node.current = system_name in jump_names or system_name == current_system.name
        node.selected = system_name == jump_names[-1] if jump_path else false
    
    for hyperlane_name: String in self._hyperlane_nodes:
        var node: GalaxyMapHyperlane = self._hyperlane_nodes[hyperlane_name]
        node.selected = false
    
    var presented_system: StarSystem
    if jump_path:
        for i in range(0, jump_path.size()):
            var last_name := jump_path[i - 1].name if i > 0 else self.hyperdrive_system.current_system().name

            var forward_name := "%s > %s" % [last_name, jump_path[i].name]
            if forward_name in self._hyperlane_nodes:
                self._hyperlane_nodes[forward_name].selected = true

            var backward_name := "%s > %s" % [jump_path[i].name, last_name]
            if backward_name in self._hyperlane_nodes:
                self._hyperlane_nodes[backward_name].selected = true

        presented_system = jump_path[-1]
        self.current_or_destination_heading.text = "Destination system"
    else:
        presented_system = current_system
        self.current_or_destination_heading.text = "Current system"

    self.system_name_label.text = presented_system.name

    if not presented_system.ports:
        self.ports_label.text = "(none)"
        self.facilities_heading.visible = false
        self.facilities_label.visible = false
        self.currency_heading.visible = false
        self.currency_label.visible = false
        self.commodities_heading.visible = false
        self.commodities_label.visible = false
        return

    self.facilities_heading.visible = true
    self.facilities_label.visible = true
    self.commodities_heading.visible = true
    self.commodities_label.visible = true

    var facilities_flags: int = 0
    var ports := PackedStringArray()
    for port in presented_system.ports:
        ports.append(port.name)
        facilities_flags |= port.facilities
    
    var facilities := PackedStringArray()
    if facilities_flags & Port.REFUEL:
        facilities.append("Fuel")
    if facilities_flags & Port.MISSIONS:
        facilities.append("Missions")
    if facilities_flags & Port.OUTFITTER:
        facilities.append("Outfitter")
    if facilities_flags & Port.SHIPYARD:
        facilities.append("Shipyard")

    self.ports_label.text = "\n".join(ports)
    self.facilities_label.text = "\n".join(facilities) if facilities else "(none)"
    
    var commodities := PackedStringArray()
    if presented_system.market:
        for commodity: Commodity in presented_system.market.commodities:
            commodities.append(commodity.name)
        
        self.commodities_label.text = "\n".join(commodities)
    else:
        self.commodities_label.text = "(none)"
    
    var money := presented_system.preferred_money()
    if money:
        self.currency_heading.visible = true
        self.currency_label.visible = true
        self.currency_label.text = money.name
    else:
        self.currency_heading.visible = false
        self.currency_label.visible = false

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_galaxy_map"):
        self.get_viewport().set_input_as_handled()
        self.queue_free()

func _on_window_close_requested() -> void:
    self.queue_free()

func _on_system_clicked(star_system: StarSystem) -> void:
    if not is_instance_valid(self.hyperdrive_system) or self.hyperdrive_system.jumping:
        return

    if star_system == self.hyperdrive_system.current_system():
        self.hyperdrive_system.clear_jump_path()
        return

    if Input.is_key_pressed(KEY_SHIFT):
        self._update_multi_path(star_system)
    else:
        self._replace_single_path(star_system)

func _on_hyperlane_clicked(from_system: StarSystem, to_system: StarSystem) -> void:
    if not is_instance_valid(self.hyperdrive_system) or self.hyperdrive_system.jumping:
        return
    
    var current_system := self.hyperdrive_system.current_system()
    var jump_path := self.hyperdrive_system.get_jump_path()
    if from_system == current_system or from_system in jump_path:
        self._on_system_clicked(to_system)
    elif to_system == current_system or to_system in jump_path:
        self._on_system_clicked(from_system)

func _update_multi_path(star_system: StarSystem) -> void:
    var current_path := self.hyperdrive_system.get_jump_path()
    if not current_path:
        return self._replace_single_path(star_system)

    var current_path_names := self.hyperdrive_system.get_jump_path().map(func(system: StarSystem) -> StringName: return system.name)
    var index := current_path_names.find(star_system.name)
    if index != -1:
        # Reset path back to the clicked node
        self.hyperdrive_system.set_jump_path(current_path.slice(0, index + 1))
        return
    
    # Add to end of path
    var last_system := current_path[-1]
    if star_system.name in last_system.connections:
        self.hyperdrive_system.add_to_jump_path(star_system)

func _replace_single_path(star_system: StarSystem) -> void:
    if star_system.name not in self.hyperdrive_system.current_system().connections:
        return

    self.hyperdrive_system.set_jump_path([star_system])
