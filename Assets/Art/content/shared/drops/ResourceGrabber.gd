extends Area2D

signal grabbed_resource

@export var dropType := "" # (String, "", "iron", "water", "sand", "treat")

var spent := false

func dropTarget()->Vector2:
	return global_position

func arrived(gadget):
	gadget.shred(false)
	emit_signal("grabbed_resource")

func _on_ResourceGrabber_area_entered(area):
	if spent:
		return
	
	if area.canBeDelivered():
		var drop = area.getDeliverableDrop(dropType)
		if drop:
			drop.floatToDropTarget(self)
			spent = true

func disable():
	set_deferred("monitoring", false)

func enable():
	set_deferred("monitoring", true)
