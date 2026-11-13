extends Area2D


func _process(delta):
	var highestStableIron
	var maxHeight := 0
	for b in get_overlapping_bodies():
		if b.linear_velocity.length() < 4:
			if b.position.y < maxHeight:
				maxHeight = b.position.y
				highestStableIron = b
	
	if maxHeight < -10:
		$Label.text = "height: " + str(abs(maxHeight))
