extends RayCast3D
class_name Wheels
@export var wheel_no : int

@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D

@export var can_traction : bool
@export var can_steering : bool
@export var force_offset : Vector3  = Vector3.ZERO
var car : CarController3D
var s_force = Vector3.ZERO
var accel_dir = 1
var wheel_mesh : MeshInstance3D 
var wheel_dir : Marker3D
func _ready() -> void:
	car = get_parent()
	wheel_mesh = get_child(0)
	wheel_dir = wheel_mesh.get_child(0)
func _physics_process(delta: float) -> void:
	if !is_colliding():
		gpu_particles_3d.emitting = false
	var collision_point = get_collision_point()
	calcuate_suspension(collision_point)
	if is_colliding():
		calcuate_acceleration(collision_point)
	if is_colliding() and  abs(car.linear_velocity.dot(-global_basis.z)) > 1  :
		calcuate_steering(delta)

	var speed = sqrt(car.linear_velocity.x**2 +car.linear_velocity.y**2 +car.linear_velocity.z**2)
	var wheel_rpm = (speed / (car.wheel_radius * 2 * PI))
	
	
	if (-global_basis.z).angle_to(car.linear_velocity) < (global_basis.z).angle_to(car.linear_velocity):
		accel_dir = 1
	elif (-global_basis.z).angle_to(car.linear_velocity) > (global_basis.z).angle_to(car.linear_velocity):
		accel_dir = -1
	
	wheel_mesh.rotation.x += accel_dir * wheel_rpm*2*PI*delta
# Get the lateral (sideways) component of the car's velocity
	Telemetery.net_force = Telemetery.engine_force + Telemetery.friction_force

	# Apply force opposite to lateral movement (simulate lateral friction)


var prev_velocity : Vector3 = Vector3.ZERO

func calcuate_steering(delta):
	
	var steering_dir = global_basis.x
	var tire_velocity = _get_point_velocity()
	var steering_vel = tire_velocity.dot(steering_dir) * car.steer_multiplier
	var des_vel_change = -steering_vel 
	var des_a = des_vel_change/delta
	var steering = des_a*steering_dir
	if car.can_drift:
		if car.is_drifting(0.1) == -1:
			steering = des_a*steering_dir* car.drift_multiplier
		else:
			steering = des_a*steering_dir
			pass
	
	Telemetery.steering = steering
	car.apply_force(steering ,global_position - car.global_position)
	if car.debug_wheels:
		DebugDraw3D.draw_arrow(global_position, global_position +(steering)/10,Color.SANDY_BROWN,0.1)

	
	
func calcuate_acceleration(collision_point):
	var velocity = _get_point_velocity().dot(global_basis.z)
	var friction_force = (-velocity) * car.mass * car.fric_multiplier * global_basis.z
	var grip = car.base_grip
	var lateral_velocity = _get_point_velocity().dot(car.global_basis.x) 
	var lateral_dir = car.global_basis.x
	# Add more grip to front or rear depending on wheel number
	if wheel_no in [0, 1]:  # front wheels
		grip *= car.front_grip_bias  # < 1 = understeer, > 1 = oversteer
	else:  # rear wheels
		grip *= car.rear_grip_bias

	var lateral_force = -lateral_velocity * grip * lateral_dir * (0 +(50 * car.drift_multiplier)) * 2
	var accel_dir = Input.get_axis("Down","Up")
	var engine_force =  Vector3.ZERO
	if can_steering:
		friction_force*=0.1
	if can_traction:
		if Input.is_action_pressed("brake") and velocity < 0:
			engine_force += ((-1 * car.horsepower) * (-global_basis.z))  * car.current_gear_ratio
		if accel_dir<0:
			engine_force += ((-1 * car.horsepower*0.5) * (-global_basis.z))  * car.current_gear_ratio
		if accel_dir> 0:
			engine_force += ((1 * car.horsepower) * (-global_basis.z))  * car.current_gear_ratio
	var net_force = engine_force + friction_force
	car.apply_force(net_force,global_position - car.global_position - force_offset)
	car.apply_force(lateral_force,global_position - car.global_position)
	if car.debug_wheels:
		DebugDraw3D.draw_arrow(global_position - force_offset, global_position  - force_offset +(friction_force.normalized())*2,Color.ROSY_BROWN,0.1)
		DebugDraw3D.draw_arrow(global_position - force_offset ,global_position - force_offset +  engine_force.normalized()*3,Color.RED,0.5,true)
		DebugDraw3D.draw_arrow(global_position, global_position +(lateral_force.normalized())*2,Color.ROSY_BROWN,0.1)

	
	

func calcuate_suspension(collision_point):
	if is_colliding():
		target_position.y = - (car.rest_distance + car.wheel_radius)
		var pos_of_ground = collision_point
		var up = get_collision_normal()  # More stable on slopes
		var len = clamp(global_position.distance_to(pos_of_ground) - car.wheel_radius,0 , car.rest_distance)
		get_child(0).position.y = -len 
		var spring_force = (car.rest_distance - len) * car.spring_constant
		var reletive_vel = up.dot(_get_point_velocity())
		var damp_force = car.spring_damping*reletive_vel
		var force_mag = clamp(spring_force - damp_force,-3.9*car.mass,3.9*car.mass)
		var suspension_force :Vector3 = force_mag * up
		var s_force_offset = pos_of_ground - global_position
		car.apply_force(suspension_force,global_position - car.global_position)
		if car.debug_wheels:
			DebugDraw3D.draw_arrow(global_position ,(global_position +  suspension_force / Vector3(1,200,1)),Color.GREEN,0.5,true)
	pass 
func _get_point_velocity():
	var state := PhysicsServer3D.body_get_direct_state(car.get_rid())
	return state.get_velocity_at_local_position(global_position - car.global_position )
	pass
