extends Node3D
class_name RigidBodyThruster

## Attaches to a [RigidBody3D] to implement thrust behaviors.
##
## [b]This script expects the parent node to be a [RigidBody3D].[/b]

@export var thruster: Thruster

## The [Battery] to power the thruster from.
@export var battery: Battery

## An audio clip to play while the thruster is active.
##
## This audio stream should be a looping sound. Rather than restarting from the beginning each time the thruster is used, the audio stream is paused and resumed, and evenutally loops.
@export var thruster_audio: AudioStreamPlayer3D

## If set to a value greater than 0, all child [member GeometryInstance3D.transparency] values will be animated in and out depending on whether the thruster is active.
##
## This duration applies to the animation in, or the animation out, not the combination of the two.
@export var animation_duration: float = 0.4

@export var animation_transition: Tween.TransitionType = Tween.TRANS_CUBIC
@export var animation_ease: Tween.EaseType = Tween.EASE_IN_OUT

## The current level of throttle (where 1.0 is full throttle), which corresponds to the magnitude of the thrust to apply, as well as the amount of power to be consumed.
var throttle: float:
    set(value):
        throttle = maxf(0.0, value)

## Any in-flight animation tweening.
var _tween: Tween

## The target transparency for the current animation.
##
## Can be used to selectively replace the existing tween if it's not animating to the desired value already.
var _target_transparency: float = 1.0

## The geometry to animate.
var _animation_geometry: Array[GeometryInstance3D]

## The [RigidBody3D] to apply thrust to.
@onready var _rigid_body := get_parent() as RigidBody3D

func _ready() -> void:
    if self.animation_duration > 0.0:
        self._animation_geometry = []
        for child_index in self.get_child_count():
            var geometry_instance := self.get_child(child_index) as GeometryInstance3D
            if not geometry_instance:
                continue
            
            self._animation_geometry.push_back(geometry_instance)
        
        for geometry in self._animation_geometry:
            geometry.transparency = 1.0

func _physics_process(delta: float) -> void:
    if is_zero_approx(self.throttle) or is_zero_approx(self.battery.power):
        self.thruster_audio.stream_paused = true
        self._animate_transparency(1.0)
        return
    
    if self.thruster_audio.stream_paused:
        self.thruster_audio.stream_paused = false
    if !self.thruster_audio.playing:
        self.thruster_audio.play()
    
    var desired_power := self.thruster.power_consumption_rate * self.throttle * delta
    var power_consumed := self.battery.consume_up_to(desired_power)
    var magnitude := self.throttle * (power_consumed / desired_power)
    self._animate_transparency(1.0 - magnitude)
    self._rigid_body.apply_central_force(self._rigid_body.transform.basis * Vector3.FORWARD * self.thruster.thrust_force * magnitude)

## Animates child geometry to the specified transparency value.
func _animate_transparency(to_transparency: float) -> void:
    if is_equal_approx(self._target_transparency, to_transparency) or not self._animation_geometry:
        return

    if self._tween != null:
        self._tween.kill()

    var tween := self.create_tween()
    tween.set_parallel(true)
    tween.set_trans(self.animation_transition)
    tween.set_ease(self.animation_ease)

    # Animate faster for smaller changes
    var duration := self.animation_duration * absf(self._target_transparency - to_transparency)

    for geometry in self._animation_geometry:
        tween.tween_property(geometry, "transparency", to_transparency, duration)
    
    self._tween = tween
    self._target_transparency = to_transparency
