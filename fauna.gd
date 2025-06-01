extends Node3D

@export var noise : NoiseTexture2D
@export var grass : PackedScene
@export var area_size : int = 512
@export var density : float = 0.1  # Adjust as needed

func _ready() -> void:



	# Estimate max number of instances based on density
	var max_instances = int(area_size * area_size * density)
	var noise_obj = noise.noise
	
	
	for x in range(area_size):
		for z in range(area_size):
			var noise_val = noise_obj.get_noise_2d(x,z)
			
			if noise_val > 0.3:  # You can tweak this threshold
				var pos = Vector3(1, 0, 1)
				var g : Node3D  = grass.instantiate()
				g.position = pos
				add_child(g)
				
				

	# Adjust instance count to the actual number placed
