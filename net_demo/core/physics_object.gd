extends RigidBody3D

const physics_state_sync_const = preload("res://net_demo/core/physics_state_synchronizer.gd")

# Index into the color table for multiplayer
var multiplayer_color_id: int = -1

# This flag is set if the player tries to gain authority over this rigid body. They will
# ignore incoming updates while it is set and instead act like they have control over it.
# (Currently there is no interface for explicitly requesting ownership, so simulation will
# not match.)
var pending_authority_request: bool = false

# Updates the material to match the color of the object
func update_color_id_and_material() -> void:
	multiplayer_color_id = MultiplayerColorTable.get_multiplayer_material_index_for_peer_id(
		multiplayer.get_unique_id() if pending_authority_request else get_multiplayer_authority(), false)
	if multiplayer_color_id >= 0:
		var color_material: Material = MultiplayerColorTable.get_material_for_index(multiplayer_color_id)
		assert(color_material)
		$MeshInstance3D.material_override = color_material
	else:
		$MeshInstance3D.material_override = null
			
# Applies quantization locally to gain improved simulation consistency between peers
# (currently causes objects to jitter; disabling local quantization during
# sleep state helps a bit, but still needs further investigation)
func _quantize_simulation_locally() -> void:
	var physics_state: physics_state_sync_const.PhysicsState = physics_state_sync_const.PhysicsState.new()
	physics_state.set_from_rigid_body(self)
	
	physics_state = physics_state_sync_const.PhysicsState.decode_physics_state(
		physics_state_sync_const.PhysicsState.encode_physics_state(physics_state))
	
	transform = Transform3D(Basis(physics_state.rotation), physics_state.origin)
	linear_velocity = physics_state.linear_velocity
	angular_velocity = physics_state.angular_velocity
	
# Sleeping rigid bodies will show up as partially transparent
func _update_sleep_visualization() -> void:
	if sleeping:
		$MeshInstance3D.transparency = 0.25
	else:
		$MeshInstance3D.transparency = 0.0
			
func _on_body_entered(p_body: PhysicsBody3D) -> void:
	if p_body is CharacterBody3D and p_body.is_multiplayer_authority():
		if p_body.get_multiplayer_authority() != get_multiplayer_authority():
			pending_authority_request = true
			if multiplayer.has_multiplayer_peer():
				update_color_id_and_material()
			
func _physics_process(p_delta: float) -> void:
	_update_sleep_visualization()
	
	if (multiplayer.has_multiplayer_peer() and is_multiplayer_authority()) or pending_authority_request:
		if !sleeping:
			_quantize_simulation_locally()

func _ready() -> void:
	assert(MultiplayerColorTable.color_table_updated.connect(update_color_id_and_material) == OK)
	
	if multiplayer.has_multiplayer_peer():
		update_color_id_and_material()
