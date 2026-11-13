extends Carryable

var activated := false
var untilExplosion := 0.0
var maxUntilExplosion := 0.0
var exploded := false
var lastVelocity

func _ready():
	super._ready()
	Style.init($CarrySprite)
	Style.init($FocusSprite)
	$Sprite2D.play("normal")

func serialize()->Dictionary:
	var data = super.serialize()
	data["activated"] = activated
	data["untilExplosion"] = untilExplosion
	data["maxUntilExplosion"] = maxUntilExplosion
	data["exploded"] = exploded
	return data
	
func deserialize(data: Dictionary):
	super.deserialize(data)
	activated = data["activated"]
	untilExplosion = data["untilExplosion"]
	maxUntilExplosion = data["maxUntilExplosion"]
	exploded = data["exploded"]
	
	if activated:
		activate()
	else:
		deactivate()
		
	if exploded:
		queue_free()
	
func canFocusCarry() -> bool:
	return not exploded

func onCarried(keeper:Keeper):
	deactivate()

func deactivate():
	activated = false
	untilExplosion = 0.0
	$Sprite2D.play("normal")
	$ActivateSound.stop()

func activate():
	maxUntilExplosion = 3.0
	untilExplosion = maxUntilExplosion
	activated = true
	$Sprite2D.play("activated")
	$ActivateSound.play()

func onDropped(keeper:Keeper):
	activate()

func _physics_process(delta):
	if GameWorld.paused or exploded:
		return
	
	if not activated and not isCarried():
		if linear_velocity.length() > 20:
			activated = true
			$Sprite2D.play("activated")
			$ActivateSound.play()
	
	if not activated:
		return
	
	lastVelocity = linear_velocity
	if untilExplosion > 0.0:
		untilExplosion -= delta
		$Sprite2D.speed_scale = 0.3 + 1.7*(1.0 - untilExplosion / maxUntilExplosion)
		$CountdownSound.play()
	else:
		explode()

func explode():
	$ActivateSound.stop()
	if Level.map:
		for dir in CONST.DIRECTIONS:
			Level.map.damageTileDirection(global_position, dir.normalized(), 30, 10000, 0.1)
			var ex = load("res://content/caves/bombcave/ExplosionCaveBomb.tscn").instantiate()
			ex.position = position + dir * GameWorld.TILE_SIZE * 0.75
			get_parent().add_child(ex)
			if not exploded:
				ex.playSound()
				exploded = true
	deactivated = true
	queue_free()
