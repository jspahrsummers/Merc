extends Node
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

## Fires when the [member target] changes.
signal target_changed(targeting_system: TargetingSystem)

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
