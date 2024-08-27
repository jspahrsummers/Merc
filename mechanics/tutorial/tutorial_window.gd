extends Window

@export var label: RichTextLabel
@export var previous_button: Button
@export var next_button: Button

## The current stage of the tutorial.
##
## Note that these values are saved via [SaveGame], so be careful about backwards compatibility!
enum Stage {
    INITIAL = 0,
    SHIP_CONTROLS = 1,
    LAND_ON_PLANET = 2,
    OPEN_GALAXY_MAP = 3,
    HYPERJUMP = 4,
    FINAL = 1000,
}

var _stage: Stage = Stage.INITIAL:
    set(value):
        if _stage == value:
            return
        
        _stage = value
        self._update()

func _ready() -> void:
    self._update()

func _update() -> void:
    self.previous_button.visible = self._stage != Stage.INITIAL
    self.next_button.text = "DONE" if self._stage == Stage.FINAL else "NEXT"

    match self._stage:
        Stage.INITIAL:
            self.label.text = """\
Welcome to your new ship! This tutorial will guide you through the basics of ship control, navigation, and interstellar travel. Let's begin!"""

        Stage.SHIP_CONTROLS:
            var control_scheme := UserPreferences.control_scheme
            var thrust_key := self._get_action_binding("thrust")
            var turn_left_key := self._get_action_binding("turn_left")
            var turn_right_key := self._get_action_binding("turn_right")
            var fire_key := self._get_action_binding("fire")
            
            var movement_text: String
            match UserPreferences.control_scheme:
                UserPreferences.ControlScheme.RELATIVE:
                    movement_text = """\
    - [color=yellow]{thrust_key}[/color]: Thrust forward
    - [color=yellow]{turn_left_key}[/color]/[color=yellow]{turn_right_key}[/color]: Turn left/right""".format({
                        "thrust_key": thrust_key,
                        "turn_left_key": turn_left_key,
                        "turn_right_key": turn_right_key
                    })

                UserPreferences.ControlScheme.ABSOLUTE:
                    movement_text = """\
    - [color=yellow]Arrow keys[/color]: Move in any direction"""

                UserPreferences.ControlScheme.MOUSE_JOYSTICK:
                    movement_text = """\
    - [color=yellow]Mouse[/color] or [color=yellow]touchpad[/color]: Move in any direction"""

                UserPreferences.ControlScheme.CLICK_TO_MOVE:
                    movement_text = """\
    - [color=yellow]Click[/color]: Navigate to your mouse cursor"""

            self.label.text = """\
To maneuver your ship:
{movement_text}
    - [color=yellow]{fire_key}[/color]: Fire weapons
Try moving and firing to get familiar with the controls.""".format({
                "movement_text": movement_text,
                "fire_key": fire_key
            })

        Stage.LAND_ON_PLANET:
            var cycle_landing_target_key := self._get_action_binding("cycle_landing_target")
            var land_key := self._get_action_binding("land")
            
            self.label.text = """\
Stop at ports to refuel, trade, and obtain missions:
    1. Click or press [color=yellow]{cycle_key}[/color] to target a planet, moon, or space station.
    2. Approach your selected port and slow down.
    3. Press [color=yellow]{land_key}[/color] to land.
Try landing on Earth now.""".format({
                "cycle_key": cycle_landing_target_key,
                "land_key": land_key
            })

        Stage.OPEN_GALAXY_MAP:
            var toggle_galaxy_map_key := self._get_action_binding("toggle_galaxy_map")
            
            self.label.text = """\
The galaxy awaits you beyond Sol! You can use the galaxy map to navigate:
    1. Press [color=yellow]{map_key}[/color] to open the map.
    2. Click a system to set as destination.
    3. Click the X or press [color=yellow]{map_key}[/color] to close the map.
Select the neighboring system Thalassa from the galaxy map.""".format({
                "map_key": toggle_galaxy_map_key
            })

        Stage.HYPERJUMP:
            var jump_key := self._get_action_binding("jump")
            
            self.label.text = """\
Now that you have selected Thalassa, you can initiate a hyperspace jump.

Press [color=yellow]{jump_key}[/color] to make the jump to Thalassa now.""".format({
                "jump_key": jump_key
            })
        
        Stage.FINAL:
            var toggle_tutorial_key := self._get_action_binding("toggle_tutorial")

            self.label.text = """\
Congratulations, you're ready to head out on your own! Explore, trade, and complete missions as you travel the galaxy—and don't forget to refuel your hyperdrive!

Good luck, pilot.""".format({
                "toggle_tutorial_key": toggle_tutorial_key
            })

func _on_close_requested() -> void:
    self.hide()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_tutorial"):
        self.get_viewport().set_input_as_handled()
        self.hide()

func _get_action_binding(action: StringName) -> String:
    return InputMap.action_get_events(action)[0].as_text()

## See [SaveGame].
func save_to_dict() -> Dictionary:
    var result := {}
    result["stage"] = self._stage
    result["visible"] = self.visible
    return result

## See [SaveGame].
func load_from_dict(dict: Dictionary) -> void:
    self._stage = dict["stage"]
    self.visible = dict["visible"] and UserPreferences.tutorial_enabled

func _on_previous_button_pressed() -> void:
    assert(self._stage != Stage.INITIAL, "Previous button should not be clickable when on initial tutorial stage")

    var stages := Stage.values()
    var index := stages.find(self._stage)

    assert(index != -1, "Could not find current tutorial stage")
    self._stage = stages[index - 1]

func _on_next_button_pressed() -> void:
    if self._stage == Stage.FINAL:
        self.hide()
        return

    var stages := Stage.values()
    var index := stages.find(self._stage)

    assert(index != -1, "Could not find current tutorial stage")
    self._stage = stages[index + 1]
