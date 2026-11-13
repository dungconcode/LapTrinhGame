extends Sprite2D

@onready var dust1 = $Dust1
@onready var dust2 = $Dust2
@onready var tornado = $Tornado
var direction = 1
var change_direction = 0.0

func _ready():
	Style.init(self)
	start_weather()
	
func start_weather():
	# Move to correct tree position
	var possible_positions = get_tree().get_nodes_in_group("weather-windstorm")
	if possible_positions.size():
		get_parent().remove_child(self)
		possible_positions[0].add_child(self)
		
		var t = DeprecatedTween.new()
		add_child(t)
		var start = modulate
		start.a = 0
		var end = modulate
		end.a = 1
		$WindSound.volume_db = -40
		$WindSound.play()
		t.interpolate_property(self, "modulate", start, end, 3.0)
		t.interpolate_property(dust1, "modulate", start, end, 3.0)
		t.interpolate_property(dust2, "modulate", start, end, 3.0)
		tornado.self_modulate = start
		t.interpolate_property(tornado, "self_modulate", start, end, 3.0, Tween.TRANS_CUBIC, Tween.EASE_IN, 2.0)
		t.interpolate_property($WindSound, "volume_db", $WindSound.volume_db, 0, 3.0)
		t.interpolate_callback(t, 10.0, "queue_free")
		t.start()
	else:
		queue_free()

	possible_positions = get_tree().get_nodes_in_group("weather-windstormfar")
	if possible_positions.size():
		remove_child(dust2)
		possible_positions[0].add_child(dust2)
		
		remove_child(tornado)
		possible_positions[0].add_child(tornado)

func stop():
	var t = DeprecatedTween.new()
	add_child(t)
	
	var start = modulate
	start.a = 1
	var end = modulate
	end.a = 0
	t.interpolate_property(self, "modulate", start, end, 3.0)
	t.interpolate_property(dust1, "modulate", start, end, 3.0)
	t.interpolate_property(dust2, "modulate", start, end, 3.0)
	tornado.emitting = false
	t.interpolate_property($WindSound, "volume_db", 0, -40, 3.0)
	t.interpolate_callback(self, 3.0, "queue_free")
	t.start()

func _process(delta):
	dust1.region_rect.position.x -= 2000 * delta
	dust1.region_rect.position.y = 0

	dust2.region_rect.position.x -= 500 * delta
	dust2.region_rect.position.y = 0
	
	change_direction -= delta
	if change_direction <= 0:
		change_direction = 3
		if randf() < 0.5:
			direction = 1
		else:
			direction = -1
		if tornado.position.x > 200:
			direction = -1
		elif tornado.position.x < -200:
			direction = 1
	tornado.position.x += direction * 20 * delta
	tornado.position.x += sin(Time.get_ticks_msec() / 290.0) + sin(Time.get_ticks_msec() / 130.0)
	
func pauseChanged():
	if GameWorld.paused:
		for c in get_children():
			if c is DeprecatedTween:
				c.stop_all()
	else:
		for c in get_children():
			if c is DeprecatedTween:
				c.resume_all()
