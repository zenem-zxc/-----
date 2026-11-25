extends RigidBody2D

const DRIVE_TORQUE := 1800000.0
const MAX_WHEEL_SPEED := 20.0
const ENTER_DISTANCE := 110.0

@onready var left_wheel: RigidBody2D = $LeftWheel
@onready var right_wheel: RigidBody2D = $RightWheel
@onready var player: RigidBody2D = get_parent().get_node("Player")
var occupied := false
var _player_layer := 0
var _player_mask := 0


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode == KEY_E and event.pressed and not event.echo:
		if occupied:
			exit_vehicle()
		elif player.global_position.distance_to(global_position) <= ENTER_DISTANCE:
			enter_vehicle()


func enter_vehicle() -> void:
	if occupied:
		return
	occupied = true
	_player_layer = player.collision_layer
	_player_mask = player.collision_mask
	player.in_vehicle = true
	player.freeze = true
	player.collision_layer = 0
	player.collision_mask = 0
	player.hide()
	player.global_position = global_position


func exit_vehicle() -> void:
	if not occupied:
		return
	# Check both sides and above before enabling the player's collision again.
	var shape := player.get_node("CollisionShape2D").shape as Shape2D
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = _player_mask
	query.exclude = [player.get_rid()]
	for offset: Vector2 in [Vector2(-100, -20), Vector2(100, -20), Vector2(0, -100)]:
		var destination: Vector2 = global_position + offset
		query.transform = Transform2D(0.0, destination)
		if get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
			occupied = false
			player.global_position = destination
			player.linear_velocity = linear_velocity
			player.collision_layer = _player_layer
			player.collision_mask = _player_mask
			player.freeze = false
			player.in_vehicle = false
			player.show()
			return


func _physics_process(_delta: float) -> void:
	if not occupied:
		return
	player.global_position = global_position
	var direction := Input.get_axis("ui_left", "ui_right")
	if Input.is_physical_key_pressed(KEY_A):
		direction -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		direction += 1.0
	direction = clampf(direction, -1.0, 1.0)
	for wheel in [left_wheel, right_wheel]:
		if direction != 0.0 and wheel.angular_velocity * direction < MAX_WHEEL_SPEED:
			wheel.apply_torque(direction * DRIVE_TORQUE)
