extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var scene: Node = load("res://scenes/physics_test.tscn").instantiate()
	root.add_child(scene)
	var player: RigidBody2D = scene.get_node("Player")
	player.position = Vector2(200, 400)
	player.linear_velocity = Vector2(200, 300)
	var frames := 0
	while not player._was_grounded and frames < 90:
		await physics_frame
		frames += 1
	if frames >= 90:
		push_error("Player did not land")
		quit(1)
		return
	var speed_at_landing: float = player.linear_velocity.x
	var impact_ratio: float = player._landing_normal_ratio
	for i in range(3):
		await physics_frame
	var sliding_speed: float = player.linear_velocity.x
	if speed_at_landing < 150.0 or sliding_speed < 40.0 or sliding_speed >= speed_at_landing or impact_ratio <= 1.0:
		push_error("Landing should increase friction while retaining horizontal slide: %s -> %s, ratio %s" % [speed_at_landing, sliding_speed, impact_ratio])
		quit(1)
		return
	for i in range(8):
		await physics_frame
	if player._landing_friction_remaining > 0.0:
		push_error("Landing friction did not expire")
		quit(1)
		return
	print("PASS: landing friction increases with impact and preserves sliding")
	quit(0)
