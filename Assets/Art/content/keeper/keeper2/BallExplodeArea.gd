extends "res://content/keeper/keeper2/BallHandlerArea.gd"

var catching := false
var inCooldown := false
var ballsExploded:int

func _ready() -> void:
	super._ready()


func start(playerId):
	self.playerId = playerId
	Data.listen(self, playerId + ".keeper2.explodespheres", true)
	$Sprite2D.visible = false

func propertyChanged(property:String, oldValue, newValue):
	if not is_physics_processing() and newValue:
		visible = true
		Level.addTutorial(self, "assessor2_explode")
		$BallCatchCollision.disabled = false
		set_physics_process(newValue)

func _physics_process(delta):
	if GameWorld.paused:
		return
	
	if catching:
		var exploded := false
		for ball in get_overlapping_bodies():
			ball.explode(playerId)
			ballsExploded += 1
			exploded = true
		if exploded:
			match int(Data.of(playerId + ".keeper2.actionstage")):
				1:
					if not $ExplodeTrigger.playing:
						$ExplodeTrigger.play()
				2: 
					if not $ExplodeTriggerUpgrade.playing:
						$ExplodeTriggerUpgrade.play()
	elif inCooldown:
		if get_parent().ballActionCooldown <= 0.0:
			inCooldown = false
			$ExplodeReady.play()
			$Tween.interpolate_method(self, "setRadius", $BallCatchCollision.shape.radius, 0, 0.5, Tween.TRANS_QUAD, Tween.EASE_IN)
			$Tween.start()
	else:
		$Sprite2D.visible = false

func explode():
	ballsExploded = 0
	var radius = 60
	get_parent().ballActionCooldown = Data.of(playerId + ".keeper2.actioncooldown")
	catching = true
	inCooldown = true
	$Sprite2D.visible = true
	$Tween.interpolate_method(self, "setRadius", $BallCatchCollision.shape.radius, radius, 0.1, Tween.TRANS_QUART, Tween.EASE_OUT)
	$Tween.interpolate_method(self, "setRadius", radius, 16, 0.8, Tween.TRANS_BACK, Tween.EASE_IN, 0.7)
	$Tween.interpolate_callback(self, 1.0, "disable")
	$Tween.start()
	match Data.of(playerId + ".keeper2.actionstage"):
		1: $ExplodeOn.play()
		2: $ExplodeOnUpgrade.play()

func disable():
	catching = false
	if ballsExploded == 0:
		get_parent().ballActionCooldown *= 0.15
	elif ballsExploded >= 3:
		Achievements.triggerIfOpen("KEEPER2_EXPLODE")
	$ExplodeOff.play()

func setRadius(radius:float):
	$BallCatchCollision.shape.radius = radius
	$Sprite2D.material.set_shader_parameter("pixelation_factor", radius * 2)
	$Sprite2D.scale = Vector2(1.2, 1.2) / ($Sprite2D.texture.get_size() / (radius * 2))

func pauseChanged():
	if GameWorld.paused:
		$Tween.stop_all()
	else:
		$Tween.resume_all()
