extends HudElement

func init():
	super.init()
	Data.listen(self, "droneyard.remainingbattleabilityuses", true)
	Data.listen(self, "droneyard.battleabilityuses", true)

func propertyChanged(property:String, oldValue, newValue):
	match property:
		"droneyard.remainingbattleabilityuses":
			updateCharges(newValue)
		"droneyard.battleabilityuses":
			updateSlots(newValue)

func updateSlots(amount):
	for i in range(1, 4):
		get_node("Slot"+str(i)).visible = amount >= i
	match int(amount):
		1:
			element_size.x = 2
			element_size.y = 1
		2:
			element_size.x = 2
			element_size.y = 2
			for c in get_children():
				c.position.y += 2
		3:
			element_size.x = 2
			element_size.y = 2
			for c in get_children():
				c.position.y -= 2
	emit_signal("request_rebuild")
	
func updateCharges(charges):
	for i in range(1, 4):
		find_child("Charge"+str(i)).visible = charges >= i
