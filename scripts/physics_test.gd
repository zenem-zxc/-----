extends Node2D

const PhysicsValues = preload("res://scripts/physics_variables.gd")
var _initial_transforms: Dictionary = {}
var _pending_resets: Dictionary = {}


func _ready() -> void:
	_initial_transforms[$Player] = $Player.global_transform
	_initial_transforms[$Crate] = $Crate.global_transform
	# Keep both dynamic bodies on the gravity configured for this test scene.
	var project_gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
	if project_gravity > 0.0:
		$Player.gravity_scale = PhysicsValues.G / project_gravity
		$Crate.gravity_scale = PhysicsValues.G / project_gravity


func _physics_process(_delta: float) -> void:
	for body: RigidBody2D in _initial_transforms:
		if body.global_position.y > PhysicsValues.RESPAWN_Y and not _pending_resets.has(body):
			_pending_resets[body] = true
			_reset_body.call_deferred(body)


func _reset_body(body: RigidBody2D) -> void:
	body.global_transform = _initial_transforms[body]
	body.linear_velocity = Vector2.ZERO
	body.angular_velocity = 0.0
	body.sleeping = false
	_pending_resets.erase(body)
