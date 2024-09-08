extends RigidBody3D
class_name Projectile

## How long before the projectile expires (in milliseconds).
@export var lifetime_msec: int = 2000

## How much damage the projectile does.
@export var damage: Damage

## An explosion to instantiate upon collision.
@export var explosion: PackedScene

## The force (in N) with which this projectile follows its [member target].
##
## Set to 0 to disable target tracking.
@export var thrust_force: float

## The maximum turning rate, in rad/s, if this projectile has [member target] tracking.
##
## At the moment, this affects visuals only (not physics).
@export var turning_rate: float

## The [CombatObject] that was being targeted when this projectile was fired.
var target: CombatObject

## The [CombatObject] which launched this projectile.
var fired_by: CombatObject

var _spawn_time_msec: int

func _ready() -> void:
    self._spawn_time_msec = Time.get_ticks_msec()

    if self.target:
        self.target.hull.hull_destroyed.connect(_target_destroyed)

func _target_destroyed(_hull: Hull) -> void:
    self.target = null

func _physics_process(_delta: float) -> void:
    if Time.get_ticks_msec() - self._spawn_time_msec > self.lifetime_msec:
        self.queue_free()
        return

    if not self.target or is_zero_approx(self.thrust_force):
        return

    # TODO: This is kinda EZ mode, because the projectile is not constrained by a particular rotation speed or velocity limiter.
    var desired_direction := (self.target.global_transform.origin - self.global_transform.origin).normalized()
    self.apply_central_force(desired_direction * self.thrust_force)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
    if state.get_contact_count() > 0:
        self._explode_on_contact(state)
    
    if not self.target or is_zero_approx(self.turning_rate):
        return

    var desired_basis := Basis.looking_at(state.linear_velocity.normalized(), Vector3.UP)
    var desired_rotation := desired_basis.get_rotation_quaternion()
    var current_rotation := state.transform.basis.get_rotation_quaternion()

    var angle_delta := current_rotation.angle_to(desired_rotation)
    var slerp_weight := clampf(self.turning_rate * state.step / angle_delta, 0.0, 1.0)
    state.transform.basis = state.transform.basis.slerp(desired_basis, slerp_weight)

func _explode_on_contact(state: PhysicsDirectBodyState3D) -> void:
    var explosion_instance: AnimatedSprite3D = self.explosion.instantiate()
    self.add_sibling(explosion_instance)
    explosion_instance.global_position = self.global_position
    explosion_instance.global_rotation = self.global_rotation
    explosion_instance.scale = Vector3.ONE * 0.2

    var collider := state.get_contact_collider_object(0)
    var node := collider as Node
    if node:
        CombatObject.damage_combat_object_inside(node, self.damage, self.fired_by)

    self.queue_free()
