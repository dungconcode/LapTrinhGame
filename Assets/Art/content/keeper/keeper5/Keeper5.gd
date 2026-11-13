extends Keeper
# spiderman

signal tileHit

var knockbackDirection := Vector2()
var rising := false
var falling := true
var jumpStrengthLeft := 0.0

const maxCarryLineLength := 150.0

func _ready():
	Style.init(self)

func _physics_process(delta):
	super._physics_process(delta)
	# Light on/off and flicker
	if position.y < 0:
		$Light3D.hide()
	else:
		$Light3D.show()
		
	if not $Light3D/Tween.is_active():
		var s: float = randf_range(1.0,1.05)
		$Light3D/Tween.interpolate_property($Light3D, "scale", $Light3D.scale, Vector2(s,s), 0.08, Tween.TRANS_CUBIC)
		$Light3D/Tween.start()
	
	if isInsideStation or GameWorld.paused or disabled:
		$MoveSound.stop()
		$CarryLoadSound.stop()
		return
	
	move.x *= (1.0 - delta * 20)
	move.x += delta * moveDirectionInput.x * 200
	
	if moveDirectionInput.y == -1 and not falling and not rising:
		rising = true
		jumpStrengthLeft = 3.0
	
	if rising:
		jumpStrengthLeft -= delta * 5
		if moveDirectionInput.y != -1:
			jumpStrengthLeft = 0
		if jumpStrengthLeft <= 0.0:
			rising = false
			falling = true
	
	if rising or falling:
		move.y -= jumpStrengthLeft * delta * 10
		move.y = min(move.y + delta * 5, 10)
	
	set_velocity(move * 10)
	# TODOConverter3To4 looks that snap in Godot 4 is float, not vector like in Godot 3 - previous value `Vector2.DOWN*10`
	set_up_direction(Vector2.ZERO if rising else Vector2.UP)
	move_and_slide()
	var s = velocity
	if is_on_floor() and falling:
		falling = false
		move.y = 0.0
	elif not rising and not falling and not is_on_floor():
		falling = true
	
	# because there is no notification about usables becoming focussable, this runs every loop
	# otherwise there would be problems with drops and stations, like in the cellar
	updateInteractables()

func currentSpeed() -> float:
	var s = Data.of("keeper5.maxSpeed")
	return s

func pickupHit():
	pass

func pickupHold():
	pass

func pickupHoldStopped():
	pass

func dropHit():
	pass

func dropHold():
	pass
