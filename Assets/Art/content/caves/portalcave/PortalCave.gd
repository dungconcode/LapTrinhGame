extends "res://content/caves/Cave.gd"

var cooldown := 0.0

func onRevealed():
	find_child("Amb").play()
	$Sprites/Sprite.play("idle2")

func _physics_process(delta: float) -> void:
	if GameWorld.paused:
		return
	
	if cooldown > 0.0:
		cooldown -= delta
		return
	
	var bods:Array = $TeleportArea.get_overlapping_bodies()
	if bods.size() > 0:
		var drop = bods.pick_random()
		$Sprites/Sprite.play("teleport2")
		drop.floatToDropTarget(self)
		drop.deactivate()
		drop.noCollisions()
		drop.shrink()
		cooldown = 0.2

func _on_sprite_animation_finished() -> void:
	if $Sprites/Sprite.animation == "teleport2":
		$Sprites/Sprite.play("idle2")
	elif $Sprites/Sprite.animation == "teleport1":
		$Sprites/Sprite.play("idle1")

func dropTarget():
	return $GravityArea.global_position

func arrived(drop):
	pass
