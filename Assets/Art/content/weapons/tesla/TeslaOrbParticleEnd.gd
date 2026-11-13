extends Node

func end():
	get_parent().emitting = false
	$Timer.start()
	

func _on_Timer_timeout():
	get_parent().queue_free()
