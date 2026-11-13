extends AnimatedSprite2D

var fin := 0

func _ready():
	Style.init(self)
	play()

func playSound():
	$Bang.play()
	for keeper in Keepers.getAll():
	# TODO multiplayer: does not make sense. Missing keeper parameter?
		InputSystem.shake(200, 0.5, 8, global_position)

func finished():
	fin += 1
	if fin == 2:
		queue_free()
