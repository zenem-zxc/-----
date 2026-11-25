extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var scene: Node = load("res://scenes/physics_test.tscn").instantiate()
	root.add_child(scene)
	var car: RigidBody2D = scene.get_node("Car")
	var player: RigidBody2D = scene.get_node("Player")
	for i in range(120):
		await physics_frame
	print("Car=", car.global_position, " wheels=", car.left_wheel.global_position, " ", car.right_wheel.global_position)
	if car.left_wheel.global_position.distance_to(car.global_position) > 80.0 or car.right_wheel.global_position.distance_to(car.global_position) > 80.0:
		_fail("Wheels are not attached to the car")
		return
	player.global_position = car.global_position + Vector2(0, -80)
	var interaction := InputEventKey.new()
	interaction.physical_keycode = KEY_E
	interaction.pressed = true
	car._unhandled_key_input(interaction)
	if not car.occupied or not player.freeze or player.visible:
		_fail("Could not enter car")
		return
	var start_x := car.global_position.x
	Input.action_press("ui_right")
	for i in range(120):
		await physics_frame
	Input.action_release("ui_right")
	print("Car drive displacement=", car.global_position.x - start_x)
	if car.global_position.x - start_x < 20.0:
		_fail("Car did not drive right")
		return
	car._unhandled_key_input(interaction)
	if car.occupied or player.freeze or not player.visible:
		_fail("Could not exit car")
		return
	scene.queue_free()
	await process_frame
	scene = load("res://scenes/physics_test.tscn").instantiate()
	root.add_child(scene)
	car = scene.get_node("Car")
	for i in range(100):
		await physics_frame
	car.enter_vehicle()
	start_x = car.global_position.x
	Input.action_press("ui_left")
	for i in range(180):
		await physics_frame
	Input.action_release("ui_left")
	print("Car leftward displacement=", car.global_position.x - start_x, " position=", car.global_position)
	if car.global_position.x > -300.0 or car.global_position.y > 650.0:
		_fail("Car did not reach the uneven road")
		return
	print("PASS: car wheels, entry, driving and exit")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
