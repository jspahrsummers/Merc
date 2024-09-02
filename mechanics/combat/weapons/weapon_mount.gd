extends Node3D
class_name WeaponMount

## Physically attaches a weapon to a ship, powering and controlling its firing.
##
## [b]This script expects the parent node to be a [RigidBody3D].[/b] The [WeaponMount] is used as the origin for any weapon projectiles and effects.

## The weapon to be fired, or null if no weapon is mounted here.
@export var weapon: Weapon:
    set(value):
        if value == weapon:
            return
        
        weapon = value
        self._last_fired_usec = -1

## The offset, as a percentage of the weapon's [member Weapon.fire_interval], when this mount will fire.
##
## This can be used to synchronize or desynchronize the firing of different weapon mounts on the same ship.
@export_range(0, 1) var fire_offset: float = 0.0

## The [Battery] to power the weapon from.
var battery: Battery

## The [HeatSink] to dump heat into.
var heat_sink: HeatSink

## Set to true when this weapon should automatically fire; set to false to stop firing.
var firing: bool = false:
    set(value):
        if value == firing:
            return
        
        firing = value
        if firing:
            self._started_firing_usec = Time.get_ticks_usec()
        else:
            self._started_firing_usec = -1

## The tick (in microseconds) in which the weapon was last fired. 
var _last_fired_usec: int = -1

## The tick (in microseconds) in which the current round of firing began. 
var _started_firing_usec: int = -1

## The [RigidBody3D] firing the projectile.
@onready var _rigid_body := get_parent() as RigidBody3D

func _physics_process(_delta: float) -> void:
    if not self.firing or not self.weapon:
        return
    
    var now := Time.get_ticks_usec()
    if not is_zero_approx(self.fire_offset):
        var offset_sec := self.weapon.fire_interval * self.fire_offset
        if (now - self._started_firing_usec) / MathUtils.USEC_PER_SEC_F < offset_sec:
            return

    if self._last_fired_usec >= 0 and (now - self._last_fired_usec) / MathUtils.USEC_PER_SEC_F < self.weapon.fire_interval:
        return
    
    if not self.battery.consume_exactly(self.weapon.power_consumption):
        return
    
    var projectile_instance: RigidBody3D = self.weapon.projectile.instantiate()
    get_parent().add_sibling(projectile_instance)
    projectile_instance.add_collision_exception_with(self._rigid_body)
    projectile_instance.global_transform = self.global_transform
    projectile_instance.linear_velocity = self._rigid_body.linear_velocity
    projectile_instance.apply_central_impulse(projectile_instance.transform.basis * self.weapon.fire_force * Vector3.FORWARD)

    self._last_fired_usec = now
    self.heat_sink.heat += self.weapon.heat
