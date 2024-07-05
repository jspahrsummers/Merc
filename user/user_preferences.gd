extends Node

## Describes the user's preferred control scheme.
enum ControlScheme {
    ## Directional keys apply a change relative to the player ship's current orientation.
    RELATIVE = 0,

    ## Directional keys apply an absolute change, ignoring the player ship's orientation.
    ABSOLUTE = 1
}

## Fires whenever a user preference changes.
signal preferences_updated

const PREFERENCES_PATH = "user://preferences.cfg"

var _config: ConfigFile = ConfigFile.new()

## The control scheme that the user has selected.
var control_scheme: ControlScheme:
    get:
        return self._config.get_value("controls", "control_scheme", ControlScheme.RELATIVE)
    set(value):
        self._config.set_value("controls", "control_scheme", value)
        self._updated()

## The scale of UI elements (where 1 means 1x).
var ui_scale: float:
    get:
        return self._config.get_value("display", "ui_scale", ProjectSettings.get_setting_with_override("display/window/stretch/scale"))
    set(value):
        self._config.set_value("display", "ui_scale", value)
        self._updated()

func _ready() -> void:
    self.reload()

## Load user preferences from disk.
func reload() -> void:
    self._config.clear()
    var load_result := self._config.load(PREFERENCES_PATH)
    
    if load_result == Error.OK:
        print("User preferences loaded from: ", ProjectSettings.globalize_path(PREFERENCES_PATH))
    elif load_result == Error.ERR_FILE_NOT_FOUND:
        print("No user preferences found at: ", ProjectSettings.globalize_path(PREFERENCES_PATH), ", using defaults.")
    else:
        push_error("Failed to load user preferences file ", ProjectSettings.globalize_path(PREFERENCES_PATH), " with error ", load_result)

    self._updated()

## Save user preferences to disk.
func save() -> void:
    var save_result := self._config.save(PREFERENCES_PATH)
    if save_result == Error.OK:
        print("User preferences saved to: ", ProjectSettings.globalize_path(PREFERENCES_PATH))
    else:
        push_error("Failed to save user preferences file ", ProjectSettings.globalize_path(PREFERENCES_PATH), " with error ", save_result)

## Reads a custom value previously set with [method set_custom_value].
func get_custom_value(section: String, key: String, default_value: Variant) -> Variant:
    return self._config.get_value(section, key, default_value)

## Saves a custom value to the user preferences.
##
## This can be used by scripts to record small bits of data or state persistently, without surfacing it in the UI. Consequently, this behaves a bit differently than the "canonical" preferences; the setting will automatically be persisted to disk, and no signal will be emitted for observers.
func set_custom_value(section: String, key: String, value: Variant) -> void:
    self._config.set_value(section, key, value)

    # TODO: This will save any unsaved preference modifications the user made.
    # We should probably just disallow exiting the settings screen without
    # saving or reverting.
    self.call_deferred("save")

## Call this whenever user preferences change, so the UI can be updated.
func _updated() -> void:
    self.get_window().content_scale_factor = self.ui_scale
    self.emit_signal("preferences_updated")
