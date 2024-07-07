extends Node3D

## Hides or shows itself based on whether the player is targeting the object.
##
## Requires [signal CombatObject.targeted_by_changed] to be connected to this object.

func _ready() -> void:
    self.visible = false

func _on_targeted_by_changed(combat_object: CombatObject) -> void:
    for targeting_system in combat_object.get_targeted_by():
        if targeting_system.is_player:
            self.visible = true
            return
    
    self.visible = false
