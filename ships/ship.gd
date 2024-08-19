extends RigidBody3D
class_name Ship

# NODES

## The NPC hero piloting the ship, if any.
@export var hero: Hero

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

## An optional [RigidBodyCargo] for affecting this ship's physics based on its [member cargo_hold].
@export var rigid_body_cargo: RigidBodyCargo

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

## Used to save and restore the player's ship to the same node path across launches.
var save_node_path_override: NodePath

func _ready() -> void:
    self.combat_object.hull = self.hull
    self.combat_object.shield = self.shield
    if self.hero:
        self.combat_object.combat_name = self.hero.name

    self.rigid_body_thruster.battery = self.battery
    self.rigid_body_direction.battery = self.battery
    self.power_management_unit.battery = self.battery

    if self.shield_recharger:
        self.shield_recharger.shield = self.shield
        self.shield_recharger.battery = self.battery
    
    if self.hyperdrive_system:
        self.hyperdrive_system.hyperdrive = self.hyperdrive
    
    for weapon_mount in self.weapon_mounts:
        weapon_mount.battery = self.battery
    
    if self.rigid_body_cargo:
        self.rigid_body_cargo.cargo_hold = self.cargo_hold

func _to_string() -> String:
    return "Ship:%s (%s)" % [self.name, self.combat_object]

## See [SaveGame].
func save_to_dict() -> Dictionary:
    var result := {}
    SaveGame.save_resource_property_into_dict(self, result, "hull")
    SaveGame.save_resource_property_into_dict(self, result, "battery")
    SaveGame.save_resource_property_into_dict(self, result, "shield")
    SaveGame.save_resource_property_into_dict(self, result, "hyperdrive")
    SaveGame.save_resource_property_into_dict(self, result, "cargo_hold")

    result["transform"] = SaveGame.serialize_transform(self.transform)
    result["linear_velocity"] = SaveGame.serialize_vector3(self.linear_velocity)
    result["angular_velocity"] = SaveGame.serialize_vector3(self.angular_velocity)
    return result

## See [SaveGame].
func load_from_dict(dict: Dictionary) -> void:
    SaveGame.load_resource_property_from_dict(self, dict, "hull")
    SaveGame.load_resource_property_from_dict(self, dict, "battery")
    SaveGame.load_resource_property_from_dict(self, dict, "shield")
    SaveGame.load_resource_property_from_dict(self, dict, "hyperdrive")
    SaveGame.load_resource_property_from_dict(self, dict, "cargo_hold")

    self.transform = SaveGame.deserialize_transform(dict["transform"])
    self.linear_velocity = SaveGame.deserialize_vector3(dict["linear_velocity"])
    self.angular_velocity = SaveGame.deserialize_vector3(dict["angular_velocity"])
