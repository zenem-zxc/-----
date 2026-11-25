extends RigidBody2D

const PhysicsValues = preload("res://scripts/physics_variables.gd")

var is_sliding := false
var is_accelerating := false
var acceleration_direction := 0.0
var _w_was_pressed := false
var _air_correction_used := false
var _previous_direction := 0.0
var _was_grounded := false
var _previous_vertical_speed := 0.0
var _landing_friction_remaining := 0.0
var _landing_normal_ratio := 1.0
var _wall_grip_remaining := 0.0
var _wall_grip_direction := 0.0
var _last_grip_wall: Object = null
var in_vehicle := false

@onready var _sliding_feet: Polygon2D = $SlidingFeet
@onready var _acceleration_arrow: Polygon2D = $AccelerationArrow


func _process(_delta: float) -> void:
	_sliding_feet.visible = is_sliding
	_acceleration_arrow.visible = is_accelerating
	if is_accelerating:
		_acceleration_arrow.scale.x = acceleration_direction


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if in_vehicle:
		return
	var grounded := false
	var support: RigidBody2D = null
	var support_point := Vector2.ZERO
	var support_velocity := Vector2.ZERO
	var support_contacts := 0
	var support_collider: Object = null
	var wall_direction := 0.0
	var wall_collider: Object = null
	for contact in range(state.get_contact_count()):
		var normal := state.get_contact_local_normal(contact)
		if absf(normal.x) > 0.7 and state.get_contact_collider_object(contact) is StaticBody2D:
			wall_direction = signf(normal.x)
			wall_collider = state.get_contact_collider_object(contact)
		if state.get_contact_local_normal(contact).y < -0.7:
			var collider := state.get_contact_collider_object(contact)
			if not grounded:
				grounded = true
				support = collider as RigidBody2D
				# Track the actual collider even when it is a static body.
				support_collider = collider
			if collider == support_collider:
				support_point += state.get_contact_collider_position(contact)
				support_velocity += state.get_contact_collider_velocity_at_position(contact)
				support_contacts += 1
	if support_contacts > 0:
		support_point /= support_contacts
		support_velocity /= support_contacts
	if grounded:
		_wall_grip_remaining = 0.0
		_last_grip_wall = null
	elif wall_direction != 0.0 and wall_collider != _last_grip_wall:
		_wall_grip_direction = wall_direction
		_wall_grip_remaining = PhysicsValues.WALL_GRIP_TIME
		_last_grip_wall = wall_collider
	if not grounded and _wall_grip_remaining > 0.0:
		wall_direction = _wall_grip_direction
		# Hold position against the wall briefly; gravity resumes on release.
		state.linear_velocity = Vector2.ZERO
		_wall_grip_remaining = maxf(0.0, _wall_grip_remaining - state.step)
	if grounded and not _was_grounded:
		var impact_speed := maxf(0.0, _previous_vertical_speed - support_velocity.y)
		_landing_normal_ratio = 1.0 + impact_speed / (PhysicsValues.G * PhysicsValues.LANDING_IMPACT_TIME)
		_landing_friction_remaining = PhysicsValues.LANDING_FRICTION_TIME
	elif not grounded:
		_landing_friction_remaining = 0.0
	_was_grounded = grounded
	_previous_vertical_speed = state.linear_velocity.y

	var direction := Input.get_axis("ui_left", "ui_right")
	if Input.is_physical_key_pressed(KEY_A):
		direction -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		direction += 1.0
	direction = clampf(direction, -1.0, 1.0)
	var w_pressed := Input.is_physical_key_pressed(KEY_W)
	var jump_pressed := Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up") or (w_pressed and not _w_was_pressed)
	var wall_jump := not grounded and wall_direction != 0.0 and direction == wall_direction and jump_pressed
	if grounded:
		_air_correction_used = false
	elif not wall_jump and _wall_grip_remaining <= 0.0 and not _air_correction_used and direction != 0.0 and direction != _previous_direction:
		# A correction may slow opposite motion, but cannot reverse it.
		var correction := direction * PhysicsValues.AIR_CORRECTION_SPEED
		if state.linear_velocity.x * direction < 0.0:
			correction = direction * minf(absf(state.linear_velocity.x), PhysicsValues.AIR_CORRECTION_SPEED)
		state.apply_central_impulse(Vector2(mass * correction, 0.0))
		_air_correction_used = true
	_previous_direction = direction

	var relative_speed := state.linear_velocity.x - support_velocity.x
	var drive_force := Vector2.ZERO
	is_sliding = false
	is_accelerating = false
	if grounded:
		# Flat-ground approximation: normal force N = m*g, friction <= mu*N.
		var normal_force := mass * state.total_gravity.length() * gravity_scale
		var reference_normal := PhysicsValues.PLAYER_MASS * PhysicsValues.G
		var normal_ratio := normal_force / reference_normal if reference_normal > 0.0 else 0.0
		if _landing_friction_remaining > 0.0:
			normal_ratio *= _landing_normal_ratio
		var static_limit := PhysicsValues.F_STATIC_FRICTION * normal_ratio
		var sliding_force := PhysicsValues.F_SLIDING_FRICTION * normal_ratio
		# On a movable support the same impulse accelerates both bodies. Using
		# the reduced mass prevents overcorrecting their relative velocity.
		var effective_mass := mass
		if support != null and not support.freeze:
			effective_mass = mass * support.mass / (mass + support.mass)
		var stop_force := -relative_speed * effective_mass / state.step
		var force_limit := PhysicsValues.F_ACCELERATION
		if support != null and not support.freeze:
			force_limit *= PhysicsValues.SUPPORT_FORCE_RATIO
		var requested_force := clampf(mass * (direction * PhysicsValues.V_MAX - relative_speed) / PhysicsValues.TRACTION_RESPONSE_TIME, -force_limit, force_limit)
		if direction == 0.0:
			# Deadband rejects solver noise; small slip is corrected gently with
			# static friction, large slip uses kinetic friction without overshoot.
			var slipping_threshold := maxf(static_limit, PhysicsValues.F_MIN_SLIDING)
			if absf(stop_force) > slipping_threshold:
				is_sliding = true
				drive_force.x = signf(stop_force) * minf(sliding_force, absf(stop_force))
			elif absf(relative_speed) > PhysicsValues.CONTACT_SPEED_DEADBAND:
				drive_force.x = clampf(stop_force * PhysicsValues.STATIC_CORRECTION, -static_limit, static_limit)
		elif absf(requested_force) < PhysicsValues.F_MIN_MOVEMENT:
			drive_force.x = 0.0
		elif absf(requested_force) > maxf(static_limit, PhysicsValues.F_MIN_SLIDING):
			is_sliding = true
			drive_force.x = signf(requested_force) * minf(sliding_force, absf(requested_force))
		else:
			drive_force.x = requested_force
		if _landing_friction_remaining > 0.0:
			if direction == 0.0:
				var landing_limit := absf(relative_speed) * effective_mass * PhysicsValues.LANDING_BRAKE_FRACTION / PhysicsValues.LANDING_FRICTION_TIME
				drive_force.x = clampf(drive_force.x, -landing_limit, landing_limit)
			_landing_friction_remaining = maxf(0.0, _landing_friction_remaining - state.step)
		is_accelerating = direction != 0.0 and drive_force.x * direction > 0.0
		acceleration_direction = direction
		state.apply_central_force(drive_force)
		if support != null:
			support.apply_force(-drive_force, support_point - support.global_position)

	if grounded and jump_pressed:
		# JUMP_SPEED is the change in separation speed, not the player's
		# absolute speed: a light support must share the takeoff impulse.
		var inverse_effective_mass := 1.0 / mass
		if support != null and not support.freeze:
			var support_state := PhysicsServer2D.body_get_direct_state(support.get_rid())
			if support_state != null:
				var support_grounded := false
				for contact in range(support_state.get_contact_count()):
					if support_state.get_contact_local_normal(contact).y < -0.7 and support_state.get_contact_collider_object(contact) is StaticBody2D:
						support_grounded = true
						break
				if not support_grounded:
					inverse_effective_mass += support_state.inverse_mass
		var jump_impulse := Vector2(0.0, -PhysicsValues.JUMP_SPEED / inverse_effective_mass)
		state.apply_central_impulse(jump_impulse)
		if support != null:
			# Takeoff pushes through the support's centre, so a stationary edge
			# jump does not introduce a spurious spin from a single contact point.
			support.apply_central_impulse(-jump_impulse)
	elif wall_jump:
		_wall_grip_remaining = 0.0
		var target_x := wall_direction * maxf(state.linear_velocity.x * wall_direction, PhysicsValues.WALL_JUMP_HORIZONTAL_SPEED)
		var target_y := -PhysicsValues.WALL_JUMP_VERTICAL_SPEED
		state.apply_central_impulse(mass * Vector2(target_x - state.linear_velocity.x, minf(target_y - state.linear_velocity.y, 0.0)))
		_air_correction_used = true
	_w_was_pressed = w_pressed
