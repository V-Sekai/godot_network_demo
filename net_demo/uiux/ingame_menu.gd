extends Control


func _ready():
	if multiplayer and multiplayer.has_multiplayer_peer():
		$PeerIDLabel.set_text("Peer ID: %s" % str(multiplayer.get_unique_id()))
	else:
		$PeerIDLabel.set_text("Peer ID: -1")
