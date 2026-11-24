extends Node2D
## Displays the resultant force estimated from the body's velocity change.

const FORCE_SCALE := 3000.0
const MIN_FORCE := 8000.0
const MAX_LENGTH := 100.0
const SMOOTHING_TIME := 0.2
const ARROW_COLOR := Color(1.0, 0.48, 0.06)

var _previous_velocity := Vector2.ZERO
var _force := Vector2.ZERO
var _display_force := Vector2.ZERO
var _samples: Array[Vector2] = []
var _has_sample := false
@onready var _body: RigidBody2D = get_parent()


func _physics_process(delta: float) -> void:
	if _has_sample and delta > 0.0:
		_force = (_body.linear_velocity - _previous_velocity) * _body.mass / delta
	_previous_velocity = _body.linear_velocity
	_has_sample = true
	_samples.push_back(_force)
	var sample_count := maxi(1, floori(SMOOTHING_TIME / delta))
	while _samples.size() > sample_count:
		_samples.pop_front()
	_display_force = Vector2.ZERO
	for sample in _samples:
		_display_force += sample
	_display_force /= _samples.size()
	# Keep the arrow aligned to world space even when the body rotates.
	global_rotation = 0.0
	queue_redraw()


func _draw() -> void:
	if _display_force.length() < MIN_FORCE:
		return
	var direction := _display_force.normalized()
	var length := clampf(_display_force.length() / FORCE_SCALE, 12.0, MAX_LENGTH)
	var tip := direction * length
	var side := direction.orthogonal()
	draw_line(Vector2.ZERO, tip, ARROW_COLOR, 3.0, true)
	draw_colored_polygon(PackedVector2Array([tip, tip - direction * 10.0 + side * 5.0, tip - direction * 10.0 - side * 5.0]), ARROW_COLOR)
