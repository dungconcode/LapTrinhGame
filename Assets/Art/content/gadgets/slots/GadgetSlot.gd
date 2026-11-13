extends Sprite2D

func setSlots(slots:Array):
	for c in get_children():
		c.visible = slots.has(c.name)
