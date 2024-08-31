extends Window
class_name OutfitterWindow

@export var available_outfits_list: ItemList
@export var installed_outfits_list: ItemList
@export var outfit_description: RichTextLabel
@export var outfit_effects: RichTextLabel
@export var cost_label: Label
@export var cost_heading: Label
@export var install_button: Button

var ship: Ship
var available_outfits: Array[Outfit] = []
var money: TradeAsset
var cargo_hold: CargoHold
var bank_account: BankAccount

func _ready() -> void:
    self._clear()

    for outfit in self.available_outfits:
        self.available_outfits_list.add_item(outfit.name)
    
    # TODO: Show multiply installed outfits in the same row.
    for outfit in self.ship.outfits:
        self.installed_outfits_list.add_item(outfit.name)

func _on_empty_clicked(_at_position: Vector2, _mouse_button_index: int) -> void:
    self._clear()

func _clear() -> void:
    self.outfit_description.text = ""
    self.cost_label.text = ""
    self.cost_heading.text = ""
    self.install_button.text = "INSTALL"
    self.install_button.disabled = true

func _on_available_outfit_selected(index: int) -> void:
    var outfit := self.available_outfits[index]

    self.outfit_description.text = outfit.description
    self.outfit_effects.text = "\n".join(outfit.get_effects())

    self.cost_label.text = self.money.amount_as_string(self.money.price_converted_from_credits(outfit.price_in_credits))
    self.cost_heading.text = "Price"

    self.install_button.text = "INSTALL"
    self.install_button.disabled = not outfit.can_install_onto_ship(self.ship)
    
    if self.install_button.pressed.is_connected(_on_uninstall_pressed):
        self.install_button.pressed.disconnect(_on_uninstall_pressed)

    if not self.install_button.pressed.is_connected(_on_install_pressed):
        self.install_button.pressed.connect(_on_install_pressed)

func _on_installed_outfit_selected(index: int) -> void:
    var outfit := self.ship.outfits[index]
    assert(outfit.name == self.installed_outfits_list.get_item_text(index), "Installed outfit name does not match!")

    self.outfit_description.text = outfit.description
    self.outfit_effects.text = "\n".join(outfit.get_effects())

    self.cost_label.text = self.money.amount_as_string(self.money.price_converted_from_credits(outfit.price_in_credits * Outfit.REFUND_PERCENTAGE))
    self.cost_heading.text = "Refund"

    self.install_button.text = "UNINSTALL"
    self.install_button.disabled = false
    
    if self.install_button.pressed.is_connected(_on_install_pressed):
        self.install_button.pressed.disconnect(_on_install_pressed)

    if not self.install_button.pressed.is_connected(_on_uninstall_pressed):
        self.install_button.pressed.connect(_on_uninstall_pressed)

func _on_install_pressed() -> void:
    var selected := self.available_outfits_list.get_selected_items()
    if not selected:
        return
    
    var outfit := self.available_outfits[selected[0]]
    if self.ship.add_outfit(outfit):
        self.installed_outfits_list.add_item(outfit.name)
    
    # TODO: This should probably actually preserve selection, to make it easy to buy multiple of the same outfit.
    self.available_outfits_list.deselect_all()
    self._clear()

func _on_uninstall_pressed() -> void:
    var selected := self.installed_outfits_list.get_selected_items()
    if not selected:
        return
    
    var outfit := self.ship.outfits[selected[0]]
    self.ship.remove_outfit(outfit)
    self.installed_outfits_list.deselect_all()
    self.installed_outfits_list.remove_item(selected[0])
    self._clear()
