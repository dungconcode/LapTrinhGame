extends Timer


func _ready():
	var spr = get_parent() as AnimatedSprite2D
	spr.frame = 0
	spr.play()
	$"%UseParticles".emitting = true

func _on_StartAndRemove_timeout():
	queue_free()
