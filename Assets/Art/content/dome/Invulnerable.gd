extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Data.listen(self, "dome.invulnerabletime")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"dome.invulnerabletime":
			if visible:
				if newValue <= 0.0:
					deactivate()
			else:
				if newValue > 0.0:
					activate()

func activate():
	$InvulnerableSprite.modulate = Color(1,1,1,1)
	visible = true
	$InvulnerableSound.play()

func deactivate():
	var duration = 0.15
	$Tween.remove_all()
	$Tween.interpolate_property($InvulnerableSprite, "modulate", Color(1,1,1,1), Color(1,1,1,0), duration, Tween.TRANS_LINEAR)
	$Tween.interpolate_callback(self, duration, "set", "visible", false)
	$Tween.start()
