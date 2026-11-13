extends RigidBody2D

enum State { SEARCH, EAT, SCATTER }
var state: int = State.SEARCH
var tween: DeprecatedTween = DeprecatedTween.new()

const MIN_DISTANCE_FROM_KEEPER = 70
const MOVE_SPEED = 30

var direction: Vector2
var tile_normal: Vector2
var wall_normal: Vector2
var touching_wall = false
var touching_floor = false

func _ready():
	add_child(tween)
	Style.init(self)
	$deathTimer.wait_time = randf_range(40,120)
	$deathTimer.start()
	$AnimatedSprite2D.play("appear")

func die():
	gravity_scale = 0
	$AnimatedSprite2D.play("disappear")

func _on_deathTimer_timeout():
	change_state(State.SCATTER)

#func _draw():
#	draw_line(Vector2(0,0), tile_normal * 15, Color(1, 0, 0), 2)
#	draw_line(Vector2(0,0), wall_normal * 15, Color(0, 1, 0), 2)
	
func _physics_process(delta):
	var facing = Vector2.ZERO
	facing = linear_velocity if linear_velocity.length() > 1 else Vector2.ZERO
	if facing.length():
		$AnimatedSprite2D.global_rotation = 0
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = false
		
		if facing.x < 0:
			# Left
			$AnimatedSprite2D.global_rotation = 0
			$AnimatedSprite2D.flip_v = false
			$AnimatedSprite2D.flip_h = true
		
		if facing.x >= 0:
			# Right
			$AnimatedSprite2D.global_rotation = 0
			$AnimatedSprite2D.flip_v = false
			$AnimatedSprite2D.flip_h = false
			
		if facing.y <= 0:
			# Up
			if wall_normal.x > 0:
				# Right wall
				$AnimatedSprite2D.global_rotation = -PI/2
				$AnimatedSprite2D.flip_v = false
				$AnimatedSprite2D.flip_h = false
			elif wall_normal.x < 0:
				# Left wall
				$AnimatedSprite2D.global_rotation = -PI/2
				$AnimatedSprite2D.flip_v = true
				$AnimatedSprite2D.flip_h = false

		if facing.y > 0:
			# Down
			if wall_normal.x > 0:
				# Right wall
				$AnimatedSprite2D.global_rotation = -PI/2
				$AnimatedSprite2D.flip_v = false
				$AnimatedSprite2D.flip_h = true
			elif wall_normal.x < 0:
				# Left wall
				$AnimatedSprite2D.global_rotation = -PI/2
				$AnimatedSprite2D.flip_v = true
				$AnimatedSprite2D.flip_h = true

	#printt(direction, state, linear_velocity, touching_wall)
	if state != State.SCATTER:
		if linear_velocity.length() < 0.1:
			$AnimatedSprite2D.play("idle")
		else:
			$AnimatedSprite2D.play("crawl")

	match state:
		State.SEARCH:
			if linear_velocity.length() < randf_range(5,20):
				apply_central_impulse(direction * MOVE_SPEED)
			if touching_wall:
				for keeper in Keepers.getAll():
					if keeper.global_position.distance_to(global_position) < MIN_DISTANCE_FROM_KEEPER:
						change_state(State.SCATTER)
						return
		State.EAT:
			if touching_wall:
				for keeper in Keepers.getAll():
					if keeper.global_position.distance_to(global_position) < MIN_DISTANCE_FROM_KEEPER:
						change_state(State.SCATTER)
						return
		State.SCATTER:
			if not $VisibleOnScreenNotifier2D.is_on_screen():
				queue_free()
			if linear_velocity.length() < 5:
				die()

func _on_decisionTimer_timeout():
	if state == State.SCATTER:
		return
	
	change_state(State.SEARCH)
	if wall_normal.y > 0 or tile_normal.y > 0:
		# On floor
		if randf() < 0.2:
			change_state(State.EAT)
		elif randf() < 0.5:
			direction = Vector2(1,0)
		else:
			direction = Vector2(-1,0)
	elif wall_normal.y < 0:
		# On ceiling
		direction = Vector2(0,1)
	else:
		# On wall (go up)
		direction = Vector2(0,-1)
		
func _integrate_forces(state):
	# tile_normal helps the rats get around corners	
	if state.get_contact_count():
		for i in range(state.get_contact_count()):
			tile_normal = -state.get_contact_local_normal(i)
			if abs(tile_normal.y) == 0:
				break
	else:
		if tile_normal.length():
			apply_central_impulse((tile_normal + Vector2(0, randf_range(-0.5, 0))) * MOVE_SPEED)
		tile_normal = Vector2.ZERO

	# wall_normal stabilizes the rats animations and facing
	var normals := []
	wall_normal = Vector2.ZERO
	touching_floor = false
	if $RayCastUp.is_colliding():
		touching_wall = false
		direction = Vector2.ZERO
	else:
		if $RayCastRight.is_colliding():
			touching_wall = true
			normals.append(Vector2(1, 0))
		if $RayCastLeft.is_colliding():
			touching_wall = true
			normals.append(Vector2(-1,0))
		if $RayCastFloor.is_colliding():
			touching_wall = true
			touching_floor = true
			normals.append(Vector2(0,1))

	if normals.size() and touching_wall:
		normals.shuffle()
		wall_normal = normals[0]
	else:
		touching_wall = false
		wall_normal = Vector2.ZERO

	if tile_normal.length() == 0 and wall_normal.length() == 0:
		direction = Vector2.ZERO
		
func _on_Rat_body_entered(body):
	if state == State.SCATTER:
		# Tunnel away if in SCATTER mode and touching a tile
		die()

func change_state(new_state: int):
	if randf() < 0.3:
		$Squeal.play()
		
	state = new_state
	match state:
		State.SEARCH:
			# Seek a nearby drop
			$AnimatedSprite2D.play("crawl")
			
		State.EAT:
			# Found a drop, chow down
			$AnimatedSprite2D.play("idle")
			
		State.SCATTER:
			$AnimatedSprite2D.play("idle")


func _on_animated_sprite_2d_animation_looped() -> void:
	_AnimatedSpriteAnimationFinishedCheck()

func _on_AnimatedSprite_animation_finished() -> void:
	_AnimatedSpriteAnimationFinishedCheck()

func _AnimatedSpriteAnimationFinishedCheck() -> void:
	if $AnimatedSprite2D.animation == "appear":
		change_state(State.SEARCH)

	if $AnimatedSprite2D.animation == "disappear":
		queue_free()



