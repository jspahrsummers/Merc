extends Control
class_name OutfittingUI

@export var available_outfits_list: ItemList
@export var installed_outfits_list: ItemList
@export var outfit_description: RichTextLabel
@export var install_button: Button
@export var uninstall_button: Button

var player_ship: Ship
var available_outfits: Array[Outfit] = []

func _ready() -> void:
    install_button.pressed.connect(_on_install_pressed)
    uninstall_button.pressed.connect(_on_uninstall_pressed)
    available_outfits_list.item_selected.connect(_on_available_outfit_selected)
    installed_outfits_list.item_selected.connect(_on_installed_outfit_selected)

func initialize(ship: Ship, outfits: Array[Outfit]) -> void:
    player_ship = ship
    available_outfits = outfits
    _update_ui()

func _update_ui() -> void:
    available_outfits_list.clear()
    installed_outfits_list.clear()
    
    for outfit in available_outfits:
        available_outfits_list.add_item(outfit.name)
    
    for outfit in player_ship.outfits:
        installed_outfits_list.add_item(outfit.name)
    
    _update_buttons()

func _update_buttons() -> void:
    install_button.disabled = available_outfits_list.get_selected_items().is_empty() or not player_ship.can_install_outfit(available_outfits[available_outfits_list.get_selected_items()[0]])
    uninstall_button.disabled = installed_outfits_list.get_selected_items().is_empty()

func _on_available_outfit_selected(index: int) -> void:
    outfit_description.text = available_outfits[index].get_description()
    _update_buttons()

func _on_installed_outfit_selected(index: int) -> void:
    outfit_description.text = player_ship.outfits[index].get_description()
    _update_buttons()

func _on_install_pressed() -> void:
    var selected_indices = available_outfits_list.get_selected_items()
    if selected_indices.is_empty():
        return
    
    var outfit = available_outfits[selected_indices[0]]
    if player_ship.add_outfit(outfit):
        _update_ui()

func _on_uninstall_pressed() -> void:
    var selected_indices = installed_outfits_list.get_selected_items()
    if selected_indices.is_empty():
        return
    
    var outfit = player_ship.outfits[selected_indices[0]]
    if player_ship.remove_outfit(outfit):
        _update_ui()