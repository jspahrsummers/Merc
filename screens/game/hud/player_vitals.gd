extends GridContainer

@export var hull_bar: VitalsFillBar
@export var shield_bar: VitalsFillBar
@export var power_bar: VitalsFillBar

func _on_player_hull_changed(_player: Player, hull: Hull) -> void:
    self.hull_bar.max_value = hull.max_integrity
    self.hull_bar.value = hull.integrity

func _on_player_shield_changed(_player: Player, shield: Shield) -> void:
    self.shield_bar.max_value = maxf(1.0, shield.max_integrity)
    self.shield_bar.value = shield.integrity

func _on_player_power_changed(_player: Player, battery: Battery) -> void:
    self.power_bar.max_value = maxf(1.0, battery.max_power)
    self.power_bar.value = battery.power
