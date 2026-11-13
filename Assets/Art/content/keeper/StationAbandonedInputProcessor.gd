extends InputProcessor

signal no_inputs
signal got_input

var baseCountdown := 45.0
var countdown:float
var active := true

func _ready():
	resetTimer()

func resetTimer():
	countdown = baseCountdown

func becameLeaf():
	active = true

func notLeaf():
	active = false

func _process(delta):
	if GameWorld.paused or not active:
		return
	
	if countdown > 0.0:
		countdown -= delta
		if countdown <= 0.0:
			emit_signal("no_inputs")

func buttonEvent(event) -> bool:
	if countdown <= 0.0:
		emit_signal("got_input")
	countdown = baseCountdown
	return false

func stick_move(event:InputEventJoypadMotion) -> bool:
	if countdown <= 0.0:
		emit_signal("got_input")
	countdown = baseCountdown
	return false
