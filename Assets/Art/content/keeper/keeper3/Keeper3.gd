extends Keeper


const SPEED = 300.0
const JUMP_VELOCITY = -300.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

var throw_cooldown := 0.0
var current_rope

func init():
	super.init()
	
	$Sprite2D.frame = 0
	focussedUsable = null
	focussedCarryable = null
	
	Style.init(self)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if GameWorld.paused:
		return
	
	throw_cooldown -= delta
	
	var climbing_ladder:bool = false# abs(position.x) < 12 and abs(move.x) < 40
	climbing_ladder = isInsideDome
	
	var is_on_rope = current_rope and current_rope.connected
	
	# Add the gravity.
	if not is_on_floor() and not climbing_ladder and not is_on_rope:
		move.y = lerp(move.y, 200.0, delta * 3)
	
	# Handle jump.
	if climbing_ladder:
		move.y = move_toward(move.y, moveDirectionInput.y * 100, delta * 400)
	if moveDirectionInput.y < -0.1:
		if is_on_floor() and not climbing_ladder and not is_on_rope:
			move.y = JUMP_VELOCITY
	
	if is_on_rope:
		var rope_angle = current_rope.get_angle()
		if abs(moveDirectionInput.y) > 0.1:
			move = lerp(move, moveDirectionInput.y * Vector2.DOWN.rotated(rope_angle) * 100, delta * 10)
		else:
			move.y = move_toward(move.y, 0, delta * 400)
		
		if abs(moveDirectionInput.x) < 0.1:
			var diff = current_rope.connect_point.x - position.x
			move.x = move_toward(move.x, diff, abs(diff) * delta * 100)
		else:
			var strength := 0.0
			var same_dir = sign(rope_angle) == sign(moveDirectionInput.x)
			if same_dir:
				strength = max(0, 0.6 - abs(rope_angle))
			else:
				strength = max(0, 1.6 + abs(rope_angle))
			var goal = moveDirectionInput.x * 100
			move.x = move_toward(move.x, goal * strength, delta * 100)
		
	else:
		if abs(moveDirectionInput.x) < 0.1:
			move.x = move_toward(move.x, 0, SPEED)
		else:
			move.x = move_toward(move.x, moveDirectionInput.x * 100, delta * 400)
	
	set_velocity(move)
	move_and_slide()
	move = velocity
	
	var combinedMove = moveDirectionInput
	if move.length() > 0.15:
		combinedMove += move
	if combinedMove.length() < 0.35:
		$Sprite2D.play("default"+animationSuffix)
	else:
		if abs(combinedMove.x) > abs(combinedMove.y) * 0.95:
			$Sprite2D.play("left"+animationSuffix if combinedMove.x < 0 else "right"+animationSuffix)
		else:
			$Sprite2D.play("up"+animationSuffix if combinedMove.y < 0 else "down"+animationSuffix)

func rope():
	if current_rope:
		current_rope.update_origin(position)
		return
	
	var dir = getAimDirection()
	if dir.length() < 0.1:
		# TODO sound invalid rope action
		return
	move.y = 0
	current_rope = preload("res://content/keeper/keeper3/Rope.tscn").instantiate()
	current_rope.start(dir)
	current_rope.position = position
	current_rope.connect("on_connected", on_rope_connected)
	Level.map.addDrop(current_rope)

func on_rope_connected():
	pass

func stop_rope():
	if current_rope:
		current_rope.stop()
		current_rope = null

func throw():
	if throw_cooldown > 0.0:
		# TODO invalid action sound
		return
	
	# TODO throw sound
	var explosive := preload("res://content/keeper/keeper3/Explosive.tscn").instantiate()
	explosive.position = self.position
	Level.map.addDrop(explosive)
	explosive.apply_central_impulse(getAimDirection() * 150)

func getAimDirection() -> Vector2:
	if showcaseMode:
		return moveDirectionInput

	if Options.useGamepad:
		if aimDirectionInput.length() < moveDirectionThreshold:
			return Vector2.ZERO
		else:
			return aimDirectionInput
	elif Options.useMouseKeeperGameplay:
		var localMousePosition = get_local_mouse_position()
		if localMousePosition.length() < mouseTooCloseThreshold:
			return Vector2.ZERO
		else:
			return localMousePosition.normalized()
	else:
		return moveDirectionInput

func currentSpeed():
	return 200
