extends Node3D
class_name TargetingSystem

## Attaches to a [CombatObject] to implement target lock from that object to other [CombatObject]s.

## The target that is currently locked on to, or null.
@export var target: CombatObject:
    set(value):
        if target == value:
            return

        if target:
            self._remove_from_target()

        target = value
        if target:
            target.hull.hull_destroyed.connect(_on_target_destroyed)
            target.targeted_by.push_back(self)
        
        self.target_changed.emit(self)

## The [CombatObject] containing this [TargetingSystem].
@onready var combat_object := get_parent() as CombatObject

## Whether this is a player's [TargetingSystem]. Used to render UI differently accordingly.
var is_player: bool = false

## Fires when the [member target] changes.
signal target_changed(targeting_system: TargetingSystem)

func get_available_targets() -> Array[CombatObject]:
    var combat_objects: Array[CombatObject] = []
    for node in get_tree().get_nodes_in_group("combat_objects"):
        if node.is_queued_for_deletion():
            continue

        var obj := node as CombatObject
        if obj.is_visible_in_tree():
            combat_objects.push_back(obj)
    
    return combat_objects

func _notification(what: int) -> void:
    match what:
        # When freed, make sure to remove self from the targeted_by list, in case the target object will be sticking around.
        NOTIFICATION_PREDELETE:
            if is_instance_valid(self.target):
                self._remove_from_target()

func _on_target_destroyed(_hull: Hull) -> void:
    self.target = null

func _remove_from_target() -> void:
    self.target.targeted_by.erase(self)
    self.target.hull.hull_destroyed.disconnect(_on_target_destroyed)
