extends Window

## The current stage of the tutorial.
##
## Note that these values are saved via [SaveGame], so be careful not to break backwards compatibility!
enum Stage {
    INITIAL = 0,

    DONE = 1000,
}

var _stage: Stage = Stage.INITIAL:
    set(value):
        if _stage == value:
            return
        
        assert(value > _stage, "Tutorial stage should not move backwards")
        _stage = value
        if self.is_inside_tree():
            self._start_stage()

func _enter_tree() -> void:
    if self._stage == Stage.DONE:
        self.queue_free()
    
    self._start_stage()

func _start_stage() -> void:
    pass

func _on_close_requested() -> void:
    self.hide()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_tutorial"):
        self.get_viewport().set_input_as_handled()
        self.hide()

## See [SaveGame].
func save_to_dict() -> Dictionary:
    var result := {}
    result["stage"] = self._stage
    result["visible"] = self.visible
    return result

## See [SaveGame].
func load_from_dict(dict: Dictionary) -> void:
    self._stage = dict["stage"]
    self.visible = dict["visible"]
