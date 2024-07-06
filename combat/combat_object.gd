extends Node3D
class_name CombatObject

## Attaches to an object that can participate in combat, and be damaged or destroyed.
##
## CombatObject will automatically remove itself [b]and its parent[/b] from the scene tree when destroyed.

## This object's name when targeted in combat.
@export var combat_name: String

## An optional shield protecting the object.
@export var shield: Shield

## An optional mesh to render as the object's shields, when the shields are hit.
##
## This is accomplished by keeping the mesh at full transparency most of the time, then animating it to fully opaque and back when hit. The mesh's material must honor transparency.
@export var shield_mesh_instance: MeshInstance3D

## The total duration of the shield flash effect, in seconds.
@export var shield_flash_duration: float = 0.4

@export var shield_flash_on_transition: Tween.TransitionType = Tween.TRANS_ELASTIC
@export var shield_flash_on_ease: Tween.EaseType = Tween.EASE_OUT
@export var shield_flash_off_transition: Tween.TransitionType = Tween.TRANS_CUBIC
@export var shield_flash_off_ease: Tween.EaseType = Tween.EASE_IN

## The hull of the object.
##
## Connect to [signal Hull.hull_destroyed] to be notified when the CombatObject is destroyed.
@export var hull: Hull

## An optional scene to instantiate at the object's [member Node3D.global_transform] when destroyed.
##
## The root must be a [Node3D].
@export var destruction: PackedScene

## [TargetingSystem]s that are currently targeting this object.
@export var targeted_by: Array[TargetingSystem] = []:
    set(value):
        if value == targeted_by:
            return

        targeted_by = value.duplicate()
        self.targeted_by_changed.emit(self)

## Fires when the [member targeted_by] property changes.
signal targeted_by_changed(combat_object: CombatObject)

var _shield_tween: Tween

func _ready() -> void:
    if self.destruction:
        self.hull.hull_destroyed.connect(_on_hull_destroyed)
    
    if self.shield_mesh_instance:
        self.shield_mesh_instance.transparency = 1.0

## Damages this object, potentially destroying it.
func damage(dmg: Damage) -> void:
    var apply_hull_dmg_pct := 1.0

    if self.shield and self.shield.integrity > 0.01: # compare with epilson to mitigate floating point rounding issues
        self._show_shields()

        var actual_shield_dmg := minf(self.shield.integrity, dmg.shield_damage)
        self.shield.integrity -= actual_shield_dmg

        # Reduce hull damage proportionally to the shield damage applied
        apply_hull_dmg_pct -= actual_shield_dmg / dmg.shield_damage
    
    if apply_hull_dmg_pct > 0.0:
        self.hull.integrity -= dmg.hull_damage * apply_hull_dmg_pct

func _on_hull_destroyed(destroyed_hull: Hull) -> void:
    assert(destroyed_hull == self.hull)

    var parent := self.get_parent()
    var grandparent := parent.get_parent()

    var destruction_instance: Node3D = self.destruction.instantiate()
    if grandparent:
        grandparent.add_child(destruction_instance)
    else:
        get_tree().root.add_child(destruction_instance)
    destruction_instance.global_transform = self.global_transform

    parent.queue_free()

## Flash shields, if enabled.
func _show_shields() -> void:
    if not self.shield_mesh_instance or not self.shield_flash_duration:
        return

    if self._shield_tween != null:
        self._shield_tween.kill()

    var tween := self.create_tween()

    var on_tweener := tween.tween_property(self.shield_mesh_instance, "transparency", 0.0, self.shield_flash_duration / 2.0)
    on_tweener.set_trans(self.shield_flash_on_transition)
    on_tweener.set_ease(self.shield_flash_on_ease)

    var off_tweener := tween.tween_property(self.shield_mesh_instance, "transparency", 1.0, self.shield_flash_duration / 2.0)
    off_tweener.set_trans(self.shield_flash_off_transition)
    off_tweener.set_ease(self.shield_flash_off_ease)
    
    self._shield_tween = tween
