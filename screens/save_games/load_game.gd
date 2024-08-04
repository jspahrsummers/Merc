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
    
    if self.save_game_list.item_count > 0:
        self.save_game_list.select(0)
        self._selected_save_game = self.save_game_list.get_item_text(0)

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
    SaveGame.load_async_after_scene_change(self._selected_save_game)
