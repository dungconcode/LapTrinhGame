extends RefCounted

var cells := []

func addCell(coord:Vector2):
	cells.append(coord)

func tileRevealed(coord:Vector2):
	var cellCount:int = cells.size()
	var placedDecorations:Array = Level.map.decorations().applyDecoratives(cells)
	if placedDecorations.size() == 0:
		return
	var visibilityRate:float = cellCount * 0.75 / float(placedDecorations.size())
	for deco in placedDecorations:
		if randf() < visibilityRate:
			deco.makeVisible()
