extends Area2D

signal exhausted

var done := false
var remainingHp:int

func _ready():
	Style.init(self)

func init(delay, offsetY, hp):
	var oldPos = position
	position += Vector2.DOWN.rotated(rotation) * offsetY
	var duration = 0.6 + randf() * 0.4
	remainingHp = hp
	$Sprite2D.frame = 0
	$Tween.interpolate_property(self, "position", position, oldPos, duration, Tween.TRANS_QUAD, Tween.EASE_OUT, delay)
	$Tween.interpolate_callback($Sprite2D, delay, "play", "default")
	$Tween.start()

func serialize()->Dictionary:
	var data = {}
	data["meta.priority"] = 100
	data["meta.kind"] = "generic"
	data["remainingHp"] = remainingHp
	return data

func deserialize(data: Dictionary):
	remainingHp = data["remainingHp"]
	if remainingHp <= 0:
		dissolve()
	else:
		$Sprite2D.play("default",10)

func _on_Shield_area_entered(area):
	if done:
		return
	
#	$ReflectSound.play()
	
	area.domeAbsorbsDamage()
	
#	$Tween.interpolate_property($Base, "modulate", Color.white*10, Color.white, 0.3, Tween.TRANS_QUAD, Tween.EASE_OUT)
#	$Tween.start()
	remainingHp -= area.damage
	if remainingHp <= 0:
		dissolve()

func dissolve(delay := 0.0):
	if delay > 0.0:
		$Tween.interpolate_callback(self, delay, "dissolve")
		$Tween.start()
		return
	
	if done:
		return
	
	done = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	emit_signal("exhausted")
	
	var goalPos = position + Vector2.DOWN.rotated(rotation) * 40
	modulate.r = 0.4
	modulate.g = 0.4
	modulate.b = 0.4
	$Sprite2D.play("shrivel")
	$Tween.interpolate_property(self, "position", position, goalPos, 0.4, Tween.TRANS_QUAD, Tween.EASE_IN, 0.2)
	$Tween.interpolate_callback(self, 0.6, "queue_free")
	$Tween.start()

func pauseChanged():
	if GameWorld.paused:
		$Tween.stop_all()
	else:
		$Tween.resume_all()

func onGameLost():
	dissolve()
