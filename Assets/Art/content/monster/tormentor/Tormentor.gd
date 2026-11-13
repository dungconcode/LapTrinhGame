extends "res://content/monster/Monster.gd"

enum Phase {WALK, TRANSFORM_TO_BEAM, BEAM, DIE}

var phase:int = Phase.WALK
var walking := true
var beaming := false
var damageSum := 0.0
const damageUnit := 2.0

var path:Path2D
var meleeTarget:Path2D
var meleeTargetLength:float
var beamNoise := FastNoiseLite.new()
var beamNoiseTime := 0.0
var progress := 0.0
var lastDelta:float
var goalProgress:float

var lastWalkFrame := 0

@onready var tormentorBeam = $TormentorBeam
@onready var beamEndParticle = $BeamEndParticle
@onready var beamStartParticle = $BeamStartParticle


func init():
	beamNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	position = path.curve.sample_baked(0) + path.global_position
	var d = position.x - (path.curve.sample_baked(50).x + path.global_position.x)
	lastDelta = -d
	setFlip(d > 0.0)
	$Sprite2D.play("walk")
	updateHitboxState()
	$Sprite2D.speed_scale = speedModifier
	$EnterSound.play()

func subProcess(delta):
	if walking:
		# the tormentor takes really big steps, so just smoothly increasing progress looks weird
		# with 12 frames, to get an average of 1 across the walk cycle, the speed during step needs to be 1.5
		# doing it dynamically is bad but if we adjust the walk cycle, there's a formula for getting the correct speedMod
		var speedMod:float
#		var stopFrames := [2, 1, 7]
#		var smoothFrames := [3,8,0]
#		var walkFrames := [4,5,6,9,10,11]
		if ($Sprite2D.frame >= 4 and $Sprite2D.frame <= 6) or ($Sprite2D.frame >= 9 and $Sprite2D.frame <= 11):
			speedMod = 1.5
#			speedMod = 1.0 + (float(smoothFrames.size()) / walkFrames.size())
		elif $Sprite2D.frame == 3 or $Sprite2D.frame == 8 or $Sprite2D.frame == 0:
			speedMod = 1.0
		else:
			speedMod = 0.0
		progress += delta * Data.of("tormentor.speed") * $Sprite2D.speed_scale*speedMod
		var cp = meleeTarget.curve.get_closest_point($HitPosition.global_position)
		if sign(lastDelta) != sign(cp.x - $HitPosition.global_position.x):
			phase = Phase.TRANSFORM_TO_BEAM
			animation("transform_to_beam")
			walking = false
		else:
			position = path.curve.sample_baked(progress) + path.global_position
	elif beaming:
		damageSum += Data.of("tormentor.damage") * delta
		if damageSum >= damageUnit:
			damageSum -= damageUnit
			Level.dome.requestBeamDamage(damageUnit * damageModifier, beamEndParticle.global_position, self)
			InputSystem.shake(20, 0.2, 8)
		
		var noiseSpeed = 50.0
		if randf() > 0.9:
			noiseSpeed = 1500.0
		beamNoiseTime += delta*noiseSpeed
		
		phase = Phase.BEAM
		var newTarget:Vector2 = meleeTarget.curve.sample_baked(meleeTargetLength * (beamNoise.get_noise_1d(beamNoiseTime)*0.5 + 0.5))
		tormentorBeam.target = lerp(tormentorBeam.target, newTarget, delta*24.0)
		tormentorBeam.show()
		beamEndParticle.global_transform = tormentorBeam.end.global_transform
		beamEndParticle.emitting = true
		beamStartParticle.emitting = true


func onGameLost():
	if currentHealth <= 0:
		return
	if walking:
		leaving = true
		animation("walk")
		$Sprite2D.speed_scale = 0.9 + randf() * 0.5
		setFlip(not $Sprite2D.flip_h)
	else:
		animateDeath()

func animateDeath():
	setBeaming(false)
	if phase == Phase.BEAM: # one frame of beam + death flash, will call back to animateDeath when it ends
		animation("die_beam")
		phase = Phase.DIE
		return
	phase = Phase.DIE
	if walking:
		animation("die_walk")
	else:
		animation("die_upright")
	$DieSound.play()

# controls when the beam is actually emitting
# is distinct from the BEAM phase as that includes getting staggered during beam
func setBeaming(value:bool):
	beaming = value
	if beaming:
		animation("beam")
		$BeamSound.play()
		$BeamStartSound.play()
		meleeTargetLength = meleeTarget.curve.get_baked_length()
	else:
		tormentorBeam.hide()
		beamEndParticle.emitting = false
		beamStartParticle.emitting = false
		$BeamSound.stop()

func _on_sprite_2d_animation_looped() -> void:
	_animationFinishedCheck()	

func _on_Sprite_animation_finished() -> void:
	_animationFinishedCheck()

func _animationFinishedCheck() -> void:
	if $Sprite2D.animation == "die_beam":
		animateDeath()
	elif $Sprite2D.animation == "beam_hit" or $Sprite2D.animation == "transform_to_beam":
		setBeaming(true)
	elif $Sprite2D.animation == "die_upright":
		super.removeFreeBlocker()
	elif $Sprite2D.animation == "die_walk":
		super.removeFreeBlocker()


func _on_Sprite_frame_changed():
	match $Sprite2D.animation: 
		"transform_to_beam":
			currentHealth = min(currentHealth, maxHealth * (1.0 - $Sprite2D.frame / 53.0)) # should end up at about 23% of max health after fully transforming. Changing the animation length needs adjustment here. 41/51 is roughly 0.8
			if $Sprite2D.frame == 5:
				$TransformSound.play()
				# currently the beam anim is baked into the sheet, so slowing down the playback while beaming looks really weird and doesn't even do anything bc of the default min stun level of 0.2
				minStunLevel = 1.0
				stunPriority = 0
			elif $Sprite2D.frame == 10:
				hitboxToEnable.append($HitboxBeam)
			elif $Sprite2D.frame == 22:
				hitboxToDisable.append($HitboxDefault)


