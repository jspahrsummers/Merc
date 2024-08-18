extends Node3D
class_name CombatObject

## Attaches to an object that can participate in combat, and be damaged or destroyed.
##
## CombatObject will automatically remove itself [b]and its parent[/b] from the scene tree when destroyed.

## This object's name when targeted in combat.
@export var combat_name: String

## A scene to render as the visualization of this object in the target info panel.
@export var target_view: PackedScene

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

## An optional scene to instantiate at the object's [member Node3D.global_transform] when destroyed.
##
## The root must be a [Node3D].
@export var destruction: PackedScene

## An optional sound to play when this object is targeted by another.
@export var targeted_sound: AudioStreamPlayer

## The hull of the object.
##
## Connect to [signal Hull.hull_destroyed] to be notified when the CombatObject is destroyed.
var hull: Hull:
    set(value):
        if value == hull:
            return
        
        if hull:
            hull.hull_destroyed.disconnect(_on_hull_destroyed)
        hull = value
        if hull:
            hull.hull_destroyed.connect(_on_hull_destroyed)

## An optional shield protecting the object.
var shield: Shield

## Fires when this object is targeted, or stops being targeted, by a new [TargetingSystem].
##
## See [method get_targeted_by]
signal targeted_by_changed(combat_object: CombatObject)

var _shield_tween: Tween
var _targeted_by: Array[TargetingSystem] = []

func _enter_tree() -> void:
    if self.shield_mesh_instance:
        self.shield_mesh_instance.transparency = 1.0
    
    if self._shield_tween:
        self._shield_tween.kill()
        self._shield_tween = null

## Returns the list of [TargetingSystem]s targeting this object.
func get_targeted_by() -> Array[TargetingSystem]:
    return self._targeted_by.duplicate()

## Adds to the list of [TArgetingSystem]s targeting this object.
##
## This [b]must not[/b] be called twice for the same targeting system, without an intervening removal.
func add_targeted_by(targeting_system: TargetingSystem) -> void:
    assert(self._targeted_by.find(targeting_system) == -1, "Duplicate add_targeted_by with the same targeting system")
    self._targeted_by.push_back(targeting_system)
    self.targeted_by_changed.emit(self)

    if self.targeted_sound:
        self.targeted_sound.play()

## Removes from the list of [TArgetingSystem]s targeting this object.
##
## This [b]must[/b] only be called after a matching [method add_targeted_by] call.
func remove_targeted_by(targeting_system: TargetingSystem) -> void:
    # Targets are more likely to change at the end of the list, so search in reverse
    var index := self._targeted_by.rfind(targeting_system)
    assert(index != -1, "remove_targeted_by called with a targeting system that is not targeting this object")

    self._targeted_by.remove_at(index)
    self.targeted_by_changed.emit(self)

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

## Checks whether [param node] contains a [CombatObject], and damages it if so.
static func damage_combat_object_inside(node: Node, dmg: Damage) -> bool:
    var combat_object := node.get_node_or_null(^"CombatObject") as CombatObject
    if not combat_object:
        return false
    
    combat_object.damage(dmg)
    return true

func _on_hull_destroyed(destroyed_hull: Hull) -> void:
    if not self.destruction:
        return

    assert(destroyed_hull == self.hull)

    var parent := self.get_parent()

    var destruction_instance: Node3D = self.destruction.instantiate()
    parent.add_sibling(destruction_instance)
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

func _to_string() -> String:
    return "CombatObject:" + self.combat_name

func _on_collision_object_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
    if event is InputEventMouseButton:
        InputEventBroadcaster.broadcast(self, event)
