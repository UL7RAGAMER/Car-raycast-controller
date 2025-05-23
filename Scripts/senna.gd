extends VehicleBody3D

@export var MAXSTEER = 0.9
@export var MINSTEER = 0.2  # Steering clamp at high speed
@export var STEER_SPEED_SENSITIVITY = 150.0  # How fast steering reduces (higher = slower reduction)
@export var ENGINEPOWER = 300
@export var BRAKEPOWER = ENGINEPOWER * 1.3  # <-- Stronger than enginepower
@export var RearRightWheel : VehicleWheel3D
@export var RearLeftWheel : VehicleWheel3D
var wheel_radius = 0.383
var gear_ratios = [3.83, 2.83, 2.20, 1.69, 1.04, 0.93, 0.85] 
var current_gear = 0
var current_gear_ratio = gear_ratios[current_gear]
@export var DRIFT_THRESHOLD = 10.0  # How sensitive drifting is
@export var BASE_FRICTION = 11     # Normal tire friction when not drifting
@export var DRIFT_FRICTION = 2  
var CURRENT_FRICTION  = BASE_FRICTION# Lower friction when drifting
@export var fmod_event_emitter_3d: FmodEventEmitter3D
var over8000 = false

func _physics_process(delta: float) -> void:
	var speed = (linear_velocity.x**2 + linear_velocity.z**2)**0.5
	steering = move_toward(steering, Input.get_axis("Right", "Left") * MAXSTEER, delta * 8)
	var wheel_rpm = (speed / (wheel_radius * 2 * PI)) * 60
	var engine_rpm = wheel_rpm * current_gear_ratio
	fmod_event_emitter_3d.set_parameter_by_id(2520763146034599108, round(engine_rpm))
	print(over8000)
	if engine_rpm > 8000:
		over8000 = true
	
	# Send RPM to FMOD
	



	# Braking logic
	var braking = Input.is_action_pressed("brake")
	if braking:
		# Apply strong brake to rear wheels
		RearLeftWheel.brake = BRAKEPOWER * 2.0  # Make it strong
		RearRightWheel.brake = BRAKEPOWER * 2.0
		
		# Lower the rear wheel friction to make it slip
		RearLeftWheel.wheel_friction_slip = DRIFT_FRICTION
		RearRightWheel.wheel_friction_slip = DRIFT_FRICTION
	else:
		# Reset brake
		RearLeftWheel.brake = 0
		RearRightWheel.brake = 0
		
		# Restore normal friction depending if drifting or not
		RearLeftWheel.wheel_friction_slip = CURRENT_FRICTION
		RearRightWheel.wheel_friction_slip = CURRENT_FRICTION



	var throttle = Input.get_axis("Down", "Up")
	var drift_factor = abs(steering) * speed
	var is_drifting = false
	engine_force = throttle * ENGINEPOWER * current_gear_ratio
	var w = 1
	var l = 1
	var h = 0.185
	
	inertia.z = 1/12*mass*(w**2+l**2)
	inertia.x = 1/12*mass*(h**2+l**2)
	inertia.y = 1/12*mass*(w**2+h**2)
	print(inertia)
	# Normal drifting by sharp steering
	if drift_factor > DRIFT_THRESHOLD:
		is_drifting = true

	# Forced drift when braking and turning at high speed
	if braking and abs(steering) > 0.1 and speed > 80.0:  # adjust 20.0 depending on your game
		is_drifting = true
	if is_drifting:
		CURRENT_FRICTION = DRIFT_FRICTION
		
	else:
		CURRENT_FRICTION = BASE_FRICTION
	RearLeftWheel.wheel_friction_slip = lerp(float(RearLeftWheel.wheel_friction_slip), float(CURRENT_FRICTION), delta * 5.0)
	RearRightWheel.wheel_friction_slip = lerp(float(RearRightWheel.wheel_friction_slip), float(CURRENT_FRICTION), delta * 5.0)







	
	print(speed, '|',  round(engine_rpm), '| Gear:', current_gear + 1,"|", CURRENT_FRICTION,"|",engine_force)
var test = 0
