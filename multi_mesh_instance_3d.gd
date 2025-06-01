extends MultiMeshInstance3D
@onready var marker_3d: Marker3D = $"../../Marker3D"
var spawned = false
@export var instances : int = 15625
@export var mesh : ArrayMesh
@export var noise : NoiseTexture2D
@export var scale_no : int = 1000
@export var fauna_no : int 
func _ready() -> void:
	multimesh = MultiMesh.new()
	multimesh.transform_format = 1
	multimesh.instance_count = instances
	multimesh.mesh = mesh
func is_point_inside_area(point: Vector3) -> bool:
	var space_state = get_world_3d().direct_space_state
	if space_state == null:
		return true
	var para = PhysicsPointQueryParameters3D.new()
	para.collide_with_areas = true
	para.collide_with_bodies = false
	para.position = point
	var result = space_state.intersect_point(para,1)
	for hit in result:
		if hit.collider is Area3D:
			return true
	return false

func _physics_process(delta: float) -> void:
	if spawned:
		return
	spawned = true
	for i in range(instances):
		var px = randf_range(0,1123)
		var py = randf_range(0,1123)
		var pos = Vector3(px,0,py)
		while is_point_inside_area(pos + global_position):
			px = randf_range(0,1123)
			py = randf_range(0,1123)
			pos = Vector3(px,0,py)
		var point_noise = noise.noise.get_noise_2d(px,py)
		if point_noise>0.1:
			multimesh.set_instance_transform(i,Transform3D(global_basis.scaled(Vector3.ONE * scale_no),pos))
		elif fauna_no == 0:
			multimesh.set_instance_transform(i,Transform3D(global_basis.scaled(Vector3.ONE * scale_no * randf_range(0,0.5)),pos))
