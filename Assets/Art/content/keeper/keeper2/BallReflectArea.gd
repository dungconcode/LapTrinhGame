extends "res://content/keeper/keeper2/BallHandlerArea.gd"

var lifetime:float
var done:bool
var remainingFreeBlockers := 2

func _ready():
	super._ready()
	$AnimatedSprite2D.visible = true
	$AnimatedSprite2D.play("reflect")
	$Ambience.play()
	Style.init(self)
	set_physics_process(true)

func _physics_process(delta):
	if GameWorld.paused:
		return
	
	if done:
		if remainingFreeBlockers <= 0:
			queue_free()
		return
	
	lifetime -= delta
	if lifetime <= 0:
		done = true
		$ReflectionOff.play()
		$BallReflectCollision.set_deferred("disabled", true)
		$Tween.interpolate_property($AnimatedSprite2D, "scale", $AnimatedSprite2D.scale, Vector2.ZERO, 0.2, Tween.TRANS_QUAD, Tween.EASE_IN)
		$Tween.interpolate_callback(self, 0.2, "removeFreeBlocker")
		$Tween.start()
		return
	
	$AnimatedSprite2D.rotation = randf() * TAU
	
	var play := false

	for sphere in approachingSpheres:
		if not handledSpheres.has(sphere):
			sphere.reflect()
			handledSpheres.append(sphere)
			play = true
	
	if play:
		var time = 0.06
		$Tween.interpolate_property($AnimatedSprite2D, "scale", $AnimatedSprite2D.scale, Vector2.ONE*0.6, time, Tween.TRANS_QUAD, Tween.EASE_OUT)
		$Tween.interpolate_property($AnimatedSprite2D, "scale", Vector2.ONE*0.6,Vector2.ONE*1.25, time, Tween.TRANS_QUAD, Tween.EASE_IN, time)
		$Tween.interpolate_property($AnimatedSprite2D, "scale", Vector2.ONE*1.25,Vector2.ONE*1.0, time, Tween.TRANS_QUAD, Tween.EASE_IN, time * 2)
		$Tween.start()

func spherePassed(sphere):
	super.spherePassed(sphere)
	handledSpheres.erase(sphere)

func _on_BallReflectArea_body_entered(body):
	if not approachingSpheres.has(body) and body.timeAlive < 0.05:
		# ball spawned within reflect area
		handledSpheres.append(body)

func _on_BallReflectArea_body_exited(body):
	spherePassed(body)

func removeFreeBlocker():
	remainingFreeBlockers -= 1

func _on_ReflectionOff_finished():
	removeFreeBlocker()
