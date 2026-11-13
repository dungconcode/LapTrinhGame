extends Node2D

var prefix:String

var teleporting := false

var action_hint_teleport := -1

func _ready():
	prefix = get_parent().playerId
	Data.apply(prefix + ".keeper.onewayteleportercooldown", 0)
	Data.apply(prefix + ".keeper.onewayteleporterportalpresent", false)

func addTutorials():
	Level.addTutorial(self, "onewayteleporter")

func serialize()->Dictionary:
	var data = {}
	data["prefix"] = prefix
	data["teleporting"] = teleporting
	data["meta.priority"] = 200
	data["meta.kind"] = "station"
	return data

func deserialize(data:Dictionary):
	prefix = data["prefix"]
	teleporting = data["teleporting"]

func _process(delta):
	if GameWorld.softPaused():
		return
	
	var cooldown = Data.ofOr(prefix + ".keeper.onewayteleportercooldown", 0)
	if cooldown > 0.0:
		cooldown -= delta * GameWorld.cycleSpeed
		Data.apply(prefix + ".keeper.onewayteleportercooldown", cooldown)

func executeSpecial2(keeper:Keeper) -> bool:
	if keeper != get_parent() or GameWorld.paused:
		return false
	
	var cooldown = Data.ofOr(prefix + ".keeper.onewayteleportercooldown", 0)
	if cooldown > 0 or GameWorld.paused or teleporting:
		Audio.sound("gui_err")
		return false
	
	var portals = get_tree().get_nodes_in_group(prefix + "_onewayteleporter")
	
	if not portals.is_empty():
		executeSpecial2Teleport(keeper)
		Data.apply(prefix + ".keeper.onewayteleporterportalpresent", false)
		return true
	elif not keeper.isInsideDome and keeper.position.y > 50:
		var keeperPlacedEye = preload("res://content/caves/teleportcave/TeleporterEye.tscn").instantiate()
		keeperPlacedEye.position = keeper.position
		keeperPlacedEye.add_to_group(prefix + "_onewayteleporter")
		Level.map.add_child(keeperPlacedEye)
		Data.apply(prefix + ".keeper.onewayteleporterportalpresent", true)
		return true
	else:
		Audio.sound("gui_err")
		return false

func executeSpecial2Teleport(keeper:Keeper):
	var portals = get_tree().get_nodes_in_group(prefix + "_onewayteleporter")
	if portals.is_empty():
		return
	
	teleporting = true
	var shrinkTime := 0.5
	var transitionTime:float = 0.5
	
	var eye = portals.front()
	keeper.startTeleportation(self, shrinkTime, keeper.global_position, eye.global_position, true, true)
	
	await get_tree().create_timer(shrinkTime).timeout
	
	if teleporting:
		complete_teleport(keeper, false, shrinkTime, transitionTime)

func complete_teleport(keeper:Keeper, abort:bool, shrinkTime, transitionTime):
	var portals = get_tree().get_nodes_in_group(prefix + "_onewayteleporter")
	if portals.is_empty():
		abort = true
	
	keeper.teleportComplete()
	keeper.grow(shrinkTime, transitionTime - 0.2)
	
	if not abort:
		var eye = portals.front()
		keeper.teleport(eye.position)
		var maxCooldown = Data.of("keeper.onewayteleportermaxcooldown")
		Data.apply(prefix + ".keeper.onewayteleportermaxcooldown", maxCooldown)
		Data.apply(prefix + ".keeper.onewayteleportercooldown", maxCooldown)
		eye.onUsed()
	else:
		Level.viewports.abortTeleportAnimation(keeper)
	teleporting = false
	
func keeperWantsToAbort(keeper:Keeper):
	if not teleporting:
		return
	
	complete_teleport(keeper, true, 0, 0.2)
