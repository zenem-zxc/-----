extends RefCounted
## Units: kg, pixels, seconds. 100 pixels = 1 metre, so forces use kg*px/s².
## Divide a force by PIXELS_PER_METRE to express it in newtons.

const PIXELS_PER_METRE := 100.0
const G := 980.0 # px/s² = 9.8 m/s²; matches project.godot.
const PLAYER_MASS := 70.0 # kg
const V_MAX := 280.0 # px/s
const F_ACCELERATION := PLAYER_MASS * 450.0 * 5.0 # kg*px/s²
const SUPPORT_FORCE_RATIO := 0.5 # gentler traction on movable bodies
const TRACTION_RESPONSE_TIME := 0.12 # s: avoid one-frame force reversals
const MU_STATIC := 2.4
const MU_SLIDING := 1.8
const F_STATIC_FRICTION := MU_STATIC * PLAYER_MASS * G # max on level ground
const F_SLIDING_FRICTION := MU_SLIDING * PLAYER_MASS * G # on level ground
const F_MIN_MOVEMENT := 7000.0 # kg*px/s² (70 N): minimum control force
const F_MIN_SLIDING := 30000.0 # kg*px/s² (300 N): minimum slipping threshold
const STATIC_CORRECTION := 0.25 # gradual correction to avoid contact oscillation
const CONTACT_SPEED_DEADBAND := 0.2 # px/s: ignore solver noise, not normal motion
const JUMP_SPEED := 464.33 # px/s upward (4.64 m/s), independent of gravity
const AIR_CORRECTION_SPEED := 50.0 # px/s: one small horizontal correction per airborne period
const LANDING_FRICTION_TIME := 0.1 # seconds
const LANDING_IMPACT_TIME := 0.1 # seconds over which impact load is approximated
const LANDING_BRAKE_FRACTION := 0.8 # maximum fraction of slip removed per landing window
const WALL_JUMP_HORIZONTAL_SPEED := 220.0 # px/s away from the wall
const WALL_JUMP_VERTICAL_SPEED := 300.0 # px/s upward
const WALL_GRIP_TIME := 0.2 # seconds
const RESPAWN_Y := 1100.0 # px: reset bodies that fall below the test area
