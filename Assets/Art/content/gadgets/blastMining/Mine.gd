extends Carryable

var activated := false
var untilExplosion := 0.0
var maxUntilExplosion := 0.0
var exploded := false
var sticks := false
var lastVelocity
var stickingTo:Vector2
var animationSuffix:String

func _ready():
	super._ready()
	Style.init(self)
	contact_monitor = false
	$Adhesion.visible = false
	var bombsize = int(min(100, Data.of("blastMining.bombsize")))
	animationSuffix = "_" + str(bombsize)
	match bombsize:
		0: $Adhesion.frame = 0
		1: $Adhesion.frame = 1
		2: $Adhesion.frame = 2
		3: $Adhesion.frame = 3
		4: $Adhesion.frame = 4
		100: $Adhesion.frame = 1
	$Sprite2D.play("normal" + animationSuffix)

func serialize()->Dictionary:
	var data = super.serialize()
	data["activated"] = activated
	data["untilExplosion"] = untilExplosion
	data["maxUntilExplosion"] = maxUntilExplosion
	data["exploded"] = exploded
	data["sticks"] = sticks
	data["stickingTo"] = var_to_str(stickingTo)
	return data
	
func deserialize(data: Dictionary):
	super.deserialize(data)
	activated = data["activated"]
	untilExplosion = data["untilExplosion"]
	maxUntilExplosion = data["maxUntilExplosion"]
	exploded = data["exploded"]
	sticks = data["sticks"]
	stickingTo = BackwardCompatibilityUtils.str_to_var(data["stickingTo"])
	
	if activated:
		activate()
	else:
		deactivate()
		
	if exploded:
		queue_free()
	
	if sticks and stickingTo:
		var delta = getStickToDirection()
		$Adhesion.visible = true
		$Adhesion.rotation = delta.angle() - rotation
		changeToStatic.call_deferred()
	
func canFocusCarry() -> bool:
	return not exploded

func onCarried(keeper:Keeper):
	deactivate()

func deactivate():
	if sticks:
		freeze = false
		$Adhesion.visible = false
	sticks = false
	activated = false
	untilExplosion = 0.0
	$Sprite2D.play("normal" + animationSuffix)
	$ActivateSound.stop()
	$HotBombSound.stop()
	$CountdownSound.stop()
	$StickToWallSound.stop()
	contact_monitor = false

func activate():
	if Data.of("blastMining.stickyCharge"):
		maxUntilExplosion = 1.5
		untilExplosion = maxUntilExplosion
		$StickToWallSound.play()
	else:
		maxUntilExplosion = 3.0
		untilExplosion = maxUntilExplosion
		$ActivateSound.play()
	activated = true
	$Sprite2D.play("activated" + animationSuffix)
	$CountdownSound.play()

func onDropped(keeper:Keeper):
	if Data.of("blastMining.explodeOnImpact"):
		contact_monitor = true
	elif Data.of("blastMining.stickyCharge"):
		contact_monitor = true
	else:
		activate()

func _physics_process(delta):
	if GameWorld.paused or exploded:
		return
	
	# impact detonation explodes when resting on resources
	var explodeOnImpact = Data.of("blastMining.explodeOnImpact")
	if explodeOnImpact and not isCarried():
		if activated:
			if (linear_velocity - lastVelocity).length() > 15:
				explode(lastVelocity.normalized())
				$HotBombSound.stop()
		elif linear_velocity.length() > 20:
			activated = true
			$Sprite2D.play("activated" + animationSuffix)
			$HotBombSound.play()
	
	lastVelocity = linear_velocity
	
	if not activated:
		return
	
	if not explodeOnImpact:
		if untilExplosion > 0.0:
			untilExplosion -= delta
			$Sprite2D.speed_scale = 0.3 + 1.7 * (1.0 - untilExplosion / maxUntilExplosion)
		else:
			explode()

func getStickToDirection() -> Vector2:
	var delta = stickingTo - global_position
	if abs(delta.x) > abs(delta.y):
		delta.y = 0
	else:
		delta.x = 0
	return delta

func explode(direction := Vector2.ZERO):
	$ActivateSound.stop()
	var ex = load("res://content/gadgets/blastMining/Explosion.tscn").instantiate()
	ex.position = position
	match animationSuffix:
		"_0": ex.bangType  = ""
		"_1": ex.bangType  = ""
		"_2": ex.bangType  = "Upgrade1"
		"_3": ex.bangType  = "Upgrade2"
		"_4": ex.bangType  = "Upgrade3"
		"_100": ex.bangType  = "Tech"
	get_parent().add_child(ex)
	if Level.map:
		if sticks:
			var delta = getStickToDirection()
			var dist = round(2.0 * pow(Data.of("blastMining.radius"), 1.6))
			Level.map.damageTileDirection(global_position, delta.normalized(), dist, Data.of("blastMining.damage"), 0.1)
		else:
			var radius = Data.of("blastMining.radius")
			var offset = direction * radius * 0.8 * GameWorld.TILE_SIZE
			Level.map.damageTileCircleArea(global_position, radius, Data.of("blastMining.damage"), 0.1, offset)
	exploded = true
	deactivated = true
	Backend.event("gadget_used", {"gadget": "blastMining"})
	GameWorld.incrementRunStat("blastcharges_used")
	queue_free()

func _on_Mine_body_entered(body):
	if not body.has_meta("destructable") or not body.get_meta("destructable"):
		return
	
	if not sticks and Data.of("blastMining.stickyCharge"):
		changeToStatic.call_deferred()
		sticks = true
		stickingTo = body.global_position
		$Adhesion.visible = true
		var delta = getStickToDirection()
		$Adhesion.rotation = delta.angle() - rotation
		activate()
		return

func changeToStatic() -> void:
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	freeze = true
