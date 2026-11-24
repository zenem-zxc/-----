extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var scene: Node = load("res://scenes/physics_test.tscn").instantiate()
	root.add_child(scene)
	var player: RigidBody2D = scene.get_node("Player")
	var crate: RigidBody2D = scene.get_node("Crate")
	player.position = Vector2(470, 440)
	for i in range(150):
		await physics_frame
	var start_y := player.global_position.y
	Input.action_press("ui_accept")
	await physics_frame
	await physics_frame
	Input.action_release("ui_accept")
	var highest_y := player.global_position.y
	for i in range(35):
		await physics_frame
		highest_y = minf(highest_y, player.global_position.y)
	if start_y - highest_y < 70.0:
		push_error("Player could not jump from a crate resting on the floor")
		quit(1)
		return
	# A stationary jump at the edge should not kick the crate into a spin.
	scene.queue_free()
	await process_frame
	scene = load("res://scenes/physics_test.tscn").instantiate()
	root.add_child(scene)
	player = scene.get_node("Player")
	crate = scene.get_node("Crate")
	player.position = Vector2(490, 440)
	for i in range(150):
		await physics_frame
	var initial_angle := crate.rotation
	Input.action_press("ui_accept")
	await physics_frame
	await physics_frame
	Input.action_release("ui_accept")
	for i in range(20):
		await physics_frame
	if absf(crate.rotation - initial_angle) > 0.15:
		push_error("A stationary edge jump spun the crate")
		quit(1)
		return
	scene.queue_free()
	await process_frame
	scene = load("res://scenes/physics_test.tscn").instantiate()
	root.add_child(scene)
	player = scene.get_node("Player")
	crate = scene.get_node("Crate")
	player.position = Vector2(470, 440)
	for i in range(150):
		await physics_frame
	# Remove the floor so it cannot absorb the takeoff impulse.
	scene.get_node("Ground").position.y += 1000.0
	for i in range(3):
		await physics_frame
	var initial_momentum := player.mass * player.linear_velocity.y + crate.mass * crate.linear_velocity.y
	var initial_horizontal_momentum := player.mass * player.linear_velocity.x + crate.mass * crate.linear_velocity.x
	Input.action_press("ui_accept")
	await physics_frame
	await physics_frame
	Input.action_release("ui_accept")
	var relative_speed := crate.linear_velocity.y - player.linear_velocity.y
	var momentum_change := player.mass * player.linear_velocity.y + crate.mass * crate.linear_velocity.y - initial_momentum
	var horizontal_momentum_change := player.mass * player.linear_velocity.x + crate.mass * crate.linear_velocity.x - initial_horizontal_momentum
	print("Jump recoil: separation speed=", relative_speed, " player velocity=", player.linear_velocity, " crate velocity=", crate.linear_velocity, " angular=", crate.angular_velocity, " momentum change=", momentum_change)
	# Gravity contributes about 3100 kg*px/s over two 60 Hz frames.
	if relative_speed < 400.0 or relative_speed > 510.0 or crate.linear_velocity.y < 0.0 or crate.linear_velocity.y > 450.0 or absf(momentum_change) > 6000.0 or absf(horizontal_momentum_change) > 100.0:
		push_error("Jump did not transfer a balanced impulse to the movable support")
		quit(1)
		return
	print("PASS: jump recoil conserves momentum and limits separation speed")
	quit(0)
