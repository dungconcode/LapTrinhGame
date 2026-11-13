extends Node

var id:String

var cooldown := 0.0

func _process(delta):
	if cooldown > 0.0:
		cooldown -= delta
	else:
		cooldown += 1.0
		var count = get_parent().tileData.get_remaining_mineable_tile_count()
		if count == 0:
			Achievements.triggerIfOpen(id)
			queue_free()
