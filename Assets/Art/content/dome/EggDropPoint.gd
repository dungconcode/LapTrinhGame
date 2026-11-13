extends Area2D

func arrived(egg):
	egg.grow()
	egg.stabilizeRotation = true

func dropTarget()->Vector2:
	return global_position

func _on_EggDropPoint_area_entered(area):
	var drop = area.getDeliverableDrop("egg")
	if drop:
		drop.floatToDropTarget(self)

