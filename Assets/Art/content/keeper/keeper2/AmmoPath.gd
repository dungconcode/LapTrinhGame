extends Node2D

var currentRotation := 0.0
var playerId:String
const RELOAD_EFFECT_TIME = 5.0

func start(playerId):
	self.playerId = playerId
	Data.listen(self, playerId + ".keeper2.remainingspheres")

func propertyChanged(property:String, oldValue, newValue):
	var childCount = $AmmoPath.get_child_count()
	if newValue > childCount:
		while newValue > childCount:
			var ammo = preload("res://content/keeper/keeper2/Ammo.tscn").instantiate()
			if childCount > 0:
				ammo.progress_ratio = fmod(currentRotation + 1.0 / float(childCount), 1.0)
			$AmmoPath.add_child(ammo)
			ammo.find_child("AnimatedSprite2D").play()
			Style.init(ammo)
			childCount += 1
	elif newValue < childCount and childCount > 0:
		while childCount > newValue:
			$AmmoPath.get_child(0).queue_free()
			childCount -= 1


@onready var reload_sphere = $ReloadSphere
var reload_rotation := 0.0
func _process(delta):
	var relativeMove = get_parent().move / float(get_parent().currentSpeed())
	relativeMove *= pow(relativeMove.length(), 2)
	var goalPos = relativeMove * -20
	var moveDelta = (goalPos - position).limit_length(4.0)
	position += moveDelta * 5 * delta
	scale = scale - (scale - Vector2.ONE * max(0.2, (1.0 - relativeMove.length()))) * delta * 2.0
	
	currentRotation += delta * 0.25 * (max(0.0, 1.0 - position.length() * 0.033))
	currentRotation = wrapf(currentRotation, 0.0, 1.0)
	
#	if get_parent().ballCharge > thresh:
#		var alpha = ((get_parent().ballCharge-thresh) * 1.0/(1.0-thresh)) * 1.0
#		$AmmoSpin.modulate.a = ease(alpha, 2.0)
#		$AmmoPath.modulate.a = 1.0 - ease(alpha, 2.0)
#		$AmmoSpin.play("spin")
#		$AmmoSpin.show()
#		$AmmoSpin.rotation = -currentRotation * TAU
#	else:
	$AmmoPath.modulate.a = 1.0
	$AmmoSpin.hide()
	
	var childCount = $AmmoPath.get_child_count()
	var goalOffset := 0.0
	if childCount > 0:
		var step = 1.0 / float(childCount)
		for i in range(0, childCount):
			var child = $AmmoPath.get_child(i)
			child.scale = Vector2.ONE / scale
			goalOffset = fmod(currentRotation + step * i, 1.0)
			var offsetDelta = goalOffset - child.progress_ratio
			if offsetDelta < 0.0:
				offsetDelta += 1.0
			child.progress_ratio += offsetDelta * delta * 2.0
	
	reload_sphere.hide()
	reload_sphere.scale = Vector2(1.0/scale.x, 1.0/scale.y)
	
	var remainingShots = Data.of(playerId + ".keeper2.remainingspheres")
	if remainingShots < Data.of(playerId + ".keeper2.totalspheres"):
		var reloadCounter = max(1.0, Data.ofOr(playerId + ".keeper2.currentspherereload", 0.0))
		reloadCounter += delta
		var time_remaining = Data.of(playerId + ".keeper2.spherereload") - reloadCounter
		var os_ticks : float = float(Time.get_ticks_msec())
		
		if time_remaining < RELOAD_EFFECT_TIME:
			var reload_progress : float = -(time_remaining-RELOAD_EFFECT_TIME)/RELOAD_EFFECT_TIME
			reload_sphere.show()
			reload_sphere.global_rotation = TAU * fmod(os_ticks/500, 1.0)
			reload_sphere.scale = Vector2.ONE * (reload_progress*0.5+0.5)
			reload_sphere.modulate.a = ease(reload_progress, 0.8)
			var distance : float = 22 + 2 * sin(os_ticks / 166.0)
			if time_remaining < 1:
				distance *= (ease(time_remaining, .3)*0.35)+0.65
			var speed : float = max(3.0 * reload_progress-0.4, 0.0)
			reload_rotation = wrapf(reload_rotation+delta*speed, 0.0, TAU)
			var rot : float = reload_rotation + (goalOffset*TAU) + PI/2
			reload_sphere.position = Vector2.UP.rotated(rot) * distance
