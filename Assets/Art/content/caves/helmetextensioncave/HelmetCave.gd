extends "res://content/caves/Cave.gd"

var hasHelmet := true

func _ready():
	super._ready()
	$Sprite2D.play("default")

func serialize()->Dictionary:
	var data = super.serialize()
	data["hasHelmet"] = hasHelmet
	return data
	
func deserialize(data: Dictionary):
	super.deserialize(data)
	hasHelmet = data["hasHelmet"]
	if not hasHelmet:
		$Sprite2D.play("empty")
	if currentState == State.REVEALED:
		find_child("AmbSound").play()
	
func onRevealed():
	find_child("AmbSound").play()

func canFocusUse(keeper:Keeper) -> bool:
	return hasHelmet

func useHold(keeper:Keeper) -> bool:
	return useHit(keeper)

func useHit(keeper:Keeper) -> bool:
	if not hasHelmet:
		return false
	
	$HelmetTakenSound.play()
	$Sprite2D.play("empty")
	hasHelmet = false
	
	# using 3.05 as workaround, with 3.0 due to floating point math distortion is way more visible
	# during camera movement
	Data.apply("keeper.zoominmine", 3.05)
	return true
