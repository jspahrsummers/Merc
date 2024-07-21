extends Window
class_name Landing

@export var bar_button: Button
@export var trading_button: Button
@export var missions_button: Button
@export var outfitter_button: Button
@export var shipyard_button: Button
@export var refuel_button: Button
@export var landscape_image: TextureRect
@export var description_label: RichTextLabel
@export var bar_dialog: AcceptDialog
@export var trading_window_scene: PackedScene

## Defines how the spaceport bar should behave on this landing.
@export var spaceport_bar: SpaceportBar

## The player. Must be set before displaying.
var player: Player

## The planet to land on. Must be set before displaying.
var planet: Planet

## The star system the planet is in. Must be set before displaying.
var star_system: StarSystem

var _hyperdrive: Hyperdrive
var _trading_window: TradingWindow = null

func _ready() -> void:
    self._hyperdrive = self.player.ship.hyperdrive_system.hyperdrive

    self.title = self.planet.name
    self.bar_button.visible = (self.planet.facilities&Planet.BAR)
    self.trading_button.visible = (self.planet.facilities&Planet.TRADING)
    self.missions_button.visible = (self.planet.facilities&Planet.MISSIONS)
    self.outfitter_button.visible = (self.planet.facilities&Planet.OUTFITTER)
    self.shipyard_button.visible = (self.planet.facilities&Planet.SHIPYARD)
    self.refuel_button.visible = (self.planet.facilities&Planet.REFUEL)
    self.landscape_image.texture = self.planet.landscape_image
    self.description_label.text = self.planet.description

    self.refuel_button.disabled = self._hyperdrive.fuel >= self._hyperdrive.max_fuel

func _on_bar_button_pressed() -> void:
    self.bar_dialog.dialog_text = self.spaceport_bar.get_description()
    self.bar_dialog.show()

func _on_trading_button_pressed() -> void:
    assert(self.star_system.market, "Star system must have a market for the planet to have trading")

    if not self._trading_window:
        self._trading_window = self.trading_window_scene.instantiate()
        self._trading_window.market = self.star_system.market
        self._trading_window.cargo_hold = self.player.ship.cargo_hold
        self._trading_window.bank_account = self.player.bank_account
        self.add_child(self._trading_window)

    self._trading_window.show()
    self._trading_window.grab_focus()

func _on_missions_button_pressed() -> void:
    pass # Replace with function body.

func _on_outfitter_button_pressed() -> void:
    pass # Replace with function body.

func _on_shipyard_button_pressed() -> void:
    pass # Replace with function body.

func _on_refuel_button_pressed() -> void:
    var needed_fuel := self._hyperdrive.max_fuel - self._hyperdrive.fuel
    var full_refuel_cost := needed_fuel * self.star_system.refueling_cost
    if full_refuel_cost > 0:
        var paid := self.star_system.refueling_money.take_up_to(full_refuel_cost, self.player.ship.cargo_hold, self.player.bank_account)
        var fuel_paid_for := paid / self.star_system.refueling_cost
        self._hyperdrive.refuel(fuel_paid_for)
    else:
        self._hyperdrive.refuel(needed_fuel)
    
    self.refuel_button.disabled = true

func _on_depart() -> void:
    self.hide()

func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("land", true):
        self.set_input_as_handled()
        self._on_depart()
