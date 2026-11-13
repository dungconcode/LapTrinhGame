extends Node2D
class_name DomeStation

var keeperInStation:Keeper
var keeperId:String

var controlledWeapons:Array

func _ready():
	Data.listen(self, "monsters.wavepresent")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		"monsters.wavepresent":
			if newValue and not keeperInStation:
				waveAlertOn()
			else:
				waveAlertOff()

func getControlledWeapons() -> Array:
	return controlledWeapons

func addControlledWeapon(weapon):
	controlledWeapons.append(weapon)

func canFocusUse(keeper:Keeper) -> bool:
	keeperInStation = null
	return not keeperInStation

func dropTarget()->Vector2:
	return global_position

func getDome():
	# TODO careful eye on here, might need robuster solution
	return get_parent()

func useHold(keeper:Keeper) -> bool:
	return useHit(keeper)

func useHit(keeper:Keeper) -> bool:
	keeperId = keeper.techId
	keeper.enterStation()
	keeperInStation = keeper
	keeperEnteredStation()
	Level.stage.startStationInput(keeper, self)
	return true

func exitStation():
	keeperInStation = null
	keeperExitedStation()

func getKeeperPosition() -> Vector2:
	return $KeeperPosition.global_position

func keeperEnteredStation():
	pass

func keeperExitedStation():
	pass

func waveAlertOn():
	pass

func waveAlertOff():
	pass


