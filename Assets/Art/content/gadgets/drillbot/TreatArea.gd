extends Area2D

signal treat_eaten

func dropTarget()->Vector2:
	return global_position

func _on_TreatArea_area_entered(area):
	var drop = area.getDeliverableDrop("treat")
	if drop:
		drop.floatToDropTarget(self)

func arrived(treat):
	if not treat.absorbed:
		treat.shred()
		emit_signal("treat_eaten")
