extends Node2D

const LIGHTNING_TEXTURE = preload("res://content/weather/lightning/lightning.png")
const LIGHTNING_MATERIAL = preload("res://content/weather/lightning/lightning_mat.tres")
const SOUNDS = [
	preload("res://content/sounds/Weather/lightning_1.wav"),
	preload("res://content/sounds/Weather/lightning_2.wav"),
	preload("res://content/sounds/Weather/lightning_3.wav"),
	preload("res://content/sounds/Weather/lightning_4.wav"),
]

func _ready():
	start_weather()
	
func start_weather():
	var possible_positions = get_tree().get_nodes_in_group("weather-lightning")
	if possible_positions.size():
		get_parent().remove_child(self)
		possible_positions[0].add_child(self)
	else:
		queue_free()

func stop():
	$StrikeTimer.stop()
	var t = DeprecatedTween.new()
	add_child(t)
	t.interpolate_callback(self, 10.0, "queue_free")
	t.start()

func _on_StrikeTimer_timeout():
	$StrikeTimer.wait_time = randf_range(0.5, 5.0)
	
	# Choose a random strike location
	var flash = randf()
	var strikes = get_tree().get_nodes_in_group("weather-lightningstrike")
	var strike = strikes[randi() % strikes.size()]
	for s in [$LightningSound1, $LightningSound2, $LightningSound3]:
		if not s.playing:
			s.stream = SOUNDS[randi() % SOUNDS.size()]
			s.play()
			break
	if strike.dome:
		flash = 1.0
		InputSystem.shake(80, 1.0, 16, strike.global_position)
		$DomeStrikeSound.play()
		
	# Don't draw the lightning when off screen
	if not $VisibleOnScreenNotifier2D.is_on_screen():
		return
		
	var end = global_position + strike.position
	var start = global_position + Vector2(0, -500)
	start.x = end.x + randf_range(-200, 200)
	
	# Create the main lightning branch
	var l = Line2D.new()
	l.texture = LIGHTNING_TEXTURE
	l.texture_mode = Line2D.LINE_TEXTURE_TILE
	l.width = 8
	l.material = LIGHTNING_MATERIAL
	
	var segment_length = 32
	var length = (end - start).length()
	var dir = (end - start).normalized()
	var points = ceil(length / segment_length)
	
	for i in range(points):
		var p = start + dir * i * segment_length
		p += Vector2(randf_range(-32, 32), randf_range(-16,0))
		l.add_point(p)
		if randf() < 0.5:
			var branch_dir = Vector2(1, 0)
			if randf() < 0.5: branch_dir.x = -1
			create_branch(l, p, branch_dir, 1)
	l.add_point(end)
	add_child(l)

	# Animate fade out
	var t = DeprecatedTween.new()
	add_child(t)
	if flash > 0.67 and not Options.photosensitive:
		$CanvasLayer/ColorRect.show()
		$CanvasLayer/ColorRect.modulate = Color(1,1,1,0.2)
		t.interpolate_property($CanvasLayer/ColorRect, "modulate", $CanvasLayer/ColorRect.modulate, Color(1,1,1,0), 0.05, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	t.interpolate_property(l, "modulate", Color(1,1,1,1), Color(1,1,1,0), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN)
	t.interpolate_property(l, "modulate", Color(1,1,1,1), Color(1,1,1,0), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.1)
	t.interpolate_callback(l, 0.5, "queue_free")
	t.interpolate_callback(t, 0.5, "queue_free")
	t.start()

func create_branch(line: Line2D, start: Vector2, branch_dir: Vector2, depth: int):
	# Create a lightning branch
	var l = Line2D.new()
	l.texture = LIGHTNING_TEXTURE
	l.texture_mode = Line2D.LINE_TEXTURE_TILE
	l.width = 4
	l.material = LIGHTNING_MATERIAL
	
	var segment_length = 16
	var points = (randi() % 10 + 4) - depth * 4
	if points < 0:
		points = 3
	
	l.add_point(start)
	var p = start
	var branched = false
	for _i in range(points):
		p += branch_dir * segment_length
		p += Vector2(randf_range(0, 6), randf_range(-8, 16))
		if p.y > 0:
			break
		l.add_point(p)
		# Not too many or we'll cause a stack overflow
		if depth <= 2 and not branched and randf() < 0.2:
			branched = true
			create_branch(l, p, branch_dir, depth + 1)

	line.add_child(l)


func pauseChanged():
	$StrikeTimer.paused = GameWorld.paused
