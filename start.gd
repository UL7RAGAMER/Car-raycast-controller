extends Area3D
var curr_time : float
var starting_time : float
var has_started = false
@export var label_2: Label
func _on_body_entered(body: Node3D) -> void:
	if !has_started:
		starting_time = Time.get_ticks_msec()/1000
		has_started = true
	curr_time = Time.get_ticks_msec()/1000
	label_2.text ="BEST LAP : " +  str(curr_time-starting_time)
	starting_time = curr_time
	pass # Replace with function body.
