extends "res://content/gadgets/CellarGadget.gd"

var charging := false
func _ready():
	Data.apply("probe.chargesRemaining", Data.of("probe.charges"))
	Data.listen(self, "probe.chargesRemaining")
	Data.listen(self, "probe.charges")
	$Sprite2D.play("off")

	Data.listen(self, "probe.hasstation")

	Style.init(self)
	
	Achievements.addIfOpen(self, "PROBE_USE")

func canFocusUse(keeper:Keeper) -> bool:
	return not charging and Data.of("probe.chargesRemaining") < Data.of("probe.charges")

func useHold(keeper:Keeper) -> bool:
	return useHit(keeper)

func useHit(keeper:Keeper) -> bool:
	if not canFocusUse(keeper):
		return false

	keeper.externallyMoved = true
	keeper.move *= 0
	$Tween.interpolate_property(keeper, "position", keeper.position, $KeeperPos.global_position, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	$Tween.start()
	get_tree().create_timer(0.3).timeout.connect(_on_tree_timer_timeout.bind(keeper))
	return true

func _on_tree_timer_timeout(keeper) -> void:
	var p1 = Vector2($Slider.position.x,-20)
	var p2 = Vector2($Slider.position.x,-4)
	$Tween.interpolate_property($Slider, "position", p1, p2, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	$Tween.interpolate_property($Slider, "position", p2, p1, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0.2)
	$Tween.interpolate_property($Slider, "position", p1, p2, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0.4)
	$Tween.interpolate_property($Slider, "position", p2, p1, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0.6)
	$Tween.interpolate_property($Slider, "position", p1, p2, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0.8)
	$Tween.interpolate_property($Slider, "position", p2, p1, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 1.0)
	$Tween.interpolate_callback(keeper, 1.2, "set", "externallyMoved", false)
	$Tween.interpolate_callback(Data, 1.2, "apply", "probe.chargesRemaining", Data.of("probe.charges"))
	$Tween.start()
	charging = true
	$ChargeSound.play()

func propertyChanged(property:String, oldValue, newValue):
	if property == "probe.chargesremaining":
		var on := false
		for keeper in Keepers.getAll():
			var key = "probe.chargesRemaining"
			if Data.of(key) < Data.of("probe.charges"):
				on = true

		if on:
			$Sprite2D.play("on")
		else:
			$Sprite2D.play("off")

		if oldValue == null or newValue > oldValue:
			charging = false
		return

	match property:
		"probe.charges":
			for keeper in Keepers.getAll():
				var key = "probe.chargesRemaining"
				Data.apply(key, Data.of("probe.charges"))
		"probe.hasstation":
			if not newValue:
				queue_free()
				GameWorld.availableTechSlots.append("cellar")
