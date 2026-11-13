extends Node2D

var tileLength := 0

func _ready():
	Style.init(self)

func serialize()->Dictionary:
	var data = {
		"meta.priority": 200,
		"meta.kind": "station",
		"tileLength": tileLength,
		"station": var_to_str($RemoteControlStation.serialize())
	}
	return data

func deserialize(data:Dictionary):
	tileLength = data["tileLength"]
	if t:
		t.kill()
	setRegion(max(0, tileLength * 24))
	$RemoteControlStation.deserialize(BackwardCompatibilityUtils.str_to_var(data["station"]))

var t
func setLength(y):
	tileLength = y
	
	if t:
		t.kill()
	t = create_tween()
	var oldY = $SpriteMid.region_rect.size.y + $SpriteStart.position.y - 33
	var newY = max(0, y * 24)
	t.tween_method(setRegion, oldY, newY, abs(newY - oldY) * 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT).set_delay(1.0)

func _process(delta: float) -> void:
	$SpriteCable.scale.y = $SpriteCable.position.y - ($RemoteControlStation/CableEnd.position.y + $RemoteControlStation.position.y)

func setRegion(v:float):
	var offset = $SpriteStart.position.y + 3
	$SpriteMid.region_rect.size.y = v - offset + 36
	$SpriteMid.region_rect.position.y = -v + offset
	$SpriteMid.position.y = offset * 0.5 + v * 0.5 + 18 # offset + (v - offset) * 0.5
	$SpriteEnd.position.y = v + 37
	
	$RemoteControlStation.minY = $SpriteStart.position.y + 10
	$RemoteControlStation.maxY = $SpriteEnd.position.y - 10
