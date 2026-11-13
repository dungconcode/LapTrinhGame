extends Node2D

signal on_show

var center:Vector2
var sound
var tileCoord:Vector2

func _ready():
	var distance = position.distance_to(center)
	if distance > 0.0:
		# this is the case when it's not a savegame being loaded
		$Timer.wait_time = distance / Data.of("probe.impulseSpeed")
		$Timer.start()
		hide()
		Level.map.addTileRevealedListener(self, tileCoord)
	
	Style.init($Sprite2D)

func serialize()->Dictionary:
	var data = {}
	if visible:
		data["remainingtime"] = $Timer.time_left
	else:
		data["remainingtime"] = Data.of("probe.markerRetention")
	data["tileCoord"] = var_to_str(tileCoord)
	data["meta.priority"] = 100
	data["meta.kind"] = "generic"
	return data

func deserialize(data: Dictionary):
	$Timer.start(data["remainingtime"])
	show()
	$Sprite2D.play("ping")
	tileCoord = BackwardCompatibilityUtils.str_to_var(data["tileCoord"])
	Level.map.addTileRevealedListener(self, tileCoord)

func _on_Timer_timeout():
	if visible:
		remove()
	else:
		show()
		$Sprite2D.play("ping")
		if sound:
			sound.play()
		$Timer.wait_time = Data.of("probe.markerRetention")
		$Timer.start()

func refresh():
	$Timer.start(0)

func remove():
	Level.map.removeTileRevealedListener(self, tileCoord)
	
	if (sound and sound.shouldPlay):
		#hack, if marker is removed before the sound has finished playing wait for it
		create_tween().tween_callback(queue_free).set_delay(3)
	else:
		queue_free()

func tileRevealed(tileCoord:Vector2):
	remove()

func pauseChanged():
	$Timer.paused = GameWorld.paused
