extends "res://content/map/chamber/Chamber.gd"

func _ready():
	super._ready()
	set_process(false)
	var variant = randi() % 5
	$Background.frame = variant
	$Eye.frame = 5 + variant
	$Front.frame = 10 + variant

func serialize()->Dictionary:
	var data = super.serialize()
	data["variant"] = $Background.frame
	return data
	
func deserialize(data: Dictionary):
	super.deserialize(data)
	var variant = data["variant"]
	$Background.frame = variant
	$Eye.frame = 5 + variant
	$Front.frame = 10 + variant

func onExcavated():
	set_process(true)

func _process(delta):
	var minDeltaPos := Vector2(99999, 0)
	for keeper in Keepers.getAll():
		var deltaPos =  keeper.global_position - (global_position + $Background.offset)
		if deltaPos.length() < minDeltaPos.length():
			minDeltaPos = deltaPos
#	$Background.modulate = Color.white * (clamp(80.0 / deltaPos.length(), 1.0, 6.0))
	$Background.modulate.r = clamp(120.0 / minDeltaPos.length(), 1.0, 5.0)
#	$Background.modulate.g = clamp(80.0 / deltaPos.length(), 1.0, 3.0)
#	$Background.modulate.b = clamp(80.0 / deltaPos.length(), 1.0, 2.0)
	minDeltaPos = (minDeltaPos * 0.1).limit_length(3)
	$Eye.position = minDeltaPos

func getTileType() -> int:
	return Data.TILE_SAND
