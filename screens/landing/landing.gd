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
@export var missions_window_scene: PackedScene

## Defines how the spaceport bar should behave on this landing.
@export var spaceport_bar: SpaceportBar

## The player. Must be set before displaying.
var player: Player

## The planet to land on. Must be set before displaying.
var planet_instance: PlanetInstance

## The star system the planet is in. Must be set before displaying.
var star_system: StarSystem

var _planet: Planet
var _hyperdrive: Hyperdrive
var _trading_window: TradingWindow = null
var _missions_window: MissionComputerWindow = null

func _ready() -> void:
    self._hyperdrive = self.player.ship.hyperdrive
    self._planet = self.planet_instance.planet

    self.title = self._planet.name
    self.bar_button.visible = (self._planet.facilities & Planet.BAR)
    self.trading_button.visible = (self._planet.facilities & Planet.TRADING)
    self.missions_button.visible = (self._planet.facilities & Planet.MISSIONS)
    self.outfitter_button.visible = (self._planet.facilities & Planet.OUTFITTER)
    self.shipyard_button.visible = (self._planet.facilities & Planet.SHIPYARD)
    self.refuel_button.visible = (self._planet.facilities & Planet.REFUEL)
    self.landscape_image.texture = self._planet.landscape_image
    self.description_label.text = self._planet.description

    self._update_refuel_button()

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
    if not self._missions_window:
        self._missions_window = self.missions_window_scene.instantiate()
        self._missions_window.available_missions = self.planet_instance.get_available_missions(self.player.calendar, self.player.hero_roster)
        self._missions_window.mission_controller = self.player.mission_controller
        self._missions_window.cargo_hold = self.player.ship.cargo_hold
        self._missions_window.bank_account = self.player.bank_account
        self.add_child(self._missions_window)

    self._missions_window.show()
    self._missions_window.grab_focus()

func _on_outfitter_button_pressed() -> void:
    pass # Replace with function body.

func _on_shipyard_button_pressed() -> void:
    pass # Replace with function body.

func _update_refuel_button() -> void:
    var full := self._hyperdrive.fuel >= self._hyperdrive.max_fuel
    var can_pay := self.star_system.refueling_money == null \
        or self.star_system.refueling_money.current_amount(self.player.ship.cargo_hold, self.player.bank_account) >= self.star_system.refueling_price()

    if full:
        self.refuel_button.disabled = true
        self.refuel_button.tooltip_text = "Already full"
    elif not can_pay:
        self.refuel_button.disabled = true
        self.refuel_button.tooltip_text = "Cannot afford %s" % self.star_system.refueling_money.amount_as_string(self.star_system.refueling_price())
    else:
        var needed_fuel := self._hyperdrive.max_fuel - self._hyperdrive.fuel
        var full_refuel_cost := needed_fuel * self.star_system.refueling_price()
        self.refuel_button.disabled = false
        self.refuel_button.tooltip_text = "Refuel for %s" % self.star_system.refueling_money.amount_as_string(full_refuel_cost)

func _on_refuel_button_pressed() -> void:
    var needed_fuel := self._hyperdrive.max_fuel - self._hyperdrive.fuel
    if self.star_system.refueling_money == null:
        self._hyperdrive.refuel(needed_fuel)
    else:
        var refueling_price := self.star_system.refueling_price()
        var full_refuel_cost := needed_fuel * refueling_price
        var paid := self.star_system.refueling_money.take_up_to(full_refuel_cost, self.player.ship.cargo_hold, self.player.bank_account)
        var fuel_paid_for := paid / refueling_price
        self._hyperdrive.refuel(fuel_paid_for)

    self._update_refuel_button()

func _on_depart() -> void:
    self.hide()

func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("land", true):
        self.set_input_as_handled()
        self._on_depart()
