extends Node2D

func hit(tile, buffed:bool, playHitPitch:bool):
	# play the sound for the right hardness
	var soundPlayer = get_node("TileHitHardness" + str(tile.hardness))
	soundPlayer.play()
	
	if playHitPitch:
		$TileHitPitch.pitch_scale = 0.8 + 0.4 * (1.0 - tile.health / tile.max_health)
		$TileHitPitch.play()

	# if there is a special sound for that tile type, play it
	if has_node("TileHit" + tile.type.capitalize()):
		soundPlayer = get_node("TileHit" + tile.type.capitalize())
		soundPlayer.play()

	if buffed:
		$TileHitBuffed.play()
