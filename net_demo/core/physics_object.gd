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
