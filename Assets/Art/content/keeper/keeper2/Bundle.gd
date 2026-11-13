extends Node2D

var direction:Vector2
var carryInfluences:Array
var goalSpeed:float
var lastCenterPos:Vector2
var leaderNode
var leaderPoints := []
var velocity:Vector2 = Vector2.ZERO
var curve:Curve2D

var bundleStopCenter:bool

func _ready():
	curve = Curve2D.new()
	Achievements.addIfOpen(self, "KEEPER2_BIGBUNDLE")
	
	Style.init($Shoot)
	$Shoot.hide()

	bundleStopCenter = false
	for keeper in Keepers.getAll():
		if keeper.techId == "keeper2" and Data.of(keeper.playerId + ".keeper2.bundlestopcenter"):
			bundleStopCenter = true
			break

func start(direction:Vector2, bundledCarryables:Array, speed:float, duration:float, leaderNode = null):
	self.direction = direction
	self.goalSpeed = speed
	self.leaderNode = leaderNode
	self.carryInfluences = []
	if leaderNode:
		goalSpeed *= 2.0

#	if direction.length() > 0.0:
#		$Shoot.show()
#		$Shoot.position = Vector2(-10, 0).rotated(direction.angle())
#		$Shoot.rotation = direction.angle()
#		$Shoot.frame = 0
#		$Shoot.play()
	
	if leaderNode:
		Style.init($LeaderLine)
	else:
		$LeaderLine.queue_free()
	
	$BundleCenter/Amb.play()

	for carryable in bundledCarryables:
		addCarryable(carryable,duration)

func addCarryable(c,duration):
	var influence = c.getOrCreateCarryInfluence(self)
	carryInfluences.append(influence)
	influence.strength = duration
	influence.applyBundle(self)

func _physics_process(delta):
	var size = carryInfluences.size()
	if size == 0:
		queue_free()
		return
	
	var center = Vector2()
	# bug when shredding - probably one of the resources in the bundle being freed
	for influence in carryInfluences:
		if not is_instance_valid(influence):
			Logger.error("carry influence instance is not valid anymore")
			continue
		center += influence.getCarryable().global_position
	center /= float(size)
	$BundleCenter.position = center - global_position
	
	velocity = (center - lastCenterPos) / delta
	lastCenterPos = center
	
	var strength = 1.0
	if leaderNode:
		var maxDist = 80 + size * 1.5
		var minDist = 14 + size * 0.5
		var fade = 18 + size * 0.5
		var dist = leaderNode.position - center
		var l = dist.length()
		var strengthMax = clamp(1.0 - (l - (maxDist - fade)) / fade, 0.0, 1.0)
		strengthMax = pow(strengthMax, 2)
		var strengthMin = clamp((l - fade) / fade, 0.0, 1.0)
		strength = min(strengthMin, strengthMax)
		if l < maxDist:
			if l <= minDist:
				direction = Vector2.ZERO
			else:
				direction = dist.normalized()

		leaderPoints.append(to_local(leaderNode.global_position))
		if leaderPoints.size() > 50:
			leaderPoints.pop_front()
		
		var inVec = velocity.normalized() * clamp((l - minDist) * 2.0, 0.0, 60.0)
		inVec *= min(1.0, velocity.length() * 0.02)
		
		curve.clear_points()
		curve.add_point(leaderNode.position - global_position)
		curve.add_point($BundleCenter.position, inVec)
		$LeaderLine.points = curve.get_baked_points()
		
		$LeaderLine.default_color.a = min(strength, 0.7)
		$LeaderLine.width = 0.0 + strength * 2
		$LeaderLine.z_index = 0
	
	var goalMovement = direction * (goalSpeed + size * 0.35) * strength
	
	if goalMovement.length() == 0:
		for influence in carryInfluences:
			
			if not is_instance_valid(influence):
				#removed missing ref influence from array
				carryInfluences.erase(influence)
				continue
			
			var carryable = influence.getCarryable()
			var impulse = center - carryable.global_position
			if impulse.length() > 130.0:
				influence.dissolve()
				continue
			carryable.apply_central_impulse(impulse.limit_length(3))
			
			# Check if the influence is too far from the center of the bundle
			# If so, remove it
#			if (influence.global_position - center).length() > 40:
#				influence.exitBundle()
	else:
		var centerLocked := false
		if bundleStopCenter and abs(center.x) <= GameWorld.TILE_SIZE * 0.5 and not startedInCenter():
			if leaderNode:
				goalMovement.x = -center.x
			else:
				goalMovement = Vector2(-center.x, 0)
			centerLocked = true
		
		
		if goalMovement.length() > 0:
			for influence in carryInfluences:
				
				if not is_instance_valid(influence):
					#removed missing ref influence from array
					carryInfluences.erase(influence)
					continue
					
				var carryable = influence.getCarryable()
				var move = center - carryable.global_position # to center of bundle
				if move.length() > 120.0:
					influence.dissolve()
					continue
				var localCarryablePosition = carryable.global_position - global_position
				
				if not centerLocked and not leaderNode:
					var bundleProgress = localCarryablePosition.project(goalMovement)
					move += bundleProgress - localCarryablePosition
				var impulse = (move + goalMovement).limit_length(3)
				carryable.apply_central_impulse(Vector2(impulse.x, 0))
				carryable.apply_central_impulse(Vector2(0, impulse.y))

func removeCarryInfluence(carryInfluence):
	carryInfluences.erase(carryInfluence)

func getBundledInfluences() -> Array:
	return carryInfluences.duplicate()

func startedInCenter() -> bool:
	return abs(global_position.x) <= GameWorld.TILE_SIZE * 0.5

func serialize()->Dictionary:
	var data = {}

	data["meta.priority"] = 200
	data["meta.kind"] = "generic"
	
	data["velocity"] = var_to_str(velocity)
	data["direction"] = var_to_str(direction)
	data["goal_speed"] = var_to_str(goalSpeed)
	data["last_center_pos"] = var_to_str(lastCenterPos)
	data["bundle_stop_center"]	= var_to_str(bundleStopCenter)
	
	var id = -1
	if leaderNode:
		if leaderNode is Carryable:
			id = leaderNode.UID
		elif leaderNode is Keeper:
			id = leaderNode.playerId
	data["leader_id"] = var_to_str(id)
	
	var targets := []
	for x in carryInfluences:
		targets.append([x.carryable.UID, x.strength])
	data["target_ids"] = var_to_str(targets)
	return data

func deserialize(data: Dictionary):
	velocity = BackwardCompatibilityUtils.str_to_var(data["velocity"])
	direction =  BackwardCompatibilityUtils.str_to_var(data["direction"])
	goalSpeed =  BackwardCompatibilityUtils.str_to_var(data["goal_speed"])
	lastCenterPos =  BackwardCompatibilityUtils.str_to_var(data["last_center_pos"])
	bundleStopCenter =  BackwardCompatibilityUtils.str_to_var(data["bundle_stop_center"])
	
	var all_carryable = get_tree().get_nodes_in_group("carryable")
	var map = {}
	for x in all_carryable:
		map[x.UID] = x
	
	var leaderid = BackwardCompatibilityUtils.str_to_var(data["leader_id"])
	if leaderid is String:
		leaderNode = Keepers.getKeeper(leaderid)
	else:
		leaderNode =  map.get([leaderid])
	var targets = BackwardCompatibilityUtils.str_to_var(data["target_ids"])
	for x in targets:
		var carryable = map.get(x[0])
		var influence = carryable.getOrCreateCarryInfluence(self)
		influence.strength = x[1]
		carryInfluences.append(influence)
		influence.applyBundle(self)
