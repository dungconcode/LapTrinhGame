extends HudElement

func init():
	Data.listen(self, playerId + ".keeper.onewayteleportercooldown", true)
	Data.listen(self, playerId + ".keeper.onewayteleporterportalpresent", true)

func propertyChanged(property:String, oldValue, newValue):
	var key1 = playerId + ".keeper.onewayteleportercooldown"
	var key2 = playerId + ".keeper.onewayteleporterportalpresent"
	match property:
		key1:
			if newValue <= 0.0:
				$ReadySound.play()
				$Eye.play("cooldown_finished")
			else:
				$Eye.animation = "cooldown"
				var maxCooldown = Data.of(playerId + ".keeper.onewayteleportermaxcooldown")
				$Eye.frame = 24.0 * (1.0 - newValue / maxCooldown)
		key2:
			if newValue:
				$Eye.play("portal_placed")

func _on_eye_animation_looped() -> void:
	_EyeAnimationFinishedCheck()

func _on_Eye_animation_finished() -> void:
	_EyeAnimationFinishedCheck()

func _EyeAnimationFinishedCheck() -> void:
	if $Eye.animation == "cooldown_finished":
		$Eye.play("ready_to_use")
