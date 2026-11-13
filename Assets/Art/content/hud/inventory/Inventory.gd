extends HudElement

var cache := [0,0,0]

func init():
	super.init()
	Data.listen(self, "inventory.iron", true)
	Data.listen(self, "inventory.water", true)
	Data.listen(self, "inventory.sand", true)

func propertyChanged(property:String, oldValue, newValue):
	match property:
		"inventory.iron":
			cache[0] = newValue
			updateSize()
			find_child("LabelIron").text = str(newValue)
		"inventory.water":
			cache[1] = newValue
			updateSize()
			find_child("LabelWater").text = str(newValue)
		"inventory.sand":
			cache[2] = newValue
			updateSize()
			find_child("LabelSand").text = str(newValue)

func updateSize():
	var limit := 0
	for v in cache:
		limit = max(v, limit)
	if limit >= 100 and element_size.x != 5:
		element_size.x = 5
		%LabelIron.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		%LabelWater.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		%LabelSand.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		request_rebuild.emit()
	elif limit < 100 and element_size.x != 4:
		element_size.x = 4
		%LabelIron.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		%LabelWater.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		%LabelSand.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		request_rebuild.emit()
