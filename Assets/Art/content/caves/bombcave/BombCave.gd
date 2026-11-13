extends "res://content/caves/Cave.gd"

var hasBomb := true

func _ready():
	super._ready()
	$Sprite2D.play("default")

func serialize()->Dictionary:
	var data = super.serialize()
	data["hasBomb"] = hasBomb
	return data
	
func deserialize(data: Dictionary):
	super.deserialize(data)
	hasBomb = data["hasBomb"]
	if not hasBomb:
		$Sprite2D.play("empty")
	if currentState == State.REVEALED:
		find_child("AmbSound").play()
	
func onRevealed():
	find_child("AmbSound").play()

func canFocusUse(keeper:Keeper) -> bool:
	return hasBomb

func useHold(keeper:Keeper) -> bool:
	return useHit(keeper)

func useHit(keeper:Keeper) -> bool:
	if not hasBomb:
		return false
	
	$BombTakenSound.play()
	$Sprite2D.play("empty")
	hasBomb = false
	
	var gizmo = preload("res://content/caves/bombcave/CaveBomb.tscn").instantiate()
	gizmo.position = $Usable.global_position
	Level.map.addDrop(gizmo)
	keeper.attachCarry(gizmo)
	return true
