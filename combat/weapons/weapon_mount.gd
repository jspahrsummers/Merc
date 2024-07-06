extends Node3D

## Physically attaches a weapon to a ship, powering and controlling its firing.
##
## [b]This script expects the parent node to be a [RigidBody3D].[/b] The [WeaponMount] is used as the origin for any weapon projectiles and effects.

## The weapon to be fired.
@export var weapon: Weapon

## The [Battery] to power the weapon from.
@export var battery: Battery

## The tick (in microseconds) in which the weapon was last fired. 
var _last_fired_usec: int = -1

## The [RigidBody3D] firing the projectile.
@onready var _rigid_body := get_parent() as RigidBody3D

func fire() -> bool:
    var now := Time.get_ticks_usec()
    if self._last_fired_usec >= 0 and (now - self._last_fired_usec) / MathUtils.USEC_PER_SEC_F < self.weapon.fire_interval:
        return false
    
    if not self.battery.consume_exactly(self.weapon.power_consumption):
        return false
    
    var projectile_instance: RigidBody3D = self.weapon.projectile.instantiate()
    get_tree().root.add_child(projectile_instance)
    projectile_instance.add_collision_exception_with(self._rigid_body)
    projectile_instance.global_transform = self.global_transform
    projectile_instance.linear_velocity = self._rigid_body.linear_velocity
    projectile_instance.apply_central_impulse(projectile_instance.transform.basis * self.weapon.fire_force * Vector3.FORWARD)

    self._last_fired_usec = now
    return true
