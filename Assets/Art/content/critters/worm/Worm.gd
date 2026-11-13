extends Node2D

var tween: DeprecatedTween = DeprecatedTween.new()
var tile = null

const MIN_DISTANCE_FROM_KEEPER = 50

func _ready():
	add_child(tween)
	$AnimatedSprite2D.play("appear")
	
	$deathTimer.wait_time = randf_range(5, 20)
	$deathTimer.start()
	
	Style.init(self)
	$Spawn.play()
	
	tile.connect("destroyed", Callable(self, "die"))

func die():
	$AnimatedSprite2D.play("disappear")
	$Despawn.play()

func _on_deathTimer_timeout():
	die()

func _physics_process(delta):
	for keeper in Keepers.getAll():
		if keeper.global_position.distance_to(global_position) < MIN_DISTANCE_FROM_KEEPER:
			die()
			return
		
	if not is_instance_valid(tile):
		die()

func _on_animated_sprite_2d_animation_looped() -> void:
	_AnimatedSpriteAnimationFinishedCheck()

func _on_AnimatedSprite_animation_finished() -> void:
	_AnimatedSpriteAnimationFinishedCheck()

func _AnimatedSpriteAnimationFinishedCheck() -> void:
	if $AnimatedSprite2D.animation == "appear":
		$AnimatedSprite2D.play("idle")
		$AnimatedSprite2D.frame = randi() % 8
		
	if $AnimatedSprite2D.animation == "disappear":
		queue_free()


