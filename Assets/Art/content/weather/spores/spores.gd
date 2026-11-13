extends Sprite2D

var SporeLayer = load("res://content/weather/spores/sporelayer.tscn")

func _ready():
	Style.init(self)
	start_weather()
	
func start_weather():
	var spore_instances = 0
	var possible_positions = []
	
	# Instance spores
	possible_positions = get_tree().get_nodes_in_group("weather-spores")
	for p in possible_positions:
		var spores = SporeLayer.instantiate()
		p.add_child(spores)
		spore_instances += 1

	if spore_instances == 0:
		queue_free()
		
		
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
