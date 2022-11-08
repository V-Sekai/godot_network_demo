extends MultiplayerSynchronizer

# Any peer can call this function
@rpc(any_peer, call_local)
func claim_authority() -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if GameManager.is_session_authority(multiplayer.get_unique_id()):
		MultiplayerPhysicsOwnershipTracker.request_authority(self, sender_id)
	
@rpc(any_peer, call_local)
func assign_authority(p_peer_id: int):
	var sender_id: int = multiplayer.get_remote_sender_id()
	if GameManager.is_session_authority(sender_id):
		var physics_body = get_node(root_path)
		physics_body.set_multiplayer_authority(p_peer_id)
		physics_body.pending_authority_request = false
		physics_body.update_color_id_and_material()
