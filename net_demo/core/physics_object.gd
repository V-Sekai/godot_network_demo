extends RigidBody3D

# Index into the color table for multiplayer
var multiplayer_color_id: int = -1

func update_color_id_and_material() -> void:
	multiplayer_color_id = MultiplayerColorTable.get_multiplayer_material_index_for_peer_id(get_multiplayer_authority(), false)
	if multiplayer_color_id >= 0:
		var color_material: Material = MultiplayerColorTable.get_material_for_index(multiplayer_color_id)
		assert(color_material)
		$MeshInstance3D.material_override = color_material
	else:
		$MeshInstance3D.material_override = null
			
func _ready() -> void:
	MultiplayerColorTable.color_table_updated.connect(update_color_id_and_material)
	
	if multiplayer.has_multiplayer_peer():
		update_color_id_and_material()
