extends Node

@export_node_path(CharacterBody3D) var player_controller: NodePath = NodePath()
@onready var _player_controller_node: CharacterBody3D = get_node_or_null(player_controller)

var target_origin: Vector3 = Vector3()
var target_y_rotation: float = 0.0

# Networking start
@export var sync_net_state : PackedByteArray:
	get:
		var buf: PackedByteArray = PackedByteArray()
		if buf.resize(8) == OK:
			if _player_controller_node:
				buf.encode_half(0, _player_controller_node.transform.origin.x)
				buf.encode_half(2, _player_controller_node.transform.origin.y)
				buf.encode_half(4, _player_controller_node.transform.origin.z)
				buf.encode_half(6, _player_controller_node.y_rotation)
			
		return buf
		
	set(value):
		if typeof(value) != TYPE_PACKED_BYTE_ARRAY:
			return
		if value.size() != 8:
			return
		
		if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
			target_origin.x = value.decode_half(0)
			target_origin.y = value.decode_half(2)
			target_origin.z = value.decode_half(4)
			target_y_rotation = value.decode_half(6)
			
			if _player_controller_node:
				_sync_values()
			
func _sync_values() -> void:
	_player_controller_node.network_transform_update(target_origin, target_y_rotation)
			
func _ready() -> void:
	if multiplayer.has_multiplayer_peer() and !is_multiplayer_authority() and _player_controller_node:
		_sync_values()
