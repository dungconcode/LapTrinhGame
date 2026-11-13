extends Area2D

var cooldown := 0.0

func _process(delta):
	if get_overlapping_bodies().size() > 0:
		return
	
	if cooldown <= 0:
		var iron = preload("res://content/drop/iron/IronDrop.tscn").instantiate()
		iron.position = $Marker2D.global_position
		get_parent().add_child(iron)
		cooldown = 3.0
	else:
		cooldown -= delta
