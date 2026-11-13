extends Tutorial

func _ready():
	super._ready()
	triggered = true

func process_confirm(delta:float):
	if tutorialParent.growing:
		confirm()
