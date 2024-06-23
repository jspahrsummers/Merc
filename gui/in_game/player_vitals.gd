extends GridContainer

@export var hull_bar: VitalsFillBar
@export var shield_bar: VitalsFillBar
@export var energy_bar: VitalsFillBar

func _on_player_ship_hull_changed(ship: Ship) -> void:
    assert(ship.ship_def.hull > 0.0, "Ship definition should not have 0 hull")
    self.hull_bar.max_value = ship.ship_def.hull
    self.hull_bar.value = ship.hull

func _on_player_ship_shield_changed(ship: Ship) -> void:
    self.shield_bar.max_value = 1.0 if is_zero_approx(ship.ship_def.shield) else ship.ship_def.shield
    self.shield_bar.value = ship.shield

func _on_player_ship_energy_changed(ship: Ship) -> void:
    self.energy_bar.max_value = 1.0 if is_zero_approx(ship.ship_def.energy) else ship.ship_def.energy
    self.energy_bar.value = ship.energy
