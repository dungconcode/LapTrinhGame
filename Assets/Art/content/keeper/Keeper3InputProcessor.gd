extends "res://content/keeper/KeeperInputProcessor.gd"

var roping := false

func _process(delta):
	super._process(delta)
	if GameWorld.paused or desintegrating:
		return
	
	if roping:
		keeper.rope()

func keeperButtonEvent(event, handled:bool):
	if justPressed(event, "keeper3_throw"):
		keeper.throw()
	
	if justPressed(event, "keeper3_rope"):
		roping = true
	elif released(event, "keeper3_rope"):
		roping = false 
		keeper.stop_rope()
	

func becameLeaf():
	super.becameLeaf()
	GameWorld.setShowMouse(runningInLoadout and Options.useMouseMenus or Options.useMouseKeeperGameplay)
	InputSystem.changeCursor("default")
