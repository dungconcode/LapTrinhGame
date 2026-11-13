extends Node2D

enum State {HIDE, GROW, IDLE, WALK, DIE}
var state: int = State.GROW

var cooldown := 0.0
var walktime := 0.0

func _ready():
	Style.init(self)
	$Sprite2D.play("idle")

func start(startTile):
	$Tween.interpolate_callback(self, 60 + 60*randf(), "die")
	$Tween.start()

func _physics_process(delta):
	if not $GroundDetector.is_colliding():
		die()
		return
	
	if shouldShrink():
		shrink()
	
	if cooldown > 0.0:
		cooldown -= delta
		return
	
	match state:
		State.HIDE:
			if shouldGrow():
				state = State.GROW
			cooldown = 1.0
		State.GROW:
			$Sprite2D.play("grow")
			cooldown = 1.0
			state = State.IDLE
		State.WALK:
			if not $Sprite2D.animation.begins_with("walk_"):
				$Sprite2D.play("walk_left" if $EdgeDetector.position.x < 0 else "walk_right")
			if $EdgeDetector.is_colliding() and not $WallDetector.is_colliding():
				position.x += $EdgeDetector.position.x * delta * 5
				walktime += delta
				if walktime > 2.0 and randf() > 0.9:
					state = State.IDLE
					$Sprite2D.play("idle")
			else:
				state = State.IDLE
				$Sprite2D.play("idle")
		State.IDLE:
			cooldown = 1.5 + randf() * 3.0
			if randf() > 0.5:
				flip()
			state = State.WALK
			walktime = 0.0

func shouldGrow() -> bool:
	for keeper in Keepers.getAll():
		var distanceToKeeper = global_position - keeper.global_position
		if distanceToKeeper.length() <  GameWorld.TILE_SIZE * 4.5:
			return false
	return true

func shouldShrink() -> bool:
	for keeper in Keepers.getAll():
		var distanceToKeeper = global_position - keeper.global_position
		if distanceToKeeper.length() <  GameWorld.TILE_SIZE * 2.4:
			return true
	return false

func shrink():
	if state != State.HIDE:
		state = State.HIDE
		$Sprite2D.play("shrink")

func flip():
	$EdgeDetector.position.x = -$EdgeDetector.position.x
	$WallDetector.rotation += PI

func _on_sprite_2d_animation_looped() -> void:
	_SpriteAnimationFinishedCheck()

func _on_Sprite_animation_finished() -> void:
	_SpriteAnimationFinishedCheck()

func _SpriteAnimationFinishedCheck() -> void:
	$Sprite2D.speed_scale = 1.0
	match $Sprite2D.animation:
		"shrink":
			if state == State.DIE:
				queue_free()
			else:
				animateShrunken()
		"hidden":
			animateShrunken()
		"twinkle":
			animateShrunken()
		"grow":
			$Sprite2D.play("idle")

func animateShrunken():
	for keeper in Keepers.getAll():
		var distanceToKeeper = global_position - keeper.global_position
		if distanceToKeeper.length() < GameWorld.TILE_SIZE * 2:
			# if a keeper is close, keep eyes closed
			$Sprite2D.play("hidden")
			return
	# no keeper is close
	$Sprite2D.play("twinkle")
	$Sprite2D.speed_scale = 0.5 + 0.5 * randf()

func die():
	if state != State.DIE:
		state = State.DIE
		$Sprite2D.play("shrink")


