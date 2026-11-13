extends Node2D

var remainingTimeToRechargeOneCharge:float

var action_hint_probe := -1

func _ready():
	Data.listen(self, "monsters.wavepresent")
	Data.listen(self, "probe.autorecharge")

func addTutorials():
	Level.addTutorial(self, "probe")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		"probe.autorecharge":
			updateRechargeTime()
		"monsters.wavepresent":
			if not newValue:
				if Data.of("probe.rechargeAfterBattle"):
					create_tween().tween_callback(func():Data.apply("probe.chargesRemaining", Data.of("probe.charges"))).set_delay(0.5)
					$ProbeReadySound.play()

func serialize()->Dictionary:
	var data = {
		"remainingTimeToRechargeOneCharge": remainingTimeToRechargeOneCharge
	}
	data["meta.priority"] = 200
	data["meta.kind"] = "station"
	return data

func deserialize(data: Dictionary):
	remainingTimeToRechargeOneCharge = data["remainingTimeToRechargeOneCharge"]
	updateRechargeTime()
	
func _process(delta):
	if  GameWorld.softPaused():
		return 
	
	if remainingTimeToRechargeOneCharge == 0.0:
		return
	
	var chargesRemaining = Data.of("probe.chargesRemaining")
	#Level.viewports.set_action_hint_visible(action_hint_probe, Keepers.oneInsideMine() and chargesRemaining > 0)
	
	var maxCharges = Data.of("probe.charges")
	if chargesRemaining >= maxCharges:
		return
	
	remainingTimeToRechargeOneCharge -= delta
	if remainingTimeToRechargeOneCharge <= 0:
		Data.apply("probe.chargesRemaining", maxCharges)
		updateRechargeTime()
		
func executeSpecial1(keeper:Keeper) -> bool:
	if keeper != get_parent() or keeper.isInsideDome or GameWorld.paused:
		return false

	var chargesRemaining = Data.of("probe.chargesRemaining")
	if chargesRemaining > 0:
		Data.apply("probe.chargesRemaining", chargesRemaining - 1)
		var probe = load("res://content/gadgets/probe/ProbeImpulse.tscn").instantiate()
		probe.position = global_position

		Level.map.addTileOverlayEffect(probe)
		updateRechargeTime()
		return true
	else:
		return false
		
func updateRechargeTime():
	if Data.of("probe.autorecharge") and remainingTimeToRechargeOneCharge <= 0.0 and Data.of("probe.charges") >= Data.of("probe.chargesRemaining"):
		remainingTimeToRechargeOneCharge = GameWorld.getTimeBetweenWaves() * Data.of("probe.rechargetime")
