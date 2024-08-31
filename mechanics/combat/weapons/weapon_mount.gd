extends Node3D
class_name WeaponMount

## Physically attaches a weapon to a ship, powering and controlling its firing.
##
## [b]This script expects the parent node to be a [RigidBody3D].[/b] The [WeaponMount] is used as the origin for any weapon projectiles and effects.

## The weapon outfit installed in this mount.
var weapon_outfit: WeaponOutfit

## An audio clip to play while the weapon is firing.
##
## This audio stream should be a looping sound. Rather than restarting from the beginning each time the weapon is fired, the audio stream is paused and resumed, and eventually loops.
@export var weapon_audio: AudioStreamPlayer3D

## If set to a value greater than 0, all child [member GeometryInstance3D.transparency] values will be animated in and out depending on whether the weapon is active.
##
## This duration applies to the animation in, or the animation out, not the combination of the two.
@export var animation_duration: float = 0.4

@export var animation_transition: Tween.TransitionType = Tween.TRANS_CUBIC
@export var animation_ease: Tween.EaseType = Tween.EASE_IN_OUT

## The [Battery] to power the weapon from.
var battery: Battery

## The tick (in microseconds) in which the weapon was last fired. 
var _last_fired_usec: int = -1

## The [RigidBody3D] firing the projectile.
@onready var _rigid_body := get_parent() as RigidBody3D

## Any in-flight animation tweening.
var _tween: Tween

## The target transparency for the current animation.
##
## Can be used to selectively replace the existing tween if it's not animating to the desired value already.
var _target_transparency: float = 1.0

## The geometry to animate.
var _animation_geometry: Array[GeometryInstance3D]

func _enter_tree() -> void:
    if self.animation_duration > 0.0:
        self._animation_geometry = []
        for child_index in self.get_child_count():
            var geometry_instance := self.get_child(child_index) as GeometryInstance3D
            if not geometry_instance:
                continue
            
            self._animation_geometry.push_back(geometry_instance)
        
        for geometry in self._animation_geometry:
            geometry.transparency = 1.0

    if self._tween:
        self._tween.kill()
        self._tween = null
    
    self._target_transparency = 1.0

func fire() -> bool:
    if not self.weapon_outfit:
        return false

    var now := Time.get_ticks_usec()
    if self._last_fired_usec >= 0 and (now - self._last_fired_usec) / MathUtils.USEC_PER_SEC_F < 1.0 / self.weapon_outfit.fire_rate:
        return false
    
    if not self.battery.consume_exactly(self.weapon_outfit.power_consumption):
        return false
    
    # TODO: Implement firing logic using weapon_outfit properties
    # This might involve instantiating a projectile, setting its damage, etc.
    
    self._last_fired_usec = now
    return true

## Installs a weapon outfit in this mount.
func install_weapon(outfit: WeaponOutfit) -> void:
    self.weapon_outfit = outfit
    # TODO: Update visual representation of the weapon

## Removes the currently installed weapon outfit.
func uninstall_weapon() -> void:
    self.weapon_outfit = null
    # TODO: Reset visual representation of the weapon

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