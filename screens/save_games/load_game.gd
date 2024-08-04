extends Control

@export var save_game_list: ItemList
@export var load_button: Button

var _selected_save_game: String = "":
    set(value):
        _selected_save_game = value
        self.load_button.disabled = not value

func _ready() -> void:
    for save_name in SaveGame.get_save_game_names():
        self.save_game_list.add_item(save_name)

func _on_item_selected(index: int) -> void:
    self._selected_save_game = self.save_game_list.get_item_text(index)

func _on_empty_click(_at_position: Vector2, mouse_button_index: int) -> void:
    if mouse_button_index != 0:
        return

    self.save_game_list.deselect_all()
    self._selected_save_game = ""

func _on_load_pressed() -> void:
    var scene_tree := self.get_tree()
    scene_tree.change_scene_to_file(MainMenu.MAIN_GAME_SCENE)

    var result := SaveGame.load(scene_tree, self._selected_save_game)
    if result != Error.OK:
        push_error("Failed to load game: %s" % result)
