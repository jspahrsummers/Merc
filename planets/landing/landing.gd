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

func _on_depart_button_pressed() -> void:
    self.hide()

func _on_visibility_changed() -> void:
    if not self.visible:
        self.queue_free()
