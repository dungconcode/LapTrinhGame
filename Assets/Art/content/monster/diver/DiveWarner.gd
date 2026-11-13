extends GPUParticles2D

func _ready():
	Style.init(self)
	emitting = true
	
func _on_Timer_timeout():
	queue_free()

func pauseChanged():
	if GameWorld.paused:
		$Timer.paused = true
	else:
		$Timer.paused = false
		if $Timer.time_left >= 2.0:
			emitting = true
