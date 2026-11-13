extends ColorRect

var tween:DeprecatedTween

func _ready():
	tween = DeprecatedTween.new()
	add_child(tween)
	visible = false

func showOverlay():
	if visible:
		return
	
	color = Style.OVERLAY_COLOR_OUT
	visible = true
	tween.interpolate_property(self, "color", color, Style.OVERLAY_COLOR_IN, 0.3)
	tween.start()

func hideOverlay():
	if not visible:
		return
	
	color = Style.OVERLAY_COLOR_IN
	tween.interpolate_property(self, "color", color, Style.OVERLAY_COLOR_OUT, 0.3)
	tween.interpolate_callback(self, 0.3, "set", "visible", false)
	tween.start()
