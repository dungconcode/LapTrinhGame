extends Node2D
class_name Laser

@onready var hitEffect: AnimatedSprite2D = $HitEffect
var endpoint: Vector2: get = get_endpoint, set = set_endpoint

func _ready():
	if has_node("MuzzleFlash"):
		$MuzzleFlash.play("glow")
	Style.init(self)

func target(pos):
	set_endpoint(pos)
	
func get_endpoint():
	return endpoint
	
func set_endpoint(value):
	endpoint = value
	for child in get_children():
		if child is Sprite2D:
			(child as Sprite2D).region_rect.size.x = endpoint.length()
			
func start():
	for child in get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			child.show()
	if has_node("Burst"):
		$Burst.frame = 0
		$Burst.play("kapow")
	if not $FireSound.playing:
		$FireSound.play()
	$FireSoundInit.play()

func stop():
	for child in get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			child.hide()
	$FireSoundInit.stop()
	$FireSound.stop()
	
	$FireSoundStop.play()
	stop_hit()
	
func start_hit(where):
	hitEffect.position = where
	hitEffect.play()
	$HitParticles.position = where
	if not $HitParticles.emitting:
		$HitParticles.emitting = true
		hitEffect.visible = true
		$FireMonsterHit.play()
	
func stop_hit():
	$HitParticles.emitting = false
	hitEffect.visible = false
	$FireMonsterHit.stop()
	hitEffect.pause()

func playHitBumpSound():
	if not $HitParticles.emitting:
		$FireMonsterBump.play()
	
