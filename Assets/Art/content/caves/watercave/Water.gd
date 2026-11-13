extends Sprite2D

var taken := false
var regrowCooldown := 0.0

func _ready():
	Style.init(self)

func canFocusUse(keeper:Keeper) -> bool:
	return not taken

func _process(delta: float) -> void:
	if GameWorld.paused:
		return
	
	if taken:
		regrowCooldown -= delta
		if regrowCooldown <= 0.0:
			visible = true
			taken = false

func useHold(keeper:Keeper) -> bool:
	return useHit(keeper)

func useHit(keeper:Keeper) -> bool:
	if taken:
		return false
	taken = true
	
	var drop = preload("res://content/drop/water/WaterDrop.tscn").instantiate()
	drop.position = $Usable.global_position
	Level.map.addDrop(drop)
	keeper.attachCarry(drop)
	visible = false
	regrowCooldown = GameWorld.getTimeBetweenWaves() * Data.stabilizedRandomFloat(0.6, 2.5, "watercave", 2)
	
	return true
