extends MultiMeshInstance3D

var _created_rids: Array[RID] = []

const MAX_LINEAR_VELOCITY = 1.5
const MAX_ANGULAR_VELOCITY = 1.5

const SPHERE_SHAPE_RADIUS = 0.4

func _enter_tree() -> void:
    for i in range(self.multimesh.instance_count):
        var mesh_transform := self.multimesh.get_instance_transform(i)
        var linear_velocity := Vector3(randf_range( - MAX_LINEAR_VELOCITY, MAX_LINEAR_VELOCITY), 0.0, randf_range( - MAX_LINEAR_VELOCITY, MAX_LINEAR_VELOCITY))
        var angular_velocity := Vector3(randf_range( - MAX_ANGULAR_VELOCITY, MAX_ANGULAR_VELOCITY), randf_range( - MAX_ANGULAR_VELOCITY, MAX_ANGULAR_VELOCITY), randf_range( - MAX_ANGULAR_VELOCITY, MAX_ANGULAR_VELOCITY))

        var physics_body := PhysicsServer3D.body_create()
        PhysicsServer3D.body_set_mode(physics_body, PhysicsServer3D.BODY_MODE_RIGID)
        PhysicsServer3D.body_set_state(physics_body, PhysicsServer3D.BODY_STATE_TRANSFORM, mesh_transform)
        PhysicsServer3D.body_set_state(physics_body, PhysicsServer3D.BODY_STATE_ANGULAR_VELOCITY, angular_velocity)
        PhysicsServer3D.body_set_state(physics_body, PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, linear_velocity)
        PhysicsServer3D.body_set_space(physics_body, self.get_world_3d().space)
        PhysicsServer3D.body_set_force_integration_callback(physics_body, _body_moved, i)
        PhysicsServer3D.body_set_collision_layer(physics_body, 1)
        PhysicsServer3D.body_set_collision_mask(physics_body, 2)
        PhysicsServer3D.body_set_axis_lock(physics_body, PhysicsServer3D.BODY_AXIS_LINEAR_Y, true)
        self._created_rids.append(physics_body)

        var shape := PhysicsServer3D.sphere_shape_create()
        PhysicsServer3D.shape_set_data(shape, SPHERE_SHAPE_RADIUS)
        PhysicsServer3D.body_add_shape(physics_body, shape, Transform3D.IDENTITY)
        self._created_rids.append(shape)

func _exit_tree() -> void:
    for rid in self._created_rids:
        PhysicsServer3D.free_rid(rid)

    self._created_rids.clear()
    
func _body_moved(state: PhysicsDirectBodyState3D, index: int) -> void:
    var mesh_transform := state.transform

    # Overwrite the physics scale from the multimesh, because it gets lost for some reason otherwise.
    mesh_transform.basis = mesh_transform.basis.scaled(multimesh.get_instance_transform(index).basis.get_scale())

    multimesh.set_instance_transform(index, mesh_transform)
