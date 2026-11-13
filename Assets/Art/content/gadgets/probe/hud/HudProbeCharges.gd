extends HudElement

func init():
	Data.listen(self, "probe.chargesRemaining")
	Data.listen(self, "probe.charges")
	updateSlots()
	updateCharges()

func propertyChanged(property:String, oldValue, newValue):
	var key = "probe.chargesremaining"
	match property:
		key:
			updateCharges()
		"probe.charges":
			updateSlots()

func updateSlots():
	var unlocked = Data.of("probe.charges")
	for i in range(1, 5):
		get_node("Slot"+str(i)).visible = unlocked >= i
	match int(unlocked):
		1:
			element_size.y = 2
		2:
			element_size.y = 3
		3:
			element_size.y = 5
		4:
			element_size.y = 6
	emit_signal("request_rebuild")

func updateCharges():
	var unlocked = Data.of("probe.chargesRemaining")
	for i in range(1, 5):
		find_child("Charge"+str(i)).visible = unlocked >= i
