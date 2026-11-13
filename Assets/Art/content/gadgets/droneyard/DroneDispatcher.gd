extends Node2D
class_name DroneDispatcher

var cooldown:float

var domeId:String

@export
var dispatcherId:String

var baseSpeed := 50.0
var goalAmount:int

	
func _ready():
	add_to_group("dronedispatcher")

func setAmount(amount:int):
	var drones = getOwnDrones()
	var diff = amount - drones.size()
	if diff > 0:
		for _i in diff:
			spawnDrone()
	elif diff < 0:
		for i in abs(diff):
			drones[drones.size() - 1 - i].kill()

func setBaseSpeed(speed:float):
	self.baseSpeed = speed
	for drone in getOwnDrones():
		drone.baseSpeed = speed

func getOwnDrones() -> Array:
	var ownDrones := []
	for drone in get_tree().get_nodes_in_group("transport_drones"):
		if drone.dispatcherId == dispatcherId:
			ownDrones.append(drone)
	return ownDrones

func spawnDrone(): 
	var drone = preload("res://content/gadgets/droneyard/TransportDrone.tscn").instantiate()
	drone.position = $DroneSpawnPoint.global_position
	drone.speedMod = randf_range(0.9, 1.1)
	drone.baseSpeed = baseSpeed
	Level.map.addDrop(drone)
	assignDrone(drone)

func assignDrone(drone):
	drone.dispatcherId = dispatcherId
	drone.connect("request_path_home", Callable(self, "assignDronePathHome").bind(drone))

func _process(delta):
	if GameWorld.paused:
		return
	
	if cooldown > 0.0:
		cooldown -= delta
		return
	
	cooldown = randf_range(0.4, 0.8)
	
	var waitingDrones := []
	var targettedDrops := []
	for drone in getOwnDrones():
		if drone.state == 0: # Phase.WAIT
			waitingDrones.append(drone)
		
		if drone.targettedDrop:
			targettedDrops.append(drone.targettedDrop)
	
	if waitingDrones.size() == 0:
		return
	
	var drops = []
	for drop in get_tree().get_nodes_in_group("drops"):
		if drop.carryableType != "resource":
			continue
		
		if not TransportDrone.canTransport(drop):
			continue
		
		if targettedDrops.has(drop):
			continue
		
		if drop.linear_velocity.length() > 5:
			continue
		
		if drop.is_in_group("ignore-for-auto-transport"):
			continue
		
		drops.append(drop)
	
	drops.sort_custom(sortByDistance)
	
	while(waitingDrones.size() > 0 and drops.size() > 0):
		var idx = drops.size() -1
		var drop = drops[idx]
		drops.remove_at(idx)
		var drone = getClosestTo(waitingDrones, drop.position)
		if not drone:
			# something is seriously wrong here
			if drop.position.length() > 100_000:
				# drop fell off the map
				drop.shrink()
			else:
				# reset drone
				for d in waitingDrones:
					d.position = $DroneSpawnPoint.global_position
			return
		waitingDrones.erase(drone)
		var dronePos = drone.position
		if drop.position.y <= CONST.DOME_CELLAR_ENTRANCE_Y:
			var path = [dronePos, dronePos * Vector2(0,1), drop.position, drop.position * Vector2(0,1)]
			drone.targetDrop(drop, path)
		else:
			var path = tryFindPath(dronePos, drop.position)
			if path and not path.is_empty():
				if path[0] == (Vector2(0, -1)* GameWorld.TILE_SIZE + CONST.TILE_OFFSET):
					path.insert(0, Vector2(0, -3)* GameWorld.TILE_SIZE + CONST.TILE_OFFSET)
				drone.targetDrop(drop, path)
			else:
				drop.add_to_group("ignore-for-auto-transport")
				drop.create_tween().tween_callback(drop.remove_from_group.bind("ignore-for-auto-transport")).set_delay(10)

func getClosestTo(arr:Array, pos:Vector2):
	var closest = null
	var closestDist := 100_000
	for x in arr:
		var dist = (pos - x.position).length() 
		if dist< closestDist:
			closestDist = dist
			closest = x
	return closest

func assignDronePathHome(drone):
	var path = tryFindPath(drone.position, Vector2(0, -1) * GameWorld.TILE_SIZE + CONST.TILE_OFFSET)
	if path and not path.is_empty():
		path.append(Vector2(0, -5)* GameWorld.TILE_SIZE + CONST.TILE_OFFSET)
		drone.setPathHome(path)

func tryFindPath(startPos, endPos):
	for offset in CONST.PATHFINDING_OFFSETS:
		var path = Level.map.findPath(startPos + offset, endPos)
		if path:
			return path
	return null

func sortByDistance(a, b):
	return a.position.length() > b.position.length()
