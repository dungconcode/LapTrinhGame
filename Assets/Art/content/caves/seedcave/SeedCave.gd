extends "res://content/caves/Cave.gd"

var hasSeed := true

func serialize()->Dictionary:
	var data = super.serialize()
	data["hasSeed"] = hasSeed
	return data
	
func deserialize(data: Dictionary):
	super.deserialize(data)
	hasSeed = data["hasSeed"]
	if not hasSeed:
		find_child("ActiveSprite").queue_free()
		find_child("AmbSound").queue_free()
	if currentState == State.REVEALED:
		find_child("AmbSound").play()
	
func onRevealed():
	find_child("AmbSound").play()

func canFocusUse(keeper:Keeper) -> bool:
	return hasSeed

func useHold(keeper:Keeper) -> bool:
	return useHit(keeper)

func useHit(keeper:Keeper) -> bool:
	if not hasSeed:
		return false
	
	find_child("AmbSound").queue_free()
	hasSeed = false
	find_child("ActiveSprite").queue_free()
	var gizmo = Data.DROP_SCENES.get(CONST.SEED).instantiate()
	gizmo.position = $Usable.global_position
	Level.map.addDrop(gizmo)
	keeper.attachCarry(gizmo)
	return true
