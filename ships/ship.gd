extends RigidBody3D
class_name Ship

# NODES

## The [CombatObject] representing this ship.
@export var combat_object: CombatObject

## The ship's targeting system.
@export var targeting_system: TargetingSystem

## A [RigidBodyThruster] for moving this ship.
@export var rigid_body_thruster: RigidBodyThruster

## A [RigidBodyDirection] for pointing this ship.
@export var rigid_body_direction: RigidBodyDirection

## This ship's power management unit.
@export var power_management_unit: PowerManagementUnit

## An object for representing this ship on radar.
@export var radar_object: RadarObject

## An optional shield recharger for this ship.
@export var shield_recharger: ShieldRecharger

## An optional hyperdrive system for this ship.
##
## This isn't necessary, for example, for AI ships that will never leave the system they're in.
@export var hyperdrive_system: HyperdriveSystem

## Any weapons mounted on this ship.
@export var weapon_mounts: Array[WeaponMount]

# SAVEABLE RESOURCES

## The hull of the ship.
##
## Connect to [signal Hull.hull_destroyed] to be notified when the ship is destroyed.
@export var hull: Hull

## An optional shield protecting the ship.
@export var shield: Shield

## The [Battery] powering the ship.
@export var battery: Battery

## An optional cargo hold for this ship.
@export var cargo_hold: CargoHold

## An optional hyperdrive for this ship.
@export var hyperdrive: Hyperdrive

func _to_string() -> String:
    return "Ship:%s (%s)" % [self.name, self.combat_object]

## See [SaveGame].
func save_to_dict() -> Dictionary:
    return {}

## See [SaveGame].
func load_from_dict(dict: Dictionary) -> void:
    pass
