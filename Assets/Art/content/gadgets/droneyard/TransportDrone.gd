extends Node2D
class_name TransportDrone

signal request_path_home

enum State {WAIT, PICKUP, WAIT_FOR_PATH_HOME, RETRIEVE}
# RECHARGE

var state:int = State.WAIT

var cooldown:float
var carriedResource:String
var targettedDrop
var targetSpot:Vector2
var linear_velocity:Vector2
var speedMod:float = 1.0
var baseSpeed:float = 50
var retrieveSpeedMod:float = 0.6
var dispatcherId:String

var currentPath:Array
var currentPathIndex:int
var animationBiasVertical := -0.1
var animationBiasHorizontal := 0.0 

var packedDropContent : Array

func _ready():
	Style.init(self)
	$Sprite.play("spawn")
	setCarriedResource("")
	
	#hide drones in landing sequence
	if not Level.stage.is_revealed:
		hide()
		Level.stage.revealed.connect(onReveal)

func onReveal():
	show()

func _process(delta):
	if GameWorld.paused:
		return
	
	if cooldown > 0.0:
		cooldown -= delta
		return
	
	match int(state):
		State.WAIT:
			# wait until Drone Hub assigns a drop
			$MoveAmb.stop()
			$Sprite.play("idle")
			$Sprite.speed_scale = speedMod
		State.PICKUP:
			if not TransportDrone.canTransport(targettedDrop):
				targettedDrop = null
				state = State.WAIT
				return
			
			if not $MoveAmb.playing:
				$MoveAmb.play()
			
			if followPath(delta):
				var move:Vector2 = targettedDrop.global_position - $PickupSpot.global_position
				if move.length() >= 2 * GameWorld.TILE_SIZE or not is_instance_valid(targettedDrop):
					targettedDrop = null
					state = State.WAIT
					return
				
				#drop was deleted, potentially because it was picked up by another node
				if not targettedDrop.get_parent():
					targettedDrop = null
					state = State.WAIT
					return
					
				if move.length() < 1.0:
					if targettedDrop.type == "pack": 
						for drop in targettedDrop.get_children():
							if "@Sprite2D" in drop.name:
								var dropContent = []
								dropContent.append(drop.get_meta("dropType"))
								dropContent.append(drop.position.x)
								dropContent.append(drop.position.y)
								packedDropContent.append(dropContent)
						targettedDrop.get_parent().remove_child(targettedDrop)
					else:
						targettedDrop.remove()
					targetSpot = Level.dome.getDropTarget(targettedDrop.type).dropTarget()
					setCarriedResource(targettedDrop.type)
					state = State.WAIT_FOR_PATH_HOME
				else:
					move(move.normalized(), baseSpeed * 0.5 * speedMod, delta)
		State.RETRIEVE:
			if not $MoveAmb.playing:
				$MoveAmb.play()
			
			if followPath(delta):
				$Sprite.play("idle")
				var d = targetSpot - global_position
				if d.length() < 1.0:
					if carriedResource == CONST.PACK:
						for drop in packedDropContent:
							Data.changeByInt("inventory."+drop[0], 1)
						packedDropContent.clear()
						for child in $CarriedResource.get_children(): 
							child.queue_free()
					else:
						Data.changeByInt("inventory."+carriedResource, 1)
					setCarriedResource("")
					state = State.WAIT
					$Sprite.speed_scale = speedMod
				else:
					move(d.normalized(), baseSpeed * speedMod, delta)
		State.WAIT_FOR_PATH_HOME:
			# drone hub should assign new path back home
			$Sprite.play("idle")
			$Sprite.speed_scale = speedMod
			emit_signal("request_path_home")
			cooldown = 0.5
			$MoveAmb.stop()

func followPath(delta:float) -> bool:
	if currentPathIndex >= currentPath.size() - 1:
		return true
	
	var nextPoint = currentPath[currentPathIndex]
	var afterNextPoint = currentPath[min(currentPathIndex + 1, currentPath.size() - 1)]
	var d = 0.5 * (nextPoint + afterNextPoint) - position
	if d.length() < 6:
		currentPathIndex += 1
		return followPath(delta)
	move(d.normalized(), baseSpeed, delta)
	return false

func move(direction:Vector2, speed:float, delta:float):
	if carriedResource != "":
		speed *= retrieveSpeedMod
	$Sprite.speed_scale = 0.5 + speedMod * speed / 100.0
	linear_velocity = lerp(linear_velocity, direction * speed, delta * 10)
	position += linear_velocity * delta
	if direction.length() <= 0.1:
		$Sprite.play("idle")
		animationBiasVertical = -0.1
		animationBiasHorizontal = 0.0
	else:
		var prefix = "carry_" if carriedResource != "" else "move_"
		if abs(direction.y) + animationBiasVertical > abs(direction.x) + animationBiasHorizontal:
			animationBiasVertical = 0.2
			animationBiasHorizontal = 0.0
			if direction.y < 0.0:
				$Sprite.play(prefix + "up")
				if $SpriteOverlay.visible:
					$SpriteOverlay.play(prefix + "up")
			else:
				$Sprite.play(prefix + "down")
				if $SpriteOverlay.visible:
					$SpriteOverlay.play(prefix + "down")
		else:
			animationBiasHorizontal = 0.2
			animationBiasVertical = -0.1
			if direction.x < 0.0:
				$Sprite.play(prefix + "left")
				if $SpriteOverlay.visible:
					$SpriteOverlay.play(prefix + "left")
			else:
				$Sprite.play(prefix + "right")
				if $SpriteOverlay.visible:
					$SpriteOverlay.play(prefix + "right")

static func canTransport(drop) -> bool:
	return is_instance_valid(drop) and not \
	(drop.deactivated or \
	drop.independent or \
	drop.isCarried() or \
	drop.hasCarryInfluence() \
	)

func sortByDistance(a, b):
	return (a.position - position).length() < (b.position - position).length()

func targetDrop(drop, path):
	targettedDrop = drop
	targetSpot = targettedDrop.global_position - $PickupSpot.position
	state = State.PICKUP
	currentPath = path
	currentPathIndex = 0

#var line:Line2D
func setPathHome(path):
	state = State.RETRIEVE
	currentPath = path
	currentPathIndex = 0
	
#	if line:
#		line.queue_free()
#	line = Line2D.new()
#	for p in path:
#		line.add_point(p)
#	line.default_color = Color.white
#	line.width = 2
#	get_parent().add_child(line)

func setCarriedResource(res:String):
	carriedResource = res
	match res:
		"":
			$CarriedResource.texture = null
			$Sprite.play("idle")
			$SpriteOverlay.visible = false
		CONST.IRON:
			$CarriedResource.texture = preload("res://content/drop/iron/iron_smol.png")
			$Sprite.play("carry_idle")
			$SpriteOverlay.visible = true
			$SpriteOverlay.play("carry_idle")
			$PickupSound.play()
		CONST.WATER:
			$CarriedResource.texture = preload("res://content/drop/water/water_smol.png")
			$Sprite.play("carry_idle")
			$SpriteOverlay.visible = true
			$SpriteOverlay.play("carry_idle")
			$PickupSound.play()
		CONST.SAND:
			$CarriedResource.texture = preload("res://content/drop/sand/sand_smol.png")
			$Sprite.play("carry_idle")
			$SpriteOverlay.visible = true
			$SpriteOverlay.play("carry_idle")
			$PickupSound.play()
		CONST.PACK:
			for drop in packedDropContent: 
					var newChild = Sprite2D.new()
					match drop[0]:
						"iron":
							newChild.texture = preload("res://content/drop/iron/iron_smol.png")
						"water":
							newChild.texture = preload("res://content/drop/water/water_smol.png")
						"sand":
							newChild.texture = preload("res://content/drop/sand/sand_smol.png")
					newChild.position.x = drop[1]
					newChild.position.y = drop[2]
					newChild.rotation = 0
					newChild.scale = Vector2(0.5, 0.5)
					newChild.material = preload("res://content/drop/ShredMaterial.tres")
					Style.init(newChild)
					$CarriedResource.add_child(newChild)
			$Sprite.play("carry_idle")
			$SpriteOverlay.visible = true
			$SpriteOverlay.play("carry_idle")
			$PickupSound.play()

func serialize()->Dictionary:
	var data = {}
	data["meta.priority"] = 100
	data["meta.kind"] = "generic"
	data["state"] = state
	data["cooldown"] = cooldown
	data["carriedResource"] = carriedResource
	data["dispatcherId"] = dispatcherId
	data["packedDropContent"] = packedDropContent
	return data
	
func deserialize(data: Dictionary):
	state = data["state"]
	if state == State.RETRIEVE:
		state = State.WAIT_FOR_PATH_HOME
	elif state == State.PICKUP:
		state = State.WAIT
	
	cooldown = data["cooldown"]
	carriedResource = data["carriedResource"]
	dispatcherId = data["dispatcherId"]
	
	packedDropContent = data["packedDropContent"]
	
	setCarriedResource(carriedResource)
	
	await GameWorld.savegame_loaded
	for hub in get_tree().get_nodes_in_group("dronedispatcher"):
		if hub.dispatcherId == dispatcherId:
			hub.assignDrone(self)
			return
	Logger.error("Drone failed to find dispatcher with id %s" % dispatcherId)

func kill():
	queue_free()
	if carriedResource != "":
		Data.changeByInt("inventory.total" + carriedResource, -1)
		var drop = Data.DROP_SCENES.get(carriedResource).instantiate()
		drop.position = $CarriedResource.global_position
		Level.map.call_deferred("addDrop", drop)

func onGameLost():
	visible = false
