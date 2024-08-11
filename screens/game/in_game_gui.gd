extends CanvasLayer

@export var galaxy_map_scene: PackedScene
@export var game_over_scene: PackedScene
@export var exit_dialog_scene: PackedScene
@export var currency_trading_scene: PackedScene
@export var mission_log_scene: PackedScene
@export var player: Player

func _on_player_ship_destroyed(_player: Player) -> void:
    self._instantiate_and_show_window(self.game_over_scene)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_galaxy_map") and is_instance_valid(self.player):
        var galaxy_map: GalaxyMap = self.galaxy_map_scene.instantiate()
        galaxy_map.hyperdrive_system = self.player.ship.hyperdrive_system
        self.add_child(galaxy_map)
        galaxy_map.show()
    elif event.is_action_pressed("toggle_currency_trading") and is_instance_valid(self.player):
        var currency_trading: CurrencyTradingWindow = self.currency_trading_scene.instantiate()
        currency_trading.bank_account = self.player.bank_account
        self.add_child(currency_trading)
        currency_trading.show()
    elif event.is_action_pressed("toggle_mission_list") and is_instance_valid(self.player):
        var mission_log: MissionLogWindow = self.mission_log_scene.instantiate()
        mission_log.mission_controller = self.player.mission_controller
        self.add_child(mission_log)
        mission_log.show()
    elif event.is_action_pressed("exit"):
        self._instantiate_and_show_window(self.exit_dialog_scene)

func _instantiate_and_show_window(scene: PackedScene) -> void:
    var window: Window = scene.instantiate()
    self.add_child(window)
    window.show()
