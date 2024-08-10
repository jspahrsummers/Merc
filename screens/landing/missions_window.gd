extends Window

@export var mission_list: ItemList
@export var cost_label: Label
@export var reward_label: Label
@export var start_button: Button

func _on_close_requested() -> void:
    self.visible = false


func _on_empty_clicked(at_position: Vector2, mouse_button_index: int) -> void:
    pass # Replace with function body.


func _on_multi_selected(index: int, selected: bool) -> void:
    pass # Replace with function body.


func _on_start_pressed() -> void:
    pass # Replace with function body.
