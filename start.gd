extends Area3D
var curr_time : float
var starting_time : float
var is_first_time = true
@export var label_2: Label
func _on_body_entered(body: Node3D) -> void:
	if is_first_time:
		starting_time = Time.get_ticks_msec()/1000
		is_first_time = false
	curr_time = Time.get_ticks_msec()/1000
	label_2.text ="BEST LAP : " +  str(curr_time-starting_time)
	starting_time = curr_time
	pass # Replace with function body.
