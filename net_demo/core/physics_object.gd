extends RigidBody3D

const physics_state_sync_const = preload("res://net_demo/core/physics_state_synchronizer.gd")

# Index into the color table for multiplayer
var multiplayer_color_id: int = -1
var pending_ownership_request: bool = false

func update_color_id_and_material() -> void:
	multiplayer_color_id = MultiplayerColorTable.get_multiplayer_material_index_for_peer_id(
		multiplayer.get_unique_id() if pending_ownership_request else get_multiplayer_authority(), false)
	if multiplayer_color_id >= 0:
		var color_material: Material = MultiplayerColorTable.get_material_for_index(multiplayer_color_id)
		assert(color_material)
		$MeshInstance3D.material_override = color_material
	else:
		$MeshInstance3D.material_override = null
			
# Applies quantization locally to gain improved simulation consistency between peers
# (needs work, currently causes objects to jitter; can likely be solved by factoring in
# rest state)
func quantize_simulation_locally() -> void:
	var physics_state: physics_state_sync_const.PhysicsState = physics_state_sync_const.PhysicsState.new()
	physics_state.set_from_rigid_body(self)
	
	physics_state = physics_state_sync_const.PhysicsState.decode_physics_state(
		physics_state_sync_const.PhysicsState.encode_physics_state(physics_state))
	
	transform = Transform3D(Basis(physics_state.rotation), physics_state.origin)
	linear_velocity = physics_state.linear_velocity
	angular_velocity = physics_state.angular_velocity
			
func _physics_process(p_delta: float) -> void:
	if (multiplayer.has_multiplayer_peer() and is_multiplayer_authority()) or pending_ownership_request:
		quantize_simulation_locally()
			
func _on_body_entered(p_body: PhysicsBody3D) -> void:
	if p_body is CharacterBody3D and p_body.is_multiplayer_authority():
		if p_body.get_multiplayer_authority() != get_multiplayer_authority():
			pending_ownership_request = true
			if multiplayer.has_multiplayer_peer():
				update_color_id_and_material()

func _ready() -> void:
	assert(MultiplayerColorTable.color_table_updated.connect(update_color_id_and_material) == OK)
	
	if multiplayer.has_multiplayer_peer():
		update_color_id_and_material()
