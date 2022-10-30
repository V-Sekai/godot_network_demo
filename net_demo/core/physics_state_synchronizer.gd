extends Node

const quantization_const = preload("quantization.gd")

@export_node_path(RigidBody3D) var rigid_body: NodePath = NodePath("..")
@onready var _rigid_body_node: RigidBody3D = get_node_or_null(rigid_body)

static func encode_physics_state(p_physics_transform: Transform3D) -> PackedByteArray:
	var buf: PackedByteArray = PackedByteArray()
	assert(buf.resize(12) == OK)
		
	buf.encode_half(0, p_physics_transform.origin.x)
	buf.encode_half(2, p_physics_transform.origin.y)
	buf.encode_half(4, p_physics_transform.origin.z)
	buf.encode_s16(6, quantization_const.quantize_euler_angle_to_s16_angle(p_physics_transform.basis.get_euler().x))
	buf.encode_s16(8, quantization_const.quantize_euler_angle_to_s16_angle(p_physics_transform.basis.get_euler().y))
	buf.encode_s16(10, quantization_const.quantize_euler_angle_to_s16_angle(p_physics_transform.basis.get_euler().z))
	
	return buf
	
static func decode_physics_state(p_physics_byte_array: PackedByteArray) -> Transform3D:
	if p_physics_byte_array.size() == 12:
		var new_transform: Transform3D = Transform3D()
		
		new_transform.origin.x = p_physics_byte_array.decode_half(0)
		new_transform.origin.y = p_physics_byte_array.decode_half(2)
		new_transform.origin.z = p_physics_byte_array.decode_half(4)
		
		var rotation_euler: Vector3 = Vector3()
		rotation_euler.x = quantization_const.dequantize_s16_angle_to_euler_angle(p_physics_byte_array.decode_s16(6))
		rotation_euler.y = quantization_const.dequantize_s16_angle_to_euler_angle(p_physics_byte_array.decode_s16(8))
		rotation_euler.z = quantization_const.dequantize_s16_angle_to_euler_angle(p_physics_byte_array.decode_s16(10))
	
		new_transform.basis = Basis.from_euler(rotation_euler, Basis.EULER_ORDER_XYZ)
		
		return new_transform
	return Transform3D()

@export var sync_net_state : PackedByteArray:
	get:
		if _rigid_body_node:
			return encode_physics_state(_rigid_body_node.transform)
			
		return PackedByteArray()
		
	set(value):
		if typeof(value) != TYPE_PACKED_BYTE_ARRAY:
			return
		if value.size() != 12:
			return
		
		if _rigid_body_node:
			if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority() and not _rigid_body_node.pending_ownership_request:
				_rigid_body_node.transform = decode_physics_state(value)
