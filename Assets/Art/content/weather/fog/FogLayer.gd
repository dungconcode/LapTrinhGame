extends Sprite2D

var direction: Vector2 = Vector2.UP
var speed: float = 50.0

func _ready():
	Style.init(self)
	start_weather()
	
func start_weather():
	var t = DeprecatedTween.new()
	add_child(t)
	var start = modulate
	start.a = 0
	var end = modulate
	end.a = 1
	t.interpolate_property(self, "modulate", start, end, 10.0)
	t.interpolate_callback(t, 10.0, "queue_free")
	t.start()

	(material as ShaderMaterial).set_shader_parameter("direction", direction)
	(material as ShaderMaterial).set_shader_parameter("speed", speed)
			

func stop():
	var t = DeprecatedTween.new()
	add_child(t)
	
	var start = modulate
	start.a = 1
	var end = modulate
	end.a = 0
	t.interpolate_property(self, "modulate", start, end, 3.0)
	t.interpolate_callback(self, 3.0, "queue_free")
	t.start()

func pauseChanged():
	if GameWorld.paused:
		for c in get_children():
			if c is DeprecatedTween:
				c.stop_all()
	else:
		for c in get_children():
			if c is DeprecatedTween:
				c.resume_all()
