extends "movement_controller.gd"

const godot_math_extensions_const = preload("res://addons/math_util/math_funcs.gd")

const camera_holder_const = preload("camera_holder.gd")
@export_node_path var camera_holder: NodePath = NodePath()
@export var use_controls: bool = false

const MINIMUM_WALK_VELOCITY = 0.1
const MINIMUM_SPRINT_VELOCITY = 3.0

const WALK_SPEED: float = 1.5
const SPRINT_SPEED: float = 4.5

const ACCELERATION = 16.0
const DEACCELERATION = 16.0

# Index into the color table for multiplayer
var multiplayer_color_id: int = -1

func _update_bobbing(p_velocity_length: float) -> void:
	var camera_holder_node: Node3D = get_node_or_null(camera_holder)
	if camera_holder_node:
		camera_holder_node.update_bobbing(p_velocity_length, MINIMUM_SPRINT_VELOCITY)

func _process_rotation(p_movement_vector: Vector2) -> void:
	var camera_holder_node: Node3D = get_node_or_null(camera_holder)
	if !camera_holder_node:
			return
	
	var direction_vector: Vector2 = Vector2()
	if camera_holder_node.view_mode == camera_holder_const.FIRST_PERSON:
		direction_vector = Vector2(0.0, 1.0)
	else:
		direction_vector = p_movement_vector
	
	var direction_distance: float = direction_vector.normalized().length()
	
	if direction_distance > 0.0:
		var camera_pivot_node: Node3D = camera_holder_node.get_node_or_null(
			camera_holder_node.camera_pivot)
		if !camera_pivot_node:
			return
			
		var camera_basis: Basis = camera_pivot_node.global_transform.basis
		
		var direction: Vector3 = \
		(camera_basis[0] * direction_vector.x) - \
		(camera_basis[2] * direction_vector.y).normalized()
		
		var rotation_difference = godot_math_extensions_const.shortest_angle_distance(
			y_rotation,
			Vector2(direction.z, direction.x).angle()
		)
		
		var clamped_rotation_difference: float = 0.0
		clamped_rotation_difference = rotation_difference

		y_rotation += clamped_rotation_difference

func _process_movement(p_delta: float, p_movement_vector: Vector2, p_is_sprinting: bool) -> void:
	var applied_gravity: float = -gravity if !is_on_floor() else 0.0
	
	var applied_gravity_vector: Vector3 = Vector3(
		applied_gravity,
		applied_gravity,
		applied_gravity
	) * up_direction
	
	var speed_modifier: float = SPRINT_SPEED if p_is_sprinting else WALK_SPEED
	var movement_length: float = p_movement_vector.normalized().length()
	
	var is_moving: bool = movement_length > 0.0
	
	var camera_holder_node: Node3D = get_node_or_null(camera_holder)
	if !camera_holder_node:
			return
			
	var camera_pivot_node: Node3D = camera_holder_node.get_node(camera_holder_node.camera_pivot)
	
	var target_velocity: Vector3
	if camera_holder_node.view_mode == camera_holder_const.FIRST_PERSON:
		target_velocity = ((camera_pivot_node.global_transform.basis.x * p_movement_vector.x)
		+ (camera_pivot_node.global_transform.basis.z * -p_movement_vector.y)) * speed_modifier
	else:
		target_velocity = Basis().rotated(Vector3.UP, y_rotation).z * \
		p_movement_vector.normalized().length() * \
		speed_modifier
	
	var acceleration = DEACCELERATION
	if(is_moving):
		acceleration = ACCELERATION
		
	var horizontal_velocity: Vector3 = (
		velocity * (Vector3.ONE - up_direction)
	)
	
	horizontal_velocity = horizontal_velocity.cubic_interpolate_in_time(target_velocity, target_velocity, horizontal_velocity, acceleration * p_delta,
	p_delta, 0, p_delta)
	
	velocity = (
		applied_gravity_vector + \
		(horizontal_velocity * (Vector3.ONE - up_direction))
	)
	
	kinematic_movement(p_delta)
			
		
func network_transform_update(p_origin: Vector3, p_y_rotation: float) -> void:
	transform.origin = p_origin
	y_rotation = p_y_rotation
		
func _physics_process(p_delta: float) -> void:
	if !multiplayer.has_multiplayer_peer() or is_multiplayer_authority():
		# Get the movement vector
		var movement_vector: Vector2 = Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_forwards") - Input.get_action_strength("move_backwards")
		) if use_controls else Vector2()
		
		# Calculate the player's rotation
		_process_rotation(movement_vector)
		
		# Calculate the player's movement
		_process_movement(p_delta, movement_vector, InputMap.has_action("sprint") and Input.is_action_pressed("sprint"))
		
		# Update the first-person camera bobbing
		_update_bobbing((velocity * (Vector3.ONE - up_direction)).length())
		
	$CharacterModelHolder.transform.basis = Basis().rotated(Vector3.UP, y_rotation)
	
func _ready() -> void:
	super._ready()
	
	collision_layer = 0
	if multiplayer.has_multiplayer_peer() and !is_multiplayer_authority():
		set_collision_layer_value(2, false)
		set_collision_layer_value(3, true)
		# Remove game menu for non-authoritive players
		$IngameMenu.queue_free()
		$IngameMenu.get_parent().remove_child($IngameMenu)
	else:
		set_collision_layer_value(2, true)
		set_collision_layer_value(3, false)
			
	$CharacterModelHolder.assign_multiplayer_material_id(multiplayer_color_id)
	
	$CharacterModelHolder.transform.basis = Basis().rotated(Vector3.UP, y_rotation)
