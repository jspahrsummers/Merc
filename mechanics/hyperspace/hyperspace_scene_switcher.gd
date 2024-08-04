extends Node3D
class_name HyperspaceSceneSwitcher

## Coordinates loading new scenes for the player's hyperspace jumps.
##
## This node must contain exactly one [StarSystemInstance] child at all times.

## The player.
@export var player: Player

## The approximate number of days that should pass with each hyperspace jump.
const HYPERSPACE_APPROXIMATE_TRAVEL_DAYS = 3

## Fires when the hyperspace destination has been loaded and added to the current scene, but before the full visual effect has finished.
signal jump_destination_loaded(new_system_instance: StarSystemInstance)

## The player's [HyperdriveSystem].
var _hyperdrive_system: HyperdriveSystem

## Used to keep systems around in memory, so their state is remembered.
var _loaded_system_nodes: Dictionary = {}

## Used only when loading the game, to remember what the current system is.
var _current_system_after_load: String = ""

func _ready() -> void:
    self._hyperdrive_system = self.player.ship.hyperdrive_system

    var current_system_instance := self._get_current_system_instance()
    var current_system := current_system_instance.star_system
    self._loaded_system_nodes[current_system.name] = current_system_instance

func _get_current_system_instance() -> StarSystemInstance:
    return self.get_child(0)

func start_jump() -> bool:
    assert(not self._hyperdrive_system.jumping, "Jump already in progress")

    if not self._hyperdrive_system.hyperdrive.consume_for_jump():
        return false

    if not self._loaded_system_nodes.has(self._hyperdrive_system.jump_destination.name):
        ResourceLoader.load_threaded_request(self._hyperdrive_system.jump_destination.scene_path)

    self._hyperdrive_system.jumping = true
    return true

func load_jump_destination() -> void:
    assert(self._hyperdrive_system.jumping, "Expected a jump to be in progress")

    var destination := self._hyperdrive_system.jump_destination
    assert(destination, "Expected to have a jump destination")

    var player_ship := self._hyperdrive_system.ship
    var previous_system_instance := StarSystemInstance.star_system_instance_for_node(player_ship)
    previous_system_instance.remove_child(player_ship)
    self.remove_child(previous_system_instance)

    var star_system_instance: StarSystemInstance = self._loaded_system_nodes.get(destination.name)
    if star_system_instance == null:
        print("Instantiating node for ", destination)
        var new_scene := ResourceLoader.load_threaded_get(destination.scene_path) as PackedScene
        star_system_instance = new_scene.instantiate()

        self._loaded_system_nodes[destination.name] = star_system_instance
    else:
        print("Restoring node for ", destination)

    star_system_instance.add_child(player_ship)
    self.add_child(star_system_instance)

    self.player.calendar.pass_approximate_days(HYPERSPACE_APPROXIMATE_TRAVEL_DAYS)

    self._hyperdrive_system.jump_destination = null
    self.jump_destination_loaded.emit(star_system_instance)

func finish_jump() -> void:
    assert(self._hyperdrive_system.jumping, "No jump in progress")
    self._hyperdrive_system.jumping = false

## See [SaveGame].
func before_save() -> void:
    # Re-add all systems to the scene tree, so they all get saved.
    for system_name: StringName in self._loaded_system_nodes:
        var node: Node = self._loaded_system_nodes[system_name]
        if not node.is_inside_tree():
            self.add_child(node)

## See [SaveGame].
func after_save() -> void:
    var current_system_instance := self._get_current_system_instance()

    var count := self.get_child_count()
    for i in range(count - 1, 0, -1):
        var child := self.get_child(i)
        self.remove_child(child)
    
    assert(self._get_current_system_instance() == current_system_instance, "Current system unexpectedly changed after removing children")

## See [SaveGame].
func save_to_dict() -> Dictionary:
    var result := {}
    result["current_system"] = self._get_current_system_instance().star_system.name

    # Do NOT save the calendar, as this node doesn't own it.
    return result

## See [SaveGame].
func load_from_dict(dict: Dictionary) -> void:
    self._current_system_after_load = dict["current_system"]

## See [SaveGame].
func after_load() -> void:
    self._fixup_current_system()
    self._fixup_player()

    # Update any dependent properties
    self.jump_destination_loaded.emit(self._get_current_system_instance())

## The [Player] node is always saved to its initial system, so we need to move it to the current system.
func _fixup_player() -> void:
    self.player.ship.reparent(self._get_current_system_instance(), false)

## Remove inactive scenes to match the saved state.
func _fixup_current_system() -> void:
    assert(self._current_system_after_load, "Expected current system to be set after load")

    self._loaded_system_nodes.clear()
    for star_system_instance: StarSystemInstance in self.get_children():
        var star_system := star_system_instance.star_system
        self._loaded_system_nodes[star_system.name] = star_system_instance

        if star_system.name != self._current_system_after_load:
            self.remove_child(star_system_instance)

    assert(self._get_current_system_instance().star_system.name == self._current_system_after_load, "Current system mismatch after loading")
