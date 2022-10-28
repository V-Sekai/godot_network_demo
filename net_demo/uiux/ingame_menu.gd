extends Control

func assign_peer_color(p_color: Color) -> void:
	$PeerBoxContainer/PeerColorID.color = p_color

func _ready():
	if multiplayer and multiplayer.has_multiplayer_peer():
		$PeerBoxContainer/PeerIDLabel.set_text("Peer ID: %s" % str(multiplayer.get_unique_id()))
	else:
		$PeerBoxContainer/PeerIDLabel.set_text("Peer ID: UNASSIGNED")
