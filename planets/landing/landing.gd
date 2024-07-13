extends Window

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
