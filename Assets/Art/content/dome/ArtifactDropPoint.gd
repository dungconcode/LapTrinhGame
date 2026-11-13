extends Area2D

func dropTarget()->Vector2:
	return global_position

func arrived(gadget):
	gadget.shred()

func _on_ArtifactDropPoint_area_entered(area):
	var drop = area.getDeliverableDrop(CONST.GADGET)
	if drop:
		drop.floatToDropTarget(self)
	else:
		drop = area.getDeliverableDrop(CONST.POWERCORE)
		if drop:
			drop.floatToDropTarget(self)
