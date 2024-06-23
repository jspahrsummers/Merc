extends PanelContainer

## Displays information and vitals about the ship that the player is targeting, if any.

@export var target_label: Label
@export var target_view: TargetView
@export var target_viewport: SubViewport
@export var hull_bar: TargetFillBar
@export var shield_bar: TargetFillBar
@export var pick_sound: AudioStreamPlayer

var _target: Ship = null

func _on_player_ship_target_changed(_player_ship: Ship, targeted_ship: Ship) -> void:
    if targeted_ship == self._target:
        return
    
    if self._target != null:
        self._target.ship_hull_changed.disconnect(_on_target_ship_hull_changed)
        self._target.ship_shield_changed.disconnect(_on_target_ship_shield_changed)
    
    self._target = targeted_ship

    if targeted_ship == null:
        self.target_label.text = "None"
        self.target_view.visible = false
        self.hull_bar.visible = false
        self.shield_bar.visible = false
    else:
        self.pick_sound.play()
        self.target_label.text = targeted_ship.name
        self.target_view.mesh = targeted_ship.mesh_instance
        self.target_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
        self.target_view.visible = true
        self.hull_bar.visible = true
        self.shield_bar.visible = true

        targeted_ship.ship_hull_changed.connect(_on_target_ship_hull_changed)
        targeted_ship.ship_shield_changed.connect(_on_target_ship_shield_changed)
        self._update_hull()
        self._update_shield()

func _on_target_ship_hull_changed(ship: Ship) -> void:
    assert(ship == self._target, "Should only be notified about changes to the target")
    self._update_hull()

func _on_target_ship_shield_changed(ship: Ship) -> void:
    assert(ship == self._target, "Should only be notified about changes to the target")
    self._update_shield()

func _update_hull() -> void:
    assert(self._target.ship_def.hull > 0.0, "Ship definition should not have 0 hull")
    self.hull_bar.max_value = self._target.ship_def.hull
    self.hull_bar.value = self._target.hull

func _update_shield() -> void:
    self.shield_bar.max_value = 1.0 if is_zero_approx(self._target.ship_def.shield) else self._target.ship_def.shield
    self.shield_bar.value = self._target.shield
