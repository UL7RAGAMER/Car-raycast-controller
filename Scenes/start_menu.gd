extends VBoxContainer
@onready var world_environment: WorldEnvironment = $"../../WorldEnvironment"
@onready var speed: Label = $"../Speed"
@onready var best_lap: Label = $"../Best_lap"
@onready var fmod_event_emitter_3d: FmodEventEmitter3D = $"../../Node3D/Node3D/Camera3D/FmodEventEmitter3D"
@onready var node_3d: CarController3D = $"../../Node3D"
@onready var menu_theme: AudioStreamPlayer = $Menu_Theme
@onready var button_click: AudioStreamPlayer3D = $Button_click
var starting_pos 
var can_input = false
func _ready() -> void:
	starting_pos = node_3d.global_transform
	world_environment.camera_attributes.dof_blur_far_enabled = false
	speed.visible = false
	best_lap.visible = false
	node_3d.audio_stream_player_3d.stream_paused = true
	menu_theme.play()
	node_3d.freeze = true
func _process(delta: float) -> void:
	if !can_input:
		node_3d.node_3d.rotation_degrees+=Vector3(0,1,0)
	menu_theme.stream_paused =false
	if Input.is_action_just_pressed("Restart"):
		restart()
@onready var count_down: AudioStreamPlayer3D = $CountDown
func restart():
	node_3d.global_transform = starting_pos
	node_3d.freeze = true
	count_down.play()
	await get_tree().create_timer(3.274).timeout
	node_3d.freeze = false
func _on_start_pressed() -> void:
	visible = false
	can_input = true
	button_click.play()
	node_3d.node_3d.rotation_degrees = Vector3.ZERO
	menu_theme.volume_db = lerp(menu_theme.volume_db,-1000.0,0.1)
	await button_click.finished
	world_environment.camera_attributes.dof_blur_far_enabled = !true	
	speed.visible = !false
	best_lap.visible = !false
	node_3d.is_in_title = false
	fmod_event_emitter_3d.play()
	menu_theme.stop()
	node_3d.audio_stream_player_3d.stream_paused = false
	count_down.play()
	await get_tree().create_timer(3.274).timeout
	node_3d.freeze = false
	
	pass # Replace with function body.


func _on_exit_pressed() -> void:
	button_click.play()
	await button_click.finished
	get_tree().quit()
	pass # Replace with function body.
