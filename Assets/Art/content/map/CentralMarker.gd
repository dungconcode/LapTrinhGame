extends Line2D

func init(endY):
	set_point_position(0, Vector2(0, endY))
	visible = false
	for keeper in Keepers.getAll():
		if keeper.techId == "keeper2":
			Data.listen(self, keeper.playerId + ".keeper2.bundlecentralmarker", true)
	Data.listen(self, "keeper2.bundlecentralmarker", true)

func propertyChanged(property:String, oldValue, newValue):
	if newValue:
		visible = true
