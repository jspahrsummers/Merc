extends Camera3D

## A node to automatically follow with the camera.
@export var follow_target: Node3D

## The starfield below the game plane.
@export var starfield_node: Node3D

## The material rendering the starfield below the game plane.
@export var starfield_material: StandardMaterial3D

## How much to dampen movement of the starfield below the game plane, while it moves in concert with the camera.
@export var starfield_parallax_dampening: float = 50

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

func _set_camera_zoom(value: float) -> void:
    value = clampf(value, ZOOM_CLOSEST, ZOOM_FURTHEST)
    if is_equal_approx(value, self._camera_zoom):
        return

    self._camera_zoom = value
    UserPreferences.set_custom_value("camera", "zoom", value)

func _process(_delta: float) -> void:
    var follow_origin := follow_target.global_transform.origin

    var new_camera_origin := follow_origin
    new_camera_origin.y = self._camera_zoom

    var new_starfield_origin := follow_origin
    new_starfield_origin.y = self.starfield_node.global_transform.origin.y

    self.global_transform.origin = new_camera_origin
    self.starfield_node.global_transform.origin = new_starfield_origin
    self.starfield_material.uv1_offset = Vector3(follow_origin.x, follow_origin.z, 0) / self.starfield_parallax_dampening

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
