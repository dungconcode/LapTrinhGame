extends GPUParticles2D

func _ready():
	Style.init(self)
	start_weather()

func start_weather():
	emitting = true

func stop():
	var t = DeprecatedTween.new()
	add_child(t)
	
	var start = modulate
	start.a = 1
	var end = modulate
	end.a = 0
	emitting = false
	t.interpolate_property(self, "modulate", start, end, 10.0)
	t.interpolate_callback(self, 10.0, "queue_free")
	t.start()
