extends Path2D

const TOTAL_SHARDS = 40
const Shard = preload("res://content/dome/collapse/Shard.tscn")

func collapse():
	# Add them all to the scene 5 per frame during idle
	# The yield() is an optimization to prevent jank but can be removed
	var points = curve.get_baked_points()
	var size = points.size()
	for i in range(TOTAL_SHARDS):
		var p = points[randi() % size]
		var s = Shard.instantiate()
		s.position = p
		add_child(s)
		if i % 5 == 0:
			await get_tree().process_frame

