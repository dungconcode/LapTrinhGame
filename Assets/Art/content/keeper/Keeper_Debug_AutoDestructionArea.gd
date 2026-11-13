extends Area2D


func _process(delta):
	position = lerp(position, get_parent().moveDirectionInput*20.0, delta*14.0)


func _on_AutoDestructionArea_body_entered(tile):
	if "coord" in tile and tile.has_meta("destructable"):
		Level.map.freeTiles([tile.coord])
