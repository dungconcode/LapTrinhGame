extends DomeStation

func _ready():
	super._ready()
	$Sprite2D.play("idle")
	$WaveAlarm.visible = false

func keeperEnteredStation():
	$Sprite2D.play("on_" + keeperId)
	$Usable.updateFocus()
	$WaveAlarm.visible = false

func keeperExitedStation():
	$Sprite2D.play("off")
	$Usable.updateFocus()
	if Data.of("monsters.wavepresent"):
		$WaveAlarm.visible = true
		$Sprite2D.play("attack")

func waveAlertOn():
	$Sprite2D.play("attack")
	$WaveAlarm.visible = true
	$WaveAlarm.frame = 0
	$WaveAlarm.play()

func waveAlertOff():
	$WaveAlarm.visible = false

func _on_sprite_2d_animation_looped() -> void:
	_SpriteAnimationFinishedCheck()

func _on_Sprite_animation_finished() -> void:
	_SpriteAnimationFinishedCheck()

func _SpriteAnimationFinishedCheck() -> void:
	if $Sprite2D.animation.begins_with("on"):
		$Sprite2D.play("running_" + keeperId)
	elif $Sprite2D.animation == "off":
		$Sprite2D.play("idle")


