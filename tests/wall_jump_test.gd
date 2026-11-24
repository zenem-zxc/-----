extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	for side in [-1, 1]:
		var scene: Node = load("res://scenes/physics_test.tscn").instantiate()
		root.add_child(scene)
		var player: RigidBody2D = scene.get_node("Player")
		player.position = Vector2(950 + side * 38, 350)
		player.linear_velocity.x = -side * 80.0
		for i in range(3):
			await physics_frame
		var grip_start := player.position
		for i in range(7):
			await physics_frame
		if player.position.distance_to(grip_start) > 5.0:
			push_error("Player did not stay at the wall during the grip")
			quit(1)
			return
		var action := "ui_left" if side < 0 else "ui_right"
		Input.action_press(action)
		Input.action_press("ui_accept")
		for i in range(3):
			await physics_frame
		Input.action_release(action)
		Input.action_release("ui_accept")
		if player.linear_velocity.x * side < 150.0 or player.linear_velocity.y > -200.0:
			push_error("Wall jump failed on side %s: %s" % [side, player.linear_velocity])
			quit(1)
			return
		scene.queue_free()
		await process_frame
	print("PASS: wall jump pushes away and upward on both sides")
	quit(0)
