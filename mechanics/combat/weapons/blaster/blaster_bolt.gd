extends RigidBody3D

## How long before the blaster bolt expires (in milliseconds).
@export var lifetime_msec: int = 2000

## How much damage the blaster bolt does.
@export var damage: Damage

## An explosion to instantiate upon collision.
@export var explosion: PackedScene

var _spawn_time_msec: int

func _ready() -> void:
    self._spawn_time_msec = Time.get_ticks_msec()

func _process(_delta: float) -> void:
    if Time.get_ticks_msec() - self._spawn_time_msec > self.lifetime_msec:
        self.queue_free()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
    if state.get_contact_count() == 0:
        return

    var explosion_instance: AnimatedSprite3D = self.explosion.instantiate()
    self.add_sibling(explosion_instance)
    explosion_instance.global_position = self.global_position
    explosion_instance.global_rotation = self.global_rotation
    explosion_instance.scale = Vector3.ONE * 0.2

    var collider := state.get_contact_collider_object(0)
    var node := collider as Node
    if node:
        CombatObject.damage_combat_object_inside(node, self.damage)

    self.queue_free()
