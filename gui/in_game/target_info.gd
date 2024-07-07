extends PanelContainer

## Displays information and vitals about the ship that the player is targeting, if any.

@export var target_label: Label
@export var target_viewport: SubViewport
@export var hull_bar: TargetFillBar
@export var shield_bar: TargetFillBar
@export var pick_sound: AudioStreamPlayer

var _target: CombatObject = null
var _target_view: Node3D = null

func _on_player_target_changed(_player: Player, target: CombatObject) -> void:
    if target == self._target:
        return
    
    if self._target != null:
        self._target.hull.changed.disconnect(_on_target_hull_changed)
        self._target.shield.changed.disconnect(_on_target_shield_changed)
    
    self._target = target

    if target == null:
        self._target_view.queue_free()
        self.target_label.text = "None"
        self.hull_bar.visible = false
        self.shield_bar.visible = false
    else:
        self.pick_sound.play()
        self.target_label.text = target.combat_name
        self._target_view = target.target_view.instantiate() as Node3D
        self.target_viewport.add_child(self._target_view)
        self.target_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
        self.hull_bar.visible = true
        self.shield_bar.visible = true

        target.hull.changed.connect(_on_target_hull_changed)
        target.shield.changed.connect(_on_target_shield_changed)
        self._on_target_hull_changed()
        self._on_target_shield_changed()

func _on_target_hull_changed() -> void:
    var hull := self._target.hull
    self.hull_bar.max_value = hull.max_integrity
    self.hull_bar.value = hull.integrity

func _on_target_shield_changed() -> void:
    var shield := self._target.shield
    self.shield_bar.max_value = maxf(1.0, shield.max_integrity)
    self.shield_bar.value = shield.integrity
