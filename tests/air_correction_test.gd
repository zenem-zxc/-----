extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var scene: Node = load("res://scenes/physics_test.tscn").instantiate()
	root.add_child(scene)
	var player: RigidBody2D = scene.get_node("Player")
	for i in range(90):
		await physics_frame
	Input.action_press("ui_accept")
	for i in range(4):
		await physics_frame
	Input.action_release("ui_accept")
	Input.action_press("ui_right")
	for i in range(3):
		await physics_frame
	var first_speed := player.linear_velocity.x
	Input.action_release("ui_right")
	await physics_frame
	Input.action_press("ui_right")
	for i in range(3):
		await physics_frame
	Input.action_release("ui_right")
	if first_speed < 30.0 or first_speed > 40.0 or absf(player.linear_velocity.x - first_speed) > 1.0:
		push_error("Air correction was missing, too strong, or repeated")
		quit(1)
		return
	for i in range(100):
		await physics_frame
	Input.action_press("ui_accept")
	for i in range(4):
		await physics_frame
	Input.action_release("ui_accept")
	Input.action_press("ui_left")
	for i in range(3):
		await physics_frame
	Input.action_release("ui_left")
	if player.linear_velocity.x > -30.0:
		push_error("Air correction did not reset after landing")
		quit(1)
		return
	print("PASS: one small air correction per jump, resets on landing")
	quit(0)
