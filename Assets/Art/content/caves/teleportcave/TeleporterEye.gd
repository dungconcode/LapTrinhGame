extends Node2D

func _ready():
	Style.init($Sprite2D)
	$Sprite2D.play()
	$PlacedSound.play()

func onUsed():
	$Tween.interpolate_property($Sprite2D, "scale", $Sprite2D.scale, Vector2.ZERO, 1.0, Tween.TRANS_QUAD)
	$Tween.interpolate_callback(self, 1.0, "queue_free")
	$Tween.start()

func serialize()->Dictionary:
	var data = {}
	data["meta.priority"] = 200
	data["meta.kind"] = "generic"
	data["groups"] = var_to_str(get_groups())
	return data
	
func deserialize(data: Dictionary):
	for group in str_to_var(data["groups"]):
		if not is_in_group(group):
			add_to_group(group)
