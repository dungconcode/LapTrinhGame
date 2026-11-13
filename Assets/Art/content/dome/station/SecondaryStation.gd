extends DomeStation

func _ready():
	super._ready()
	$Sprite2D.play("idle")
	$Sprite2.visible = false
	$KeeperSprite.visible = false

func useHit(keeper:Keeper) -> bool:
	keeperId = keeper.techId
	keeper.enterStation()
	keeperInStation = keeper
	keeperEnteredStation()
	Level.stage.startBattleInput(keeper, self, true)
	return true

func keeperEnteredStation():
	$KeeperSprite.sprite_frames = keeperInStation.get_node("Sprite2D").sprite_frames
	$Sprite2D.play("on")
	$Usable.updateFocus()

func keeperExitedStation():
	$KeeperSprite.visible = false
	$Sprite2D.play("off")
	$Usable.updateFocus()
	if Data.of("monsters.wavepresent"):
		$Sprite2D.play("attack")

func waveAlertOn():
	$Sprite2D.play("attack")

func _on_sprite_2d_animation_looped() -> void:
	_SpriteAnimationFinishedCheck()

func _on_Sprite_animation_finished() -> void:
	_SpriteAnimationFinishedCheck()

func _SpriteAnimationFinishedCheck() -> void:
	if $Sprite2D.animation.begins_with("on"):
		$Sprite2D.play("running")
	elif $Sprite2D.animation == "off":
		$Sprite2D.play("idle")


func _on_Sprite_frame_changed():
	if $Sprite2D.animation == "on" and $Sprite2D.frame == 6:
		$KeeperSprite.visible = true
		$Sprite2.visible = true
	elif $Sprite2D.animation == "off" and $Sprite2D.frame == 3:
		$Sprite2.visible = false


