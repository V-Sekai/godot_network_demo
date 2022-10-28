extends Node

var named_color_materials: Array = [] # Fixed size array of valid materials
var multiplayer_color_table: Dictionary = {}

# Loads all the default Godot named colors
func load_named_colors() -> void:
	named_color_materials = []
	for i in range(0, Color.get_named_color_count()):
		var new_color: Color = Color.get_named_color(i)
		var new_material: StandardMaterial3D = StandardMaterial3D.new()
		new_material.albedo_color = new_color
		named_color_materials.push_back(new_material)

# Returns the material for an index id
func get_material_for_index(p_index: int) -> Material:
	assert(p_index >= 0)
	assert(p_index < named_color_materials.size())
	
	return named_color_materials[p_index]

# Clears the entire multiplayer color table
func clear_multiplayer_color_table() -> void:
	multiplayer_color_table.clear()

# Removes a peer id from the color table
func erase_multiplayer_peer_id(p_peer_id: int) -> void:
	var _erase_result: bool = multiplayer_color_table.erase(p_peer_id)

# Get the material index for a specific peer id. If one does not yet
# exist, a new one is added at random
func get_multiplayer_material_index_for_peer_id(p_peer_id: int) -> int:
	var material: Material = multiplayer_color_table.get(p_peer_id)
	if material:
		return named_color_materials.find(named_color_materials)
	else:
		var valid_named_color_material: Array = named_color_materials
		for val in multiplayer_color_table.values():
			valid_named_color_material.erase(val)
			
		if valid_named_color_material.size() > 0:
			return randi_range(0, valid_named_color_material.size()-1)
		else:
			return -1
			
func _ready() -> void:
	load_named_colors()
