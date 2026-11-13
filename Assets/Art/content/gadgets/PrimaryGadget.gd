extends Node2D

var domeId:String

func canFocusUse(keeper:Keeper) -> bool:
	return false

func useHold(keeper:Keeper) -> bool:
	return false

func useHit(keeper:Keeper) -> bool:
	return false

func canOvercharge() -> bool:
	return false

func overcharge():
	pass

func tryOvercharge() -> bool:
	if Data.of("inventory.water") <= 0:
		if not $NoOverchargeSound.playing:
			$NoOverchargeSound.play()
		return false
	else:
		overcharge()
		return true

func executeBattle1() -> bool:
	return false
