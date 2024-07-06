extends PanelContainer

## Displays information and vitals about the ship that the player is targeting, if any.

@export var target_label: Label
@export var target_view: TargetView
@export var target_viewport: SubViewport
@export var hull_bar: TargetFillBar
@export var shield_bar: TargetFillBar
@export var pick_sound: AudioStreamPlayer

var _target: CombatObject = null

func _on_player_ship_target_changed(_player_ship: Ship, target: CombatObject) -> void:
    if target == self._target:
        return
    
    if self._target != null:
        self._target.hull.changed.disconnect(_on_target_hull_changed)
        self._target.shield.changed.disconnect(_on_target_shield_changed)
    
    self._target = target

    if target == null:
        self.target_label.text = "None"
        self.target_view.visible = false
        self.hull_bar.visible = false
        self.shield_bar.visible = false
    else:
        self.pick_sound.play()
        self.target_label.text = target.combat_name
        self.target_view.mesh = self._find_target_mesh(target)
        self.target_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
        self.target_view.visible = true
        self.hull_bar.visible = true
        self.shield_bar.visible = true

        target.hull.changed.connect(_on_target_hull_changed)
        target.shield.changed.connect(_on_target_shield_changed)
        self._on_target_hull_changed(target.hull)
        self._on_target_shield_changed(target.shield)

func _find_target_mesh(target: CombatObject) -> MeshInstance3D:
    var nodes := target.get_parent().get_children()
    var index := nodes.find(func(node: Node) -> bool: return node is MeshInstance3D)
    return nodes[index] if index >= 0 else null

func _on_target_hull_changed(hull: Hull) -> void:
    self.hull_bar.max_value = hull.max_integrity
    self.hull_bar.value = hull.integrity

func _on_target_shield_changed(shield: Shield) -> void:
    self.shield_bar.max_value = maxf(1.0, shield.max_integrity)
    self.shield_bar.value = shield.integrity
