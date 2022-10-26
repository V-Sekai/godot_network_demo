extends Node3D

var color_material: Material = null

func assign_multiplayer_material_id(p_id: int) -> void:
	if p_id >= 0:
		color_material = MultiplayerColorTable.get_material_for_index(p_id)
		assert(color_material)
		
		$ThirdPersonModel/Base.material_override = color_material
		$ThirdPersonModel/Pointer.material_override = color_material
