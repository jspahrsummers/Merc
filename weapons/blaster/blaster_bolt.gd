extends RigidBody3D

## How long before the blaster bolt expires (in milliseconds).
@export var lifetime_msec: int = 2000

## How much damage the blaster bolt does to shields.
##
## If a ship has shields, damage is applied to the shields first, then the hull, in proportion.
@export var damage_shield: float = 80

## How much damage the blaster bolt does to a hull.
##
## If a ship has shields, damage is applied to the shields first, then the hull, in proportion.
@export var damage_hull: float = 40

## An explosion to instantiate upon collision.
@export var explosion: PackedScene

var _spawn_time_msec: int

func _ready() -> void:
    self._spawn_time_msec = Time.get_ticks_msec()

func _process(_delta: float) -> void:
    if Time.get_ticks_msec() - self._spawn_time_msec > self.lifetime_msec:
        self.queue_free()

func _on_body_entered(body: Node) -> void:
    var explosion_instance: AnimatedSprite3D = self.explosion.instantiate()
    get_parent().add_child(explosion_instance)
    explosion_instance.global_position = self.global_position
    explosion_instance.global_rotation = self.global_rotation
    explosion_instance.scale = Vector3.ONE * 0.2

    if body is Ship:
        var ship: Ship = body
        ship.damage({
            "shield": self.damage_shield,
            "hull": self.damage_hull
        })

    self.queue_free()
