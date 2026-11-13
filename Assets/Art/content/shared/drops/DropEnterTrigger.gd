extends Area2D

func getDeliverableDrop(type:String):
	var p = get_parent()
	if not p.absorbed and p.type == type and not p.independent:
		return p
	else:
		return null

func canBeDelivered() -> bool:
	return get_parent().canFocusCarry()
