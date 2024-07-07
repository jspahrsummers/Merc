extends Node3D
class_name HyperspaceController

## Coordinates the player's hyperspace jumps and loading new scenes.

## The playable galaxy, used to determine system connections.
@export var galaxy: Galaxy

## The current star system.
@export var current_system: StarSystem

## Fires when the player changes the jump destination, or it resets because of a performed jump.
signal jump_destination_changed(new_destination: StarSystem)

## Fires when the player initiates a hyperspace jump, before any changes have occurred.
signal jump_started(destination: StarSystem)

## Fires when the hyperspace destination has been loaded and added to the current scene, but before the full visual effect has finished.
signal jump_destination_loaded(new_system: StarSystem)

## Fires when the hyperspace jump has been completed, and the visual effect has finished.
signal jump_finished(new_system: StarSystem)

## Whether a jump is currently being performed.
##
## This property should not be written to outside the class!
var jumping: bool = false

## The hyperspace destination that the player currently has selected.
##
## This property should not be written to outside the class!
var jump_destination: StarSystem

## Used to keep systems around in memory, so their state is remembered.
var _loaded_system_nodes: Dictionary = {}

func _ready() -> void:
    self._loaded_system_nodes[self.current_system.name] = get_tree().get_first_node_in_group("star_system")

func set_jump_destination(destination: StarSystem) -> void:
    assert(current_system != destination, "Current system should not be the same as the jump destination")
    assert(destination == null or destination.name in current_system.connections, "Jump destination should be connected to the current system")

    if destination == jump_destination:
        return

    jump_destination = destination
    self.emit_signal("jump_destination_changed", jump_destination)

func start_jump() -> void:
    assert(not jumping, "Jump already in progress")
    assert(jump_destination != null, "Jump destination not set")
    assert(current_system != jump_destination, "Current system should not be the same as the jump destination")

    if not self._loaded_system_nodes.has(jump_destination.name):
        ResourceLoader.load_threaded_request(jump_destination.scene_path())

    jumping = true
    self.emit_signal("jump_started", jump_destination)

func load_jump_destination() -> void:
    assert(jump_destination != null, "Jump destination not set")
    assert(current_system != jump_destination, "Current system should not be the same as the jump destination")

    # Replace scene
    for node: Node3D in self.get_tree().get_nodes_in_group("star_system"):
        node.visible = false
        node.process_mode = Node.PROCESS_MODE_DISABLED

    var node: Node3D = self._loaded_system_nodes.get(jump_destination.name)
    if node == null:
        print("Instantiating node for system ", jump_destination.name)
        var new_scene := ResourceLoader.load_threaded_get(jump_destination.scene_path()) as PackedScene
        node = new_scene.instantiate()

        self._loaded_system_nodes[jump_destination.name] = node
        get_parent().add_child(node)
    else:
        print("Restoring node for system ", jump_destination.name)
        node.process_mode = Node.PROCESS_MODE_INHERIT
        node.visible = true

    current_system = jump_destination
    jump_destination = null

    self.emit_signal("jump_destination_loaded", current_system)
    self.emit_signal("jump_destination_changed", null)

func finish_jump() -> void:
    assert(jumping, "No jump in progress")

    jumping = false
    self.emit_signal("jump_finished", current_system)
