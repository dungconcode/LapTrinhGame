extends InputProcessor

var popup

var station
var keeper

func _ready():
	stopSuccessors = false

func handleStart():
	popup.moveIn()
	Audio.sound("enter_station_" + Level.domeId())

func handleStop():
	popup.moveOut()
	if not Keepers.isLocalMultiplayer():
		Level.stage.unpause()
	Audio.sound("exit_station_" + Level.domeId())
	
	keeper.exitStation()
	station.exitStation()

func becameLeaf():
	popup.moveIn(true)
	if not Keepers.isLocalMultiplayer():
		Level.stage.pause()
	InputSystem.changeCursor("default")

func notLeaf():
	popup.moveOut()

func buttonEvent(event) -> bool:
	if Level.stage.pauseMenuOpen:
		return false
	if justPressed(event, "dome_battle"):
		Audio.sound("gui_move")
		popup.moveOut()
		Level.stage.startBattleInput(keeper, station)
	elif justPressed(event, "dome_upgrades"):
		Audio.sound("gui_move")
		popup.moveOut()            
		Level.stage.startUpgradesInput(keeper)
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
