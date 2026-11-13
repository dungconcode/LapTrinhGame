extends Area2D

signal relic_recovered

func dropTarget()->Vector2:
	return global_position

func arrived(relic):
	relic.shrink()
	emit_signal("relic_recovered")

func _on_RelicDropPoint_area_entered(area):
	var drop = area.getDeliverableDrop("relic")
	if drop:
		drop.floatToDropTarget(self)
