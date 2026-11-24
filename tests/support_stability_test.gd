extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var scene: Node = load("res://scenes/physics_test.tscn").instantiate()
	root.add_child(scene)
	var player: RigidBody2D = scene.get_node("Player")
	var crate: RigidBody2D = scene.get_node("Crate")
	player.position = Vector2(470, 440)
	for i in range(180):
		await physics_frame
	var start := player.global_position
	var min_x := start.x
	var max_x := start.x
	var sliding_frames := 0
	for i in range(180):
		await physics_frame
		min_x = minf(min_x, player.global_position.x)
		max_x = maxf(max_x, player.global_position.x)
		if player.is_sliding:
			sliding_frames += 1
	print("support x span=", max_x - min_x, " player=", player.global_position, " crate=", crate.global_position, " sliding_frames=", sliding_frames)
	if max_x - min_x > 5.0 or absf(player.global_position.y - start.y) > 8.0 or sliding_frames > 3 or player.global_position.y >= crate.global_position.y - 40.0:
		push_error("Player did not remain stable on the crate")
		quit(1)
		return
	var before_push := player.global_position.x
	for i in range(120):
		player.apply_central_force(Vector2(5000.0, 0.0)) # below F_MIN_MOVEMENT
		await physics_frame
	print("weak-force displacement=", player.global_position.x - before_push, " sliding=", player.is_sliding)
	if absf(player.global_position.x - before_push) > 5.0 or player.is_sliding:
		push_error("A small force caused sustained movement or sliding")
		quit(1)
		return
	scene.queue_free()
	await process_frame
	scene = load("res://scenes/physics_test.tscn").instantiate()
	root.add_child(scene)
	player = scene.get_node("Player")
	crate = scene.get_node("Crate")
	player.position = Vector2(405, 500)
	for i in range(90):
		await physics_frame
	Input.action_press("ui_right")
	for i in range(5):
		await physics_frame
	Input.action_press("ui_accept")
	for i in range(3):
		await physics_frame
	Input.action_release("ui_accept")
	Input.action_release("ui_right")
	for i in range(150):
		await physics_frame
	print("after jump player=", player.global_position, " crate=", crate.global_position)
	if absf(player.global_position.x - crate.global_position.x) > 30.0 or player.global_position.y >= crate.global_position.y - 40.0 or player.is_sliding:
		push_error("Player did not land stably after jumping onto the crate")
		quit(1)
		return
	print("PASS: stable on crate, weak force, and jumping onto crate")
	quit(0)
