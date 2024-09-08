extends RigidBody3D
class_name Projectile

## How long before the projectile expires (in milliseconds).
@export var lifetime_msec: int = 2000

## How much damage the projectile does.
@export var damage: Damage

## An explosion to instantiate upon collision.
@export var explosion: PackedScene

## The maximum turning rate, in rad/s, for a guided projectile. Set to 0 to disable guidance.
@export var turning_rate: float = 0

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

func _physics_process(delta: float) -> void:
    if Time.get_ticks_msec() - self._spawn_time_msec > self.lifetime_msec:
        self.queue_free()
    
    if self.target and not is_zero_approx(self.turning_rate):
        self._guide_toward_target(delta)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
    # var velocity := state.linear_velocity.length()
    # var direction := -state.transform.basis.z
    # state.linear_velocity = direction * velocity

    if state.get_contact_count() > 0:
        self._explode_on_contact(state)

func _guide_toward_target(delta: float) -> void:
    var target_direction := (self.target.global_transform.origin - self.global_transform.origin).normalized()
    var desired_basis := Basis.looking_at(target_direction)
    if self.global_basis.is_equal_approx(desired_basis):
        return

    self.global_basis = self.global_basis.slerp(desired_basis, self.turning_rate * delta)

    var desired_velocity := -self.global_basis.z
    self.linear_velocity = self.linear_velocity.slerp(desired_velocity, self.turning_rate * delta)

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
