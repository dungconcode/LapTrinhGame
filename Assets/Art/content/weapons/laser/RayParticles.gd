extends GPUParticles2D

func _ready():
	emitting = true
	
	Style.init(self)

func _process(delta):
	if not emitting:
		queue_free()
