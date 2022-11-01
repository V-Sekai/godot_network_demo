extends Control

func assign_peer_color(p_color: Color) -> void:
	$PeerBoxContainer/PeerColorID.color = p_color

func _physics_process(_delta) -> void:
	if Input.is_action_pressed("block_physics_send"):
		$InfoContainer/BlockPhysicsUpdatesInfo.set("theme_override_colors/font_color", Color.RED)
	else:
		$InfoContainer/BlockPhysicsUpdatesInfo.set("theme_override_colors/font_color", Color.WHITE)

func _ready():
	if multiplayer and multiplayer.has_multiplayer_peer():
		$PeerBoxContainer/PeerIDLabel.set_text("Peer ID: %s" % str(multiplayer.get_unique_id()))
	else:
		$PeerBoxContainer/PeerIDLabel.set_text("Peer ID: UNASSIGNED")
