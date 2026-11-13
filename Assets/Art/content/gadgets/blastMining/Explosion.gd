extends AnimatedSprite2D

var fin := 0
var bangType:String
var shake_strength := 200

func _ready():
	play()
	var b = find_child("Bang" + bangType)
	if b:
		b.play()
	else:
		$Bang.play()
	# TODO MULTIPLAYER player individual cameras should shake
	for keeper in Keepers.getAll():
		InputSystem.shake(shake_strength, 0.5, 8, global_position)
	Style.init(self)

func finished():
	fin += 1
	if fin == 2:
		queue_free()
