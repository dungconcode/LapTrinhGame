extends AudioStreamPlayer

var tween:DeprecatedTween

const fadeTime := 2.0
var shouldPlay := false

func _ready():
	tween = DeprecatedTween.new()
	add_child(tween)

func start():
	if shouldPlay:
		return
	shouldPlay = true
	tween.stop_all()
	tween.remove_all()
	volume_db = -40
	play()
	tween.interpolate_property(self, "volume_db", volume_db, 0, fadeTime * 0.5)
	tween.start()

func stop():
	if not shouldPlay:
		return
	shouldPlay = false
	tween.stop_all()
	tween.remove_all()
	tween.interpolate_property(self, "volume_db", volume_db, -40, fadeTime * 2)
	tween.interpolate_callback(self, fadeTime, "stop")
	tween.start()
