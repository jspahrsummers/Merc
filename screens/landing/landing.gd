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

# The planet to land on. Must be set before displaying.
var planet: Planet

func _ready() -> void:
    self.title = self.planet.name
    self.bar_button.visible = (self.planet.facilities&Planet.BAR)
    self.trading_button.visible = (self.planet.facilities&Planet.TRADING)
    self.missions_button.visible = (self.planet.facilities&Planet.MISSIONS)
    self.outfitter_button.visible = (self.planet.facilities&Planet.OUTFITTER)
    self.shipyard_button.visible = (self.planet.facilities&Planet.SHIPYARD)
    self.refuel_button.visible = (self.planet.facilities&Planet.REFUEL)
    self.landscape_image.texture = self.planet.landscape_image
    self.description_label.text = self.planet.description

func _on_bar_button_pressed() -> void:
    pass # Replace with function body.

func _on_trading_button_pressed() -> void:
    pass # Replace with function body.

func _on_missions_button_pressed() -> void:
    pass # Replace with function body.

func _on_outfitter_button_pressed() -> void:
    pass # Replace with function body.

func _on_shipyard_button_pressed() -> void:
    pass # Replace with function body.

func _on_refuel_button_pressed() -> void:
    pass # Replace with function body.

func _on_depart() -> void:
    self.hide()

func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("land", true):
        self.set_input_as_handled()
        self._on_depart()
