extends CharacterBody2D

enum State {UPWARDS, DOWNWARDS, WAITING_UPWARDS, TRANSITION}
var state:int = State.WAITING_UPWARDS

var carry := []
var carryLines := {}

const maxCarryLineLength := 50.0
const transitionDuration := 1.0
@onready var lift = get_parent()

func _ready():
	position.y = lift.getBottomOfLift() + GameWorld.TILE_SIZE/2
	
	modulate.a = 0.0
	$Tween.interpolate_property(self, "modulate:a", 0.0, 1.0, 0.5)
	$Tween.start()
	$Sprite2D.play("on")
	$OrbAmb.play()
	Style.init(self)

func serialize()->Dictionary:
	var data = {
		"position": position.y,
		"state": state
	}
	return data
	
func deserialize(data: Dictionary):
	position.y = data["position"]
	state = int(data["state"])
	if state == State.DOWNWARDS or state == State.TRANSITION:
		state = State.DOWNWARDS
		goDown()
	if state == State.UPWARDS:
		goUp()

func _physics_process(delta):
	var speed = Data.of("lift.speed")
	if GameWorld.paused:
		speed = 0
		# don't return here, as the drops need to be held in place
	
	updateCarryLines()
	var top = lift.getTopOfLift()
	var bottom = lift.getBottomOfLift()
	var factor = 0.3 + 0.7 * clamp(min(abs(bottom-position.y), abs(top-position.y))/24.0, 0.0, 1.0)
	match int(state):
		State.UPWARDS:
			if position.y <= top:
				$SpawnSound.play()
				dropAllCarries(false)
				$Tween.interpolate_property(self, "modulate", modulate, Color(0.5,0.5,0.5), transitionDuration)
				$Tween.interpolate_property($OrbAmb, "fadeVolume", $OrbAmb.fadeVolume, -12, transitionDuration)
				$Tween.interpolate_callback(self, transitionDuration, "set", "state", State.DOWNWARDS)
				$Tween.start()
				z_index -= 1
				state = State.TRANSITION
				goDown()
			else:
				set_velocity(Vector2(0, -factor * speed))
				move_and_slide()
		State.DOWNWARDS:
			if position.y >= bottom:
				$SpawnSound.play()
				$Tween.interpolate_property(self, "modulate", modulate, Color.WHITE, transitionDuration)
				$Tween.interpolate_property($OrbAmb, "fadeVolume", $OrbAmb.fadeVolume, 0, transitionDuration)
				$Tween.interpolate_callback(self, transitionDuration, "set", "state", State.WAITING_UPWARDS)
				$Tween.start()
				state = State.TRANSITION
			else:
				set_velocity(Vector2(0, factor * speed))
				move_and_slide()
				if z_index != -1 and position.y > CONST.DOME_CELLAR_ENTRANCE_Y:
					z_index = -1
					modulate = Color(0.3,0.3,0.3,1.0)
		State.WAITING_UPWARDS:
			var orbs = get_tree().get_nodes_in_group("lift_orbs")
			var idealDistance = (2 * lift.getLength()) / orbs.size()
			var lowestOrb
			var lowestD := 99999999
			for orb in orbs:
				if orb.state != State.UPWARDS:
					continue
				var d = abs(orb.position.y - position.y)
				if d < lowestD:
					lowestD = d
					lowestOrb = orb
			if not lowestOrb or lowestD >= idealDistance - GameWorld.TILE_SIZE:
				state = State.TRANSITION
				goUp()
			
func goDown():
	$CarryArea/CollisionShape2D.disabled = true
	$Sprite2D.play("off")
	$Trail.emitting = false
	
func goUp():
	$CarryArea/CollisionShape2D.disabled = false
	state = State.UPWARDS
	z_index = 12
	$Sprite2D.play("on")
	$Trail.emitting = true

func updateCarryLines():
	var longest = 0
	for c in carry.duplicate():
		if not is_instance_valid(c):
			dropCarry(c)
			continue
			
		if c.independent:
			dropCarry(c)
		var d = (position - c.position).length()
		if d > longest:
			longest = d
		if d > maxCarryLineLength:
			dropCarry(c)
	
	var strength := 0.15
	for c in carry:
		var dist = position - c.position
		# keep a minimal distance
		if dist.length() < 12.0:
			dist *= 0.0
		else:
			dist -= dist.normalized() * 12
		if dist.y < 0:
			dist.y -= 2.0 * pow(1.0 + dist.length() / maxCarryLineLength, 4)
		
		var factor := 1.0
		var off = dist.length() - 0.15 * maxCarryLineLength
		if off > 0:
			var fill = abs(off / (0.8 * maxCarryLineLength))
			if randf() < fill:
				factor = 10.0 * fill
		c.apply_central_impulse(dist * strength * factor)
		strength *= 0.6

	for t in carryLines:
		if not is_instance_valid(t):
			continue
		var line = carryLines[t]
		line.set_point_position(0, global_position)
		line.set_point_position(1, t.global_position)
		
func attachCarry(body):
	if not is_instance_valid(body):
		return
		
	body.unfocusCarry(self)
	var po = CarryablePhysicsOverride.new(self)
	po.linear_damp = 2
	po.angular_damp = 2
	po.gravity_scale = 0.1
	body.addPhysicsOverride(po)
	carry.append(body)
	body.setCarriedBy(self)
	body.moveToPhysicsBackLayer()
	var infl = body.getCarryInfluence()
	if infl:
		infl.exitBundle()
	$Pickup.play()
	
	var carryLine = preload("res://content/keeper/Carryline.tscn").instantiate()
	carryLine.add_point(position)
	carryLine.add_point(body.position)
	get_parent().add_child(carryLine)
	carryLines[body] = carryLine
	
	Style.init(carryLine)
	
	GameWorld.incrementRunStat("lift_carried_drops")

func dropCarry(body):
	carry.erase(body)
	if is_instance_valid(body):
		body.freeCarry(self)
		$Drop.play()
		
		# Break carryline
		var brk = Data.CARRYLINE_BREAK.instantiate()
		brk.global_position = global_position
		brk.target = body.global_position
		Level.viewports.addElement(brk)
	
	# Delete the carryline
	carryLines[body].queue_free()
	carryLines.erase(body)

func dropAllCarries(moveToPhysicsFrontLayer:bool):
	for body in carry.duplicate():
		dropCarry(body)
		if moveToPhysicsFrontLayer:
			body.moveToPhysicsFrontLayer()

func _on_CarryArea_body_entered(body):
	# 1. capacity to carry
	# 2. not already carried
	# 3. is actually a drop (teleporter portal is also carryable, or mine)
	# 4. is not moving independenty, like from teleporter portal
	if carry.size() < Data.of("lift.capacity")\
		and not body.isCarried()\
		and body.is_in_group("drops")\
		and (not body.hasCarryInfluence() or not body.getCarryInfluence().isBundled()) \
		and body.canFocusCarry():
		attachCarry(body)
