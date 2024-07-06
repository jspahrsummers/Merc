extends GridContainer

@export var hull_bar: VitalsFillBar
@export var shield_bar: VitalsFillBar
@export var energy_bar: VitalsFillBar

func _on_player_ship_hull_changed(hull: Hull) -> void:
    self.hull_bar.max_value = hull.max_integrity
    self.hull_bar.value = hull.integrity

func _on_player_ship_shield_changed(shield: Shield) -> void:
    self.shield_bar.max_value = maxf(1.0, shield.max_integrity)
    self.shield_bar.value = shield.integrity

func _on_player_ship_power_changed(battery: Battery) -> void:
    self.energy_bar.max_value = maxf(1.0, battery.max_power)
    self.energy_bar.value = battery.power
