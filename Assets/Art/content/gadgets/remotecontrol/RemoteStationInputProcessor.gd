extends InputProcessor

var popup

var station
var keeper

var inRapidAscent := false

func _ready():
	stopSuccessors = false

func handleStart():
	popup.moveIn()

func handleStop():
	popup.moveOut(true)
	if not Keepers.isLocalMultiplayer():
		Level.stage.unpause()
	
	keeper.exitStation()
	station.exitStation()

func becameLeaf():
	popup.moveIn(true)
	if not Keepers.isLocalMultiplayer():
		Level.stage.pause()
	InputSystem.changeCursor("default")
	station.closeScreenEffect()

func notLeaf():
	popup.moveOut()

func buttonEvent(event) -> bool:
	if Level.stage.pauseMenuOpen or inRapidAscent:
		return false
	
	if justPressed(event, "dome_battle"):
		Audio.sound("gui_move")
		popup.moveOut()
		Level.stage.startBattleInput(keeper, station)
		station.transitionToDome(keeper)
	
	elif justPressed(event, "dome_upgrades"):
		if Data.of("stationextension.buyupgrades"):
			Audio.sound("gui_move")
			popup.moveOut()            
			Level.stage.startUpgradesInput(keeper)
		else:
			Audio.sound("gui_err")
	
	elif justPressed(event,"dome_ability1"):
		if Data.ofOr("stationextension.movetube",false):
			Audio.sound("gui_move")
			
			inRapidAscent = true
			station.startRapidAscent()
		else:
			Audio.sound("gui_err")
	
	elif justPressed(event, "ui_cancel"):
		Audio.sound("gui_cancel")
		desintegrate()
	elif justPressed(event, "escape"):
		return false
	elif justPressed(event, "cheats"):
		# so the parent input processor can deal with this
		return false
	elif justPressed(event, "escape"):
		return false
	
	return true
