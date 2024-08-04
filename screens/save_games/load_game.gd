extends Control

@export var save_game_list: ItemList
@export var load_button: Button

var _selected_save_game: String = "":
    set(value):
        _selected_save_game = value
        self.load_button.disabled = not value

func _ready() -> void:
    for save_name in self._get_save_game_names():
        self.save_game_list.add_item(save_name)

func _get_save_game_names() -> Array[String]:
    var dir := DirAccess.open(SaveGame.SAVE_GAMES_DIRECTORY)
    if not dir:
        return []

    var paths: Array[String] = []

    dir.list_dir_begin()
    var file_name := dir.get_next()
    while file_name:
        if not dir.current_is_dir() and file_name.ends_with(".json"):
            paths.append(file_name.substr(0, file_name.length() - 5))

        file_name = dir.get_next()
    
    return paths

func _on_item_selected(index: int) -> void:
    self._selected_save_game = self.save_game_list.get_item_text(index)

func _on_empty_click(_at_position: Vector2, mouse_button_index: int) -> void:
    if mouse_button_index != 0:
        return

    self.save_game_list.deselect_all()
    self._selected_save_game = ""

func _on_load_pressed() -> void:
    var path := SaveGame.SAVE_GAMES_DIRECTORY.path_join(self._selected_save_game + ".json")
    var scene_tree := self.get_tree()
    scene_tree.change_scene_to_file(MainMenu.MAIN_GAME_SCENE)
    SaveGame.load(scene_tree, path)
