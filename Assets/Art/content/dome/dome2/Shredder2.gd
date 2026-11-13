extends "res://content/dome/shredder/Shredder.gd"

func getDistance(drop) -> float:
	return abs(drop.global_position.x - $ShredPoint.global_position.x) + 3 * abs(drop.global_position.y - $ShredPoint.global_position.y)
