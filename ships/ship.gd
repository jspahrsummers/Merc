extends RigidBody3D
class_name Ship

@onready var combat_object: CombatObject = $CombatObject
@onready var targeting_system: TargetingSystem = $CombatObject/TargetingSystem
@onready var rigid_body_thruster: RigidBodyThruster = $RigidBodyThruster
@onready var rigid_body_direction: RigidBodyDirection = $RigidBodyDirection
@onready var rigid_body_turner: RigidBodyTurner = self.get_node_or_null("RigidBodyTurner")
@onready var power_management_unit: PowerManagementUnit = $PowerManagementUnit
@onready var radar_object: RadarObject = $RadarObject
@onready var shield_recharger: ShieldRecharger = self.get_node_or_null("ShieldRecharger")

var weapon_mounts: Array[WeaponMount] = []

func _ready() -> void:
    for child_index in self.get_child_count():
        var weapon_mount := self.get_child(child_index) as WeaponMount
        if not weapon_mount:
            continue
        
        self.weapon_mounts.push_back(weapon_mount)
