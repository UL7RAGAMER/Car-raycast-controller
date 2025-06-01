class_name CarController3D
extends RigidBody3D
@export var can_drift : bool
@export var horsepower := 1000
@export var WheelFL: RayCast3D
@export var WheelFR: RayCast3D 
@export var WheelRR: RayCast3D 
@export var WheelRL: RayCast3D
@export var fmod_event_emitter_3d : FmodEventEmitter3D
@export_category("Wheel Grip")
@export var base_grip = 1.0
@export var front_grip_bias = 0.8  # < 1.0 = more understeer
@export var rear_grip_bias = 1.2   # > 1.0 = more oversteer
@export_category("Wheel Stats")
@export var rest_distance:float= 1
@export var spring_constant :int = 1200
@export var spring_damping: int = 100
@export var wheel_radius : float= 0.5
@export var debug_wheels : bool
@export_category("Ackerman Steering")
@export var wheel_base :float = 2.6
@export var turn_radius : float = 5.2 
@export var rear_track : float = 1.2
@export var wheel_raduis : float= 0.5
@export_category("Curves")
@export var fric_curve : Curve
@export var drift_curve : Curve
@export var steer_curve : Curve


@onready var label: Label = $"../CanvasLayer/Label"
var max_turn = 1
var ackerman_left : float= 0
var ackerman_right : float = 0
var drag_force = Vector3.ZERO
var wheels: Array[Wheels]
var steer_input
var throttle_input
var previous_velocity: Vector3 = Vector3.ZERO
var fric_multiplier : float = 1
var steer_multiplier : float = 1
@onready var marker_3d: Marker3D = $Marker3D
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D
func _ready() -> void:
	audio_stream_player_3d.volume_db = -100.0
	audio_stream_player_3d.play()
	wheels.append(WheelFL)
	wheels.append(WheelFR)
	wheels.append(WheelRL)
	wheels.append(WheelRR)
func _physics_process(delta: float) -> void:
	accel_curve_apply()
	
	
	label.text =  str(linear_velocity.dot(-global_basis.z))
	steer_input = Input.get_action_strength("Left") - Input.get_action_strength("Right")
	throttle_input = Input.get_action_strength("Up") - Input.get_action_strength("Down")
	
	if steer_input < 0:
		ackerman_left = rad_to_deg(atan(wheel_base/(turn_radius + (rear_track / 2)))* steer_input)
		ackerman_right = rad_to_deg(atan(wheel_base/(turn_radius -(rear_track / 2)))* steer_input)	
	elif steer_input > 0:
		ackerman_left = rad_to_deg(atan(wheel_base/(turn_radius - (rear_track / 2)))* steer_input)
		ackerman_right = rad_to_deg(atan(wheel_base/(turn_radius +(rear_track / 2)))* steer_input)
	else:
		ackerman_left = 0 
		ackerman_right = 0
	WheelFR.rotation_degrees.y = lerp(WheelFR.rotation_degrees.y,ackerman_right,0.1)
	WheelFL.rotation_degrees.y = lerp(WheelFL.rotation_degrees.y,ackerman_left,0.1)
	if is_drifting(0.1) :
		can_drift = true
		front_grip_bias = 2
	else:
		if is_drifting(0.1) !=-1:
			can_drift = false
			front_grip_bias = 1.3
	if is_drifting(0.1) == -1 and audio_stream_player_3d.volume_db == -100.0:
		audio_stream_player_3d.volume_db = -100.0
		audio_stream_player_3d.volume_db = lerp(audio_stream_player_3d.volume_db,1.0,1)
		audio_stream_player_3d.pitch_scale = randf_range(0.8,1.2)
		for i in wheels:
			i.gpu_particles_3d.emitting = true
	elif not is_drifting(0.1) == -1 :
		audio_stream_player_3d.volume_db = lerp(audio_stream_player_3d.volume_db,-100.0,1)
		for i in wheels:
			i.gpu_particles_3d.emitting = false
	#!!!!CURVE THE DRAG_FORCE,ACCELARATION AND ANTHING ELSE!!!!	
	var gravatational_force = mass*9.8
	var angle_from_normal = (Vector3(0,-1,0)).signed_angle_to(-global_basis.y,global_basis.x.normalized())
	var gravatational_force_horizontal = global_basis.z * gravatational_force*sin(angle_from_normal)
	var gravatational_force_vertical = -global_basis.y * gravatational_force*cos(angle_from_normal)
	apply_central_force(gravatational_force_horizontal*5)
	apply_central_force(gravatational_force_vertical*0.1)
	if WheelFL.is_colliding() or WheelFR.is_colliding() or WheelRL.is_colliding() or WheelRR.is_colliding():
		pass
	DebugDraw3D.draw_arrow(global_position ,global_position +  (gravatational_force_horizontal)/40,Color.CHARTREUSE,0.5,true)
	DebugDraw3D.draw_arrow(global_position ,global_position +  (gravatational_force_vertical)/40,Color.DARK_BLUE,0.5,true)

func apply_downforce(delta):


	var up_dir = -global_transform.basis.y
	var velocity = abs(linear_velocity.normalized().dot(-global_basis.z))
	var downforce = velocity * up_dir * mass
	apply_central_force(downforce)
	# Optional: Visualize force

	DebugDraw3D.draw_arrow(global_position, global_position + downforce.normalized()*3, Color.POWDER_BLUE, 0.5, true)



var gear_ratios = [3.17, 2.29, 1.67, 1.31, 1.00, 0.82, 0.68];
var current_gear = 0
var current_gear_ratio = gear_ratios[current_gear]
var rpm_factor 
var fakerpm = 0
var drift_multiplier : float 
var slip_ratio : float
func accel_curve_apply():
	var max_velocity : float= 200
	var current_velocity : float = linear_velocity.dot(-global_basis.z)
	var normalised_velocity : float =  current_velocity/max_velocity
	var lateral_velocity = linear_velocity.dot(global_basis.x)
	slip_ratio = abs(lateral_velocity) / abs(linear_velocity.length())
	fric_multiplier =  fric_curve.sample(normalised_velocity)
	steer_multiplier = steer_curve.sample(normalised_velocity) 
	if can_drift:
		drift_multiplier= drift_curve.sample(slip_ratio)
	else: 
		drift_multiplier = 1
	var wheel_rpm = (abs(current_velocity) / (wheel_raduis * 2 * PI)) * 60
	var engine_rpm = wheel_rpm * current_gear_ratio
	
	engine_rpm = clamp(engine_rpm,800,8000)
	fmod_event_emitter_3d.set_parameter_by_id(2520763146034599108, round(engine_rpm))
	if Input.is_action_pressed("Increase"):
		fakerpm+=100
	elif Input.is_action_pressed("Decrease"):
			fakerpm-=100
	if engine_rpm >7800 and current_gear < gear_ratios.size() - 1: 
		current_gear += 1
		current_gear_ratio = gear_ratios[current_gear]
	elif engine_rpm < 3000.0 and current_gear > 0:
		current_gear -= 1
		current_gear_ratio = gear_ratios[current_gear]
	#print(round(engine_rpm),'|',current_gear,'|',current_gear_ratio,'|',steer_multiplier)

func is_drifting(thresh) -> float:
	var lateral_velocity = linear_velocity.dot(global_basis.x)
	slip_ratio = abs(lateral_velocity) / abs(linear_velocity.length())
	if slip_ratio > thresh:
		return-1
	else :
		return 1
