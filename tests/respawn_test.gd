extends SceneTree

const PhysicsValues = preload("res://scripts/physics_variables.gd")


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var scene: Node = load("res://scenes/physics_test.tscn").instantiate()
	root.add_child(scene)
	var player: RigidBody2D = scene.get_node("Player")
	var crate: RigidBody2D = scene.get_node("Crate")
	var player_start := player.global_position
	var crate_start := crate.global_position
	player.global_position = Vector2(1000, PhysicsValues.RESPAWN_Y + 100.0)
	crate.global_position = Vector2(1200, PhysicsValues.RESPAWN_Y + 100.0)
	player.linear_velocity = Vector2(300, 800)
	crate.linear_velocity = Vector2(-200, 700)
	crate.angular_velocity = 10.0
	for i in range(4):
		await physics_frame
	if absf(player.global_position.x - player_start.x) > 1.0 or absf(player.global_position.y - player_start.y) > 5.0:
		_fail("Player did not return to the start")
		return
	if absf(crate.global_position.x - crate_start.x) > 1.0 or absf(crate.global_position.y - crate_start.y) > 5.0:
		_fail("Crate did not return to the start")
		return
	if absf(player.linear_velocity.x) > 1.0 or absf(crate.linear_velocity.x) > 1.0 or absf(crate.angular_velocity) > 0.1:
		_fail("Respawn did not reset body velocities")
		return
	print("PASS: player and crate respawn independently with reset velocities")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
