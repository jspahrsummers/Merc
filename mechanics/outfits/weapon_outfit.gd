extends Outfit
class_name WeaponOutfit

## The damage dealt by this weapon.
@export var damage: float

## The range of this weapon in meters.
@export var range: float

## The rate of fire in shots per second.
@export var fire_rate: float

## The projectile scene to be instantiated when firing.
@export var projectile_scene: PackedScene

## The force with which the projectile is fired.
@export var fire_force: float

func _init() -> void:
    self.type = OutfitType.WEAPON

func apply_to_ship(ship: Ship) -> void:
    for weapon_mount in ship.weapon_mounts:
        if not weapon_mount.weapon_outfit:
            weapon_mount.install_weapon(self)
            break

func remove_from_ship(ship: Ship) -> void:
    for weapon_mount in ship.weapon_mounts:
        if weapon_mount.weapon_outfit == self:
            weapon_mount.uninstall_weapon()
            break

func get_description() -> String:
    return "Damage: %s\nRange: %s m\nFire Rate: %s shots/s" % [damage, range, fire_rate]

## Create and return a projectile instance for this weapon.
func create_projectile() -> RigidBody3D:
    var projectile: RigidBody3D = projectile_scene.instantiate()
    # TODO: Set projectile properties based on weapon characteristics
    return projectile