extends ColorRect

signal back
signal proceed

func _ready():
	Style.init($CenterContainer)
	color = Style.OVERLAY_COLOR_IN
	find_child("UnlockablesPanel").init()
	modulate.a = 0.0
	$Tween.interpolate_property(self, "modulate:a", modulate.a, 1.0, 0.1)
	$Tween.interpolate_callback(InputSystem, 0.1, "grabFocus", find_child("CancelButton"))
	$Tween.start()

func _on_UnlockablesPanel_back():
	emit_signal("back")
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_property(self, "modulate:a", modulate.a, 0.0, 0.1)
	$Tween.start()

func _on_UnlockablesPanel_proceed():
	Audio.stopMusic()
	find_child("UnlockablesPanel").applyUnlockable()
	SaveGame.persistMetaState()
	emit_signal("proceed")
	StageManager.startStage("stages/demo/demo")
