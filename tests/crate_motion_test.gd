extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var scene: Node = load("res://scenes/physics_test.tscn").instantiate()
	root.add_child(scene)
	var player: RigidBody2D = scene.get_node("Player")
	var crate: RigidBody2D = scene.get_node("Crate")
	player.position = Vector2(470, 440)
	for i in range(120):
		await physics_frame
	var initial_relative_x := player.position.x - crate.position.x
	var previous_velocity := player.linear_velocity.x
	var worst_delta := 0.0
	var reversed_frames := 0
	var inactive_frames := 0
	Input.action_press("ui_right")
	for i in range(20):
		await physics_frame
		if not player.is_accelerating:
			inactive_frames += 1
		worst_delta = maxf(worst_delta, absf(player.linear_velocity.x - previous_velocity))
		previous_velocity = player.linear_velocity.x
		if player.linear_velocity.x < -5.0:
			reversed_frames += 1
	Input.action_release("ui_right")
	var displacement := (player.position.x - crate.position.x) - initial_relative_x
	print("Walking on crate: relative displacement=", displacement, " max speed change/frame=", worst_delta, " backward frames=", reversed_frames)
	if displacement < 5.0 or reversed_frames > 1 or inactive_frames > 2 or worst_delta > 15.0:
		push_error("Movement on crate is jerky or fails to advance")
		quit(1)
		return
	print("PASS: player moves smoothly on crate")
	quit(0)
