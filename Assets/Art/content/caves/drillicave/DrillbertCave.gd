extends "res://content/caves/Cave.gd"

@onready var DrillMother = find_child("Drillmother")

var cooldown := 0.0
var sleeping := true
var woke := false
var triggered := false
var looking := false
var transitioning := false
var triggerCount := 0

func _ready():
	super._ready()
	Level.map.addSpriteToBGAlpha($AlphaMap)

func _process(delta):
	if currentState == State.REVEALED:
		if triggered or transitioning:
			return
		
		if cooldown > 0.0:
			cooldown -= delta
			return
		
		var keeperDist:float = 999990.0
		for keeper in Keepers.getAll():
			keeperDist = min(keeperDist, (keeper.global_position - DrillMother.global_position).length())

		var minTreatDist := 999
		for treat in get_tree().get_nodes_in_group("treat"):
			minTreatDist = min(minTreatDist, (DrillMother.global_position - treat.global_position).length()) 
		
		var minDrillbertDist := 999
		for drillbert in get_tree().get_nodes_in_group("drillbots"):
			minDrillbertDist = min(minDrillbertDist, (DrillMother.global_position - drillbert.global_position).length()) 
		
		if (minTreatDist < 100 or minDrillbertDist < 100) and sleeping and not triggered:
			DrillMother.play("wake")
			find_child("RaiseSound").play()
			find_child("SleepingLoop").stop()
			transitioning = true
			return
		
		if woke and minTreatDist > 140 and minDrillbertDist > 140:
			DrillMother.play("liedown")
			find_child("LieDownSound").play()
			find_child("SleepingLoop").play()
			transitioning = true
			return
		
		if sleeping:
			if looking:
				if keeperDist > 100:
					transitioning = true
					DrillMother.play("closeeyes")
					find_child("SleepingLoop").play()
			else:
				if keeperDist < 60:
					transitioning = true
					DrillMother.play("openeyes")
					find_child("LookingSound").play()
					find_child("SleepingLoop").stop()

func onRevealed():
	DrillMother.play("sleeping")
	find_child("SleepingLoop").play()

func _on_drillmother_animation_looped() -> void:
	_animationFinishedCheck()

func _on_Drillmother_animation_finished() -> void:
	_animationFinishedCheck()

func _animationFinishedCheck() -> void:
	transitioning = false
	match DrillMother.animation:
		"openeyes":
			looking = true
		"closeeyes":
			DrillMother.play("sleeping")
			looking = false
		"liedown":
			DrillMother.play("sleeping")
			sleeping = true
			looking = false
			woke = false
		"wake":
			DrillMother.play("idle")
			sleeping = false
			woke = true
		"eat":
			if triggerCount == 0:
				GameWorld.runModifiersToUnlock.append("drillbert")
			triggerCount += 1
			cooldown = 60 * triggerCount
			triggered = false
			woke = false
			sleeping = true
			$ResourceGrabber.spent = false
			DrillMother.play("sleeping")
			find_child("SleepingLoop").play()

func _on_ResourceGrabber_grabbed_resource():
	triggered = true
	DrillMother.play("eat")
	find_child("EatSound").play()

func spawnDrillbot():
	var drillbot = preload("res://content/gadgets/drillbot/Drillbot.tscn").instantiate()
	drillbot.position = find_child("DropPosition").global_position
	Level.map.addDrop(drillbot)
	drillbot.gravity_scale = 0.0
	drillbot.stableTime = -1.0
	drillbot.apply_central_impulse(Vector2(-30, -2))
	drillbot.setDirection(Vector2.LEFT)
	drillbot.normalMode()
	drillbot.startFalling(false)
	
	var dsprite = drillbot.find_child("Sprite2D")
	dsprite.modulate = Color(0.1, 0.1, 0.1, 1.0)
	dsprite.scale *= 0.0
	$Tween.interpolate_property(dsprite, "modulate", dsprite.modulate, Color.WHITE, 0.9, Tween.TRANS_QUAD, Tween.EASE_IN)
	$Tween.interpolate_property(dsprite, "scale", dsprite.scale, Vector2.ONE, 1.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	$Tween.interpolate_callback(drillbot, 1.0, "set", "gravity_scale", 1.0)
	$Tween.interpolate_callback(drillbot, 1.0, "apply_central_impulse", Vector2(randf_range(-60, -10), randf_range(-100,-250)))
	$Tween.start()

func _on_Drillmother_frame_changed():
	if triggered and (DrillMother.frame == 13 or DrillMother.frame == 30):
		spawnDrillbot()
