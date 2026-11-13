extends "res://content/gadgets/CellarGadget.gd"

var hasMushroom := false
var timeUntilGrown := 0.0
var popup 

func _ready():
	hasMushroom = true
	$Sprite.play("ready")
	
	Style.init(self)
	
	if Level.stage:
		popup = preload("res://content/gadgets/mushroomfarm/MushroomEffectOverlay.tscn").instantiate()
		Level.stage.showPopup(popup)
		popup.set_intensity(0)

	for x in Keepers.getAll():
		Data.listen(self, x.playerId + ".keeper.highbuff")
		
	Level.addTutorial(self, "mushroomfarm")
	
func serialize()->Dictionary:
	var data = super.serialize()
	data["hasMushroom"] = hasMushroom
	data["timeUntilGrown"] = timeUntilGrown
	return data

func deserialize(data: Dictionary):
	super.deserialize(data)
	hasMushroom = data["hasMushroom"]
	timeUntilGrown = data["timeUntilGrown"]
	
	if not hasMushroom:
		$Sprite.play("empty")

func canFocusUse(keeper:Keeper) -> bool:
	return hasMushroom

func useHold(keeper:Keeper) -> bool:
	return useHit(keeper)

func useHit(keeper:Keeper) -> bool:
	if not canFocusUse(keeper):
		return false
	
	hasMushroom = false
	$Sprite.play("empty")
	timeUntilGrown = Data.of("mushroomfarm.growthtime") * GameWorld.getTimeBetweenWaves()
	$TakeSound.play()
	
	$poof.stop()
	$poof.play()
	
	var spore = preload("res://content/drop/mushroomfarm/Spore.tscn").instantiate()
	spore.position = $poof.global_position
	Level.map.addDrop(spore)
	keeper.attachCarry(spore)
	
	return true

func _physics_process(delta: float) -> void:
	if GameWorld.paused:
		return
	
	if not hasMushroom:
		timeUntilGrown -= delta
		if timeUntilGrown <= 0.0:
			hasMushroom = true
			$Sprite.play("grow")
			$poof.play()
			
func _on_sprite_animation_finished() -> void:
	match $Sprite.animation:
		"grow":
			$Sprite.play("ready")
		"ready":
			$Sprite.play("idle")
		"idle":
			$Sprite.play("idle" if randf() > 0.4 else "ready")


func propertyChanged(property:String, oldValue, newValue):
	popup.set_intensity(newValue)
	
	
