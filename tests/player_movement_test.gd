extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var scene: Node = load("res://scenes/physics_test.tscn").instantiate()
	root.add_child(scene)
	var player: RigidBody2D = scene.get_node("Player")
	var crate: RigidBody2D = scene.get_node("Crate")
	for i in range(90):
		await physics_frame
	if absf(player.linear_velocity.y) > 5.0 or player.position.y < 500.0:
		_fail("Player did not settle on the floor")
		return
	if not is_equal_approx(player.mass, 70.0) or not is_equal_approx(crate.mass, 30.0):
		_fail("Unexpected body masses")
		return
	Input.action_press("ui_right")
	for i in range(5):
		await physics_frame
	var initial_speed := player.linear_velocity.x
	if initial_speed < 80.0 or not player.is_accelerating or not player.get_node("AccelerationArrow").visible:
		_fail("Fivefold drive force or acceleration indicator failed")
		return
	for i in range(12):
		await physics_frame
	var moving_speed := player.linear_velocity.x
	if initial_speed <= 0.0 or moving_speed <= initial_speed + 10.0:
		_fail("Player did not accelerate gradually")
		return
	Input.action_release("ui_right")
	for i in range(4):
		await physics_frame
	await process_frame
	if not player.is_sliding or not player.get_node("SlidingFeet").visible:
		_fail("Sliding friction or red foot indicator failed")
		return
	if player.linear_velocity.x <= 0.0 or player.linear_velocity.x >= moving_speed:
		_fail("Player did not brake gradually")
		return
	for i in range(45):
		await physics_frame
	if absf(player.linear_velocity.x) > 5.0:
		_fail("Player did not stop after braking")
		return
	var initial_crate_x := crate.position.x
	Input.action_press("ui_right")
	for i in range(100):
		await physics_frame
	Input.action_release("ui_right")
	if crate.position.x <= initial_crate_x + 10.0:
		_fail("Collision did not push the dynamic crate")
		return
	for i in range(45):
		await physics_frame
	var floor_y := player.position.y
	Input.action_press("ui_accept")
	for i in range(3):
		await physics_frame
	if player.linear_velocity.y > -350.0 or player.linear_velocity.y < -480.0:
		_fail("Jump did not use the configured takeoff speed")
		return
	Input.action_release("ui_accept")
	for i in range(8):
		await physics_frame
	if player.position.y >= floor_y - 10.0:
		_fail("Player did not jump")
		return
	print("PASS: mass, fivefold drive, friction, indicators, collision and jump")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
