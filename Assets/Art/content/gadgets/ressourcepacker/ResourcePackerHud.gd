extends HudElement

var pointIdsByMaxCharges := {
	2: [2, 4],
	3: [2, 3, 4],
	4: [1, 2, 4, 5],
	5: [1, 2, 3, 4, 5],
}

func init():
	Data.listen(self, "resourcepacker.charges")
	Data.listen(self, playerId + ".resourcepacker.chargesremaining", true)

func propertyChanged(property:String, oldValue, newValue):
	var max = Data.of("resourcepacker.charges")
	$Sprite2D.frame = max - 2
	$ResourcepackerSound.play()
	var ids = pointIdsByMaxCharges[int(max)]
	
	for i in 5:
		find_child("Chargingpoint" + str(i + 1)).visible = false
	
	var current = Data.of(playerId + ".resourcepacker.chargesremaining")
	for i in current:
		find_child("Chargingpoint" + str(ids[i])).visible = true
