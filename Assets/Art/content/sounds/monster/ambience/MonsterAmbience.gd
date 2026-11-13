extends AudioStreamPlayer

@export var beginAt := 1.0
@export var maximumAt := 2.0
@export var one_shot := false

var baseVolume:float
var goalVolume:float
var shouldStop := false
var startOneShot:bool

func _ready():
	baseVolume = volume_db - 15
	volume_db = baseVolume

func roundStarts():
	startOneShot = true

func update(current:float):
	if one_shot:
		if startOneShot and current > 0 and not playing:
			play()
			startOneShot = false
		return
	
	if current < beginAt:
		if playing:
			shouldStop = true
			goalVolume = baseVolume - 20
		return
	elif not playing:
		shouldStop = false
		volume_db = baseVolume - 20
		play()
	
	var relativeVolume = clamp((1 + current - beginAt) / ((1 + maximumAt) - beginAt), 0.0, 1.0)
	goalVolume = baseVolume + 15 * relativeVolume

func _process(delta):
	if not playing:
		return
	
	var deltaVolume = goalVolume - volume_db
	if abs(deltaVolume) > 0.2:
		volume_db += 30 * sign(deltaVolume) * delta 
	elif shouldStop:
		stop()
		shouldStop = false
