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

## Defines how the spaceport bar should behave on this landing.
@export var spaceport_bar: SpaceportBar

## The player. Must be set before displaying.
var player: Player

## The planet to land on. Must be set before displaying.
var planet: Planet

## The star system the planet is in. Must be set before displaying.
var star_system: StarSystem

var _hyperdrive: Hyperdrive

func _ready() -> void:
    self._hyperdrive = self.player.ship.hyperdrive_system.hyperdrive

    self.title = self.planet.name
    self.bar_button.visible = (self.planet.facilities&Planet.BAR)

    if self.planet.facilities&Planet.TRADING:
        assert(self.star_system.market, "Star system must have a market for the planet to have trading")
        self.trading_button.visible = true
    else:
        self.trading_button.visible = false

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
    pass # Replace with function body.

func _on_missions_button_pressed() -> void:
    pass # Replace with function body.

func _on_outfitter_button_pressed() -> void:
    pass # Replace with function body.

func _on_shipyard_button_pressed() -> void:
    pass # Replace with function body.

func _on_refuel_button_pressed() -> void:
    var needed_fuel := self._hyperdrive.max_fuel - self._hyperdrive.fuel
    var full_refuel_cost := ceili(needed_fuel * self.star_system.refueling_cost)

    var paid := self.star_system.refueling_money.take_up_to(full_refuel_cost, self.player.ship.cargo_hold, self.player.bank_account)
    var fuel_paid_for := float(paid) / self.star_system.refueling_cost

    self._hyperdrive.refuel(fuel_paid_for)
    self.refuel_button.disabled = true

func _on_depart() -> void:
    self.hide()

func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("land", true):
        self.set_input_as_handled()
        self._on_depart()
