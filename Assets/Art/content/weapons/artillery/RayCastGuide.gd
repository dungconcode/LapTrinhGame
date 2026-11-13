extends RayCast2D

func guide() -> float:
	var c = get_collider()
	if not canTarget(c):
		var cl = $RayCastLeft.get_collider()
		var cr = $RayCastRight.get_collider()
		if canTarget(cl):
			return -1.0
		elif canTarget(cr):
			return 1.0
	# TODO: maybe already course correct here? 
	return 0.0

func canTarget(c) -> bool:
	return c and c.alive() and not c.invulnerable
