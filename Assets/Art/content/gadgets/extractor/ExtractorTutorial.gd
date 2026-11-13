extends Tutorial

var pickedUp := false

func process_trigger(delta:float) -> bool:
	return keeper.isInsideDome and not keeper.isInsideStation

func process_confirm(delta:float):
	if pickedUp:
		for carry in keeper.carryables:
			if carry.name.find("Extractor") != -1:
				return
		confirm()
	else:
		for carry in keeper.carryables:
			if carry.name.find("Extractor") != -1:
				pickedUp = true
