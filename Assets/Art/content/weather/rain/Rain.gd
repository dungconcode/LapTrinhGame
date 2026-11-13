extends Sprite2D

func _ready():
	Style.init(self)
	start_weather()
	
func start_weather():
	# Move to correct tree position
	var possible_positions = get_tree().get_nodes_in_group("weather-rain")
	if possible_positions.size():
		get_parent().remove_child(self)
		possible_positions[0].add_child(self)
		
		var t = DeprecatedTween.new()
		add_child(t)
		var start = modulate
		start.a = 0
		var end = modulate
		end.a = 1
		$RainSound.volume_db = -40
		$RainSound.play()
		t.interpolate_property(self, "modulate", start, end, 10.0)
		t.interpolate_property($RainSound, "volume_db", $RainSound.volume_db, 0, 10.0)
		t.interpolate_callback(t, 10.0, "queue_free")
		t.start()
	else:
		queue_free()

func stop():
	var t = DeprecatedTween.new()
	add_child(t)
	
	var start = modulate
	start.a = 1
	var end = modulate
	end.a = 0
	t.interpolate_property(self, "modulate", start, end, 3.0)
	t.interpolate_property($RainSound, "volume_db", 0, -40, 3.0)
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
