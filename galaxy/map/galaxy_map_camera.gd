extends Camera3D
class_name GalaxyMapCamera

## A movable camera used to view the 3D galaxy map.
##
## The user can zoom the camera, and rotate around a sphere centered on a particular point (e.g., a star system).

## The point that the camera should be focused on.
##
## No matter how it is zoomed or rotated, the camera will keep the center of its frustum pointed at this position.
@export var center: Vector3:
    get:
        return self._center
    set(value):
        self._center = value
        self._update_camera_position()

## The radius of the sphere along which the camera should move, when rotated.
##
## Increasing this value zooms out the camera, while decreasing it zooms in.
@export var radius: float = 7.5

## The minimum radius the camera is allowed to zoom in to.
@export var min_radius: float = 5.0

## The maximum radius the camera is allowed to zoom out to.
@export var max_radius: float = 10.0

## How much relative mouse motion should translate into camera rotation.
@export var mouse_sensitivity: float = 0.005

## How much the camera should zoom in and out, per step, when using a scroll wheel.
@export var zoom_sensitivity: float = 1

var _center: Vector3 = Vector3.ZERO

## How far left or right the camera has rotated around the center point.
var _theta: float = 0.0

## How far up or down the camera is tilted.
var _phi: float = PI / 4 # start at 45 degree inclination

func _ready() -> void:
    self._update_camera_position()

func _input(event: InputEvent) -> void:
    var motion := event as InputEventMouseMotion
    var pan := event as InputEventPanGesture
    if motion != null and Input.is_action_pressed("galaxy_map_camera_rotate"):
        self._theta -= motion.relative.x * self.mouse_sensitivity
        self._phi = clamp(self._phi - motion.relative.y * self.mouse_sensitivity, -PI / 2 + 0.1, PI / 2 - 0.1)
        self._update_camera_position()
        self.get_viewport().set_input_as_handled()
    elif pan != null:
        self._set_radius(self.radius + pan.delta.y)
        self._update_camera_position()
        self.get_viewport().set_input_as_handled()

    if event.is_action_pressed("camera_zoom_in"):
        self._set_radius(self.radius - self.zoom_sensitivity)
        self._update_camera_position()
        self.get_viewport().set_input_as_handled()

    if event.is_action_pressed("camera_zoom_out"):
        self._set_radius(self.radius + self.zoom_sensitivity)
        self._update_camera_position()
        self.get_viewport().set_input_as_handled()

func _set_radius(value: float) -> void:
    self.radius = clampf(value, self.min_radius, self.max_radius)
    self._update_camera_position()

func _update_camera_position() -> void:
    var x := self.radius * sin(self._theta) * cos(self._phi)
    var y := self.radius * sin(self._phi)
    var z := self.radius * cos(self._theta) * cos(self._phi)

    self.transform.origin = Vector3(x, y, z) + self.center
    self.look_at(self.center, Vector3.UP)
