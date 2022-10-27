extends Node

# The node which all the player scenes are parented to
var player_parent_scene: Node3D = null

const player_spawner_const = preload("player_spawner.tscn")
var player_spawner: MultiplayerSpawner = null

func load_main_menu_scene() -> void:
	assert(get_tree().change_scene_to_file("res://net_demo/uiux/main_menu.tscn") == OK)

func load_default_scene() -> void:
	assert(get_tree().change_scene_to_file("res://net_demo/scenes/SCENE_game_map.tscn") == OK)

func get_player_spawn_buffer(p_authority: int, p_transform: Transform3D) -> PackedByteArray:
	var buf: PackedByteArray = PackedByteArray()
	var _resize_result: int = buf.resize(13)
	buf.encode_u32(0, p_authority)
	buf.encode_half(4, p_transform.origin.x)
	buf.encode_half(6, p_transform.origin.y)
	buf.encode_half(8, p_transform.origin.z)
	buf.encode_half(10, p_transform.basis.get_euler().y)
	var color_id: int = MultiplayerColorTable.get_multiplayer_material_index_for_peer_id(p_authority)
	assert(color_id != -1)
	buf.encode_u8(12, color_id)
	
	return buf
	
func get_random_spawn_point() -> Transform3D:
	var spawn_points: Array = get_tree().get_nodes_in_group("spawners")
	assert(spawn_points.size() > 0)
	
	var spawn_point_transform: Transform3D = spawn_points[randi_range(0, spawn_points.size()-1)].global_transform

	return spawn_point_transform

func _host_server(p_port: int, p_max_players: int) -> void:
	var peer: MultiplayerPeer = ENetMultiplayerPeer.new()
	if peer.create_server(p_port, p_max_players) == OK:
		multiplayer.multiplayer_peer = peer
	
		var spawn_point_transform: Transform3D = get_random_spawn_point()
		var _new_player: Node = player_spawner.spawn(get_player_spawn_buffer(1, spawn_point_transform))
	else:
		load_main_menu_scene()
	
func _join_server(p_address: String, p_port: int) -> void:
	var peer = ENetMultiplayerPeer.new()
	if peer.create_client(p_address, p_port) == OK:
		multiplayer.set_multiplayer_peer(peer)
	else:
		load_main_menu_scene()
	
func _on_connected_to_server() -> void:
	print("_on_connected_to_server")
	
func _on_connection_failed() -> void:
	print("_on_connection_failed")
	load_main_menu_scene()

func _on_peer_connect(p_id : int) -> void:
	print("_on_peer_connect(%s)" % str(p_id))
	if multiplayer.is_server():
		var spawn_point_transform: Transform3D = get_random_spawn_point()
		var _new_player: Node = player_spawner.spawn(get_player_spawn_buffer(p_id, spawn_point_transform))

func _on_peer_disconnect(p_id : int) -> void:
	print("_on_peer_disconnect(%s)" % str(p_id))
	if multiplayer.is_server():
		MultiplayerColorTable.erase_multiplayer_peer_id(p_id)

func _on_server_disconnected() -> void:
	print("_on_server_disconnected")
	MultiplayerColorTable.clear_multiplayer_color_table()
	load_main_menu_scene()
		
func host_server(p_port: int, p_max_players: int) -> void:
	assert(p_max_players < MultiplayerColorTable.named_color_materials.size())
	
	load_default_scene()
	call_deferred("_host_server", p_port, p_max_players)
	
func join_server(p_address: String, p_port: int) -> void:
	load_default_scene()
	call_deferred("_join_server", p_address, p_port)
	
func get_multiplayer_id() -> int:
	if multiplayer and multiplayer.has_multiplayer_peer():
		return multiplayer.get_unique_id()
		
	return -1
	
func _ready() -> void:
	randomize()
	
	player_spawner = player_spawner_const.instantiate()
	player_spawner.name = "PlayerSpawner"
	add_child(player_spawner)
	
	player_parent_scene = Node3D.new()
	player_parent_scene.name = "Players"
	add_child(player_parent_scene)
	
	player_spawner.spawn_path = player_spawner.get_path_to(player_parent_scene)
	
	assert(multiplayer.connected_to_server.connect(_on_connected_to_server) == OK)
	assert(multiplayer.connection_failed.connect(_on_connection_failed) == OK)
	assert(multiplayer.peer_connected.connect(_on_peer_connect) == OK)
	assert(multiplayer.peer_disconnected.connect(_on_peer_disconnect) == OK)
	assert(multiplayer.server_disconnected.connect(_on_server_disconnected) == OK)
	
	Performance.add_custom_monitor("NetworkID", get_multiplayer_id, [])
