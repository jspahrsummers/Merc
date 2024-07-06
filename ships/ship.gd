extends RigidBody3D

@onready var combat_object: CombatObject = $CombatObject
@onready var targeting_system: TargetingSystem = $TargetingSystem
@onready var rigid_body_thruster: RigidBodyThruster = $RigidBodyThruster
@onready var rigid_body_direction: RigidBodyDirection = $RigidBodyDirection
@onready var rigid_body_turner: RigidBodyTurner = $RigidBodyTurner # optional
@onready var power_management_unit: PowerManagementUnit = $PowerManagementUnit
@onready var radar_object: RadarObject = $RadarObject
@onready var weapon_mounts: Array[WeaponMount] = self.get_children().filter(func(node: Node) -> bool: return node is WeaponMount)
@onready var shield_recharger: ShieldRecharger = $ShieldRecharger # optional
