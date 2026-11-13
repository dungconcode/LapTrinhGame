extends "res://content/gadgets/CellarGadget.gd"

var hasDrillbot:bool
var hasPlant := false
var plantGrowth := 0.0
var keeper 
var remainingDrillbots := 0
var producedBots := 0

func _ready():
	Style.init(self)
	Data.listen(self, "drillbot.headcount", true)
	updateStation()
	
	Level.addTutorial(self, "drillbotcarry")

func serialize()->Dictionary:
	var data = super.serialize()
	data["hasDrillbot"] = hasDrillbot
	data["hasPlant"] = hasPlant
	data["plantGrowth"] = plantGrowth
	data["remainingDrillbots"] = remainingDrillbots
	data["producedBots"] = producedBots
	return data
	
func deserialize(data: Dictionary):
	super.deserialize(data)
	hasDrillbot = data["hasDrillbot"]
	hasPlant = data["hasPlant"]
	plantGrowth = data["plantGrowth"]
	remainingDrillbots = data["remainingDrillbots"]
	# backwards compatibility when this property did not exist
	producedBots = data.get("producedBots", Data.of("drillbot.headcount") - remainingDrillbots)
	updateStation()

func addDrillbot():
	if not hasDrillbot:
		$GlasOverlaySprite.play("open")
		updateStation()
		$Sprite2D.pause()

func propertyChanged(property:String, oldValue, newValue):
	var bots = get_tree().get_nodes_in_group("drillbots")

	match property:
		# ONLY LOWERCASE HERE
		"drillbot.headcount":
			remainingDrillbots = newValue - producedBots
			updateStation()

	for bot in bots:
		bot.station = self
		addDrillbot()

func useHold(keeper:Keeper) -> bool:
	return useHit(keeper)

func canFocusUse(keeper:Keeper) -> bool:
	return hasDrillbot or hasPlant

func _process(delta):
	if hasDrillbot or GameWorld.softPaused():
		return
	
	var growthTime = Data.of("drillbot.plantgrowthtime") * GameWorld.getTimeBetweenWaves()
	if not hasPlant and growthTime > 0.0:
		plantGrowth += delta
		if plantGrowth >= growthTime:
			growPlant()
		elif plantGrowth >= growthTime * 0.3:
			$Sprite2D.frame = 1

func growPlant():
	hasPlant = true
	$Sprite2D.frame = 2
	$FruitReadySound.play()

func useHit(keeper:Keeper) -> bool:  
	if hasDrillbot: 
		$OpeningSound.play()
		hasDrillbot = false
		$Sprite2D.play("open")
		$GlasOverlaySprite.play("open")
		self.keeper = keeper
		return true
	elif hasPlant:
		hasPlant = false
		$Sprite2D.frame = 0
		plantGrowth = 0.0
		
		var treat = preload("res://content/drop/treat/Treat.tscn").instantiate()
		treat.position = $DropPosition.global_position
		Level.map.addDrop(treat)
		keeper.attachCarry(treat)
	return false

func updateStation():
	hasDrillbot = remainingDrillbots > 0
	if hasDrillbot:
		$Sprite2D.play("idle")
		$GlasOverlaySprite.play("default")
	else:
		$Sprite2D.animation = "plant"
		if hasPlant:
			$Sprite2D.frame = 2
		else:
			$Sprite2D.frame = 0

func _on_Sprite_animation_finished():
	if keeper and $Sprite2D.animation == "open":
		var drillbot = preload("res://content/gadgets/drillbot/Drillbot.tscn").instantiate()
		drillbot.position = $DropPosition.global_position
		Level.map.addDrop(drillbot)
		keeper.attachCarry(drillbot)
		drillbot.setDirection(Vector2.RIGHT if $Sprite2D.flip_h else Vector2.LEFT)
		$Sprite2D.animation = "plant"
		if hasPlant:
			$Sprite2D.frame = 2
		else:
			$Sprite2D.frame = 0
		$Sprite2D.pause()
		keeper = null
		remainingDrillbots -= 1
		producedBots += 1
		updateStation()
