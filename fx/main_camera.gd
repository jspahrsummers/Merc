extends Camera3D
class_name MainCamera

## The closest zoom (in m) allowed on the main camera.
const ZOOM_CLOSEST: float = 5.0

## The default zoom of the main camera.
const ZOOM_DEFAULT: float = 10.0

## The furthest zoom (in m) allowed on the main camera.
const ZOOM_FURTHEST: float = 15.0

## How much to zoom incrementally.
const ZOOM_STEP: float = 1.0

var _camera_zoom: float

func _ready() -> void:
    self._camera_zoom = UserPreferences.get_custom_value("camera", "zoom", ZOOM_DEFAULT)

## Projects a screen-space point to a world-space position via this camera.
func project_position_with_zoom(screen_position: Vector2) -> Vector3:
    return self.project_position(screen_position, self._camera_zoom)

func _set_camera_zoom(value: float) -> void:
    value = clampf(value, ZOOM_CLOSEST, ZOOM_FURTHEST)
    if is_equal_approx(value, self._camera_zoom):
        return

    self._camera_zoom = value
    self.global_transform.origin.y = self._camera_zoom
    UserPreferences.set_custom_value("camera", "zoom", value)

func _unhandled_input(event: InputEvent) -> void:
    var pan_event := event as InputEventPanGesture
    if pan_event != null:
        self._set_camera_zoom(self._camera_zoom + pan_event.delta.y)
        self.get_viewport().set_input_as_handled()
    
    if event.is_action_pressed("camera_zoom_in"):
        self._set_camera_zoom(self._camera_zoom - ZOOM_STEP)
        self.get_viewport().set_input_as_handled()

    if event.is_action_pressed("camera_zoom_out"):
        self._set_camera_zoom(self._camera_zoom + ZOOM_STEP)
        self.get_viewport().set_input_as_handled()
