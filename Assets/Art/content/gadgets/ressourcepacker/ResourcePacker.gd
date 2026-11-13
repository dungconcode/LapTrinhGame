extends Node2D

var remainingRechargeTime:float
var totalRechargeTime:float
var playerId:String

var action_hint := -1
var useCooldown := 0.0

func _ready():
	playerId = get_parent().playerId
	# for now let keepers share this upgrade. Not doing so is complicated:
	# Probe for example als has a cellar part that is affected by some properties, and shared between keepers.
	# this means if we separate suit gadgets per keeper, a subset of the gadgets properties is shared and another subset is individual.
	# this would need a definition somewhere, as it can't be inferred automatically. Additionally it needs to be clear in the UI, not trivial.
	# what should definitely work is that two keepers have differen suit gadgets, but again this is not trivial at all due to shared parts.
	#Data.createInstanceProperties("resourcepacker", playerId)
	Data.listen(self, "resourcepacker.charges", not SaveGame.currentLoadingSavegame)
	
	Level.addTutorial(self, "resourcepacker")
	#action_hint = Level.viewports.register_action_hint("keeper_gadget1", "actionhint.pack")		

func propertyChanged(property:String, oldValue, newValue):
	if oldValue != newValue:
		Data.apply(playerId + ".resourcepacker.chargesremaining", newValue)
		checkStartRecharge()

func addTutorials():
	Level.addTutorial(self, "resourcepacker")

func serialize()->Dictionary:
	var data = {
		"remainingRechargeTime": remainingRechargeTime,
		"totalRechargeTime": totalRechargeTime
	}
	data["meta.priority"] = 200
	data["meta.kind"] = "station"
	return data

func deserialize(data: Dictionary):
	remainingRechargeTime = data["remainingRechargeTime"]
	totalRechargeTime = data["totalRechargeTime"]
	
func _process(delta):
	if GameWorld.paused:
		return
	
	var charges = Data.of(playerId + ".resourcepacker.chargesremaining")
	#Level.viewports.set_action_hint_visible(action_hint, Keepers.oneInsideMine() and charges >0)
	
	if useCooldown > 0.0:
		useCooldown -= delta
	
	if totalRechargeTime == 0.0:
		return
	
	remainingRechargeTime -= delta
	if remainingRechargeTime <= 0:
		Data.changeByInt(playerId + ".resourcepacker.chargesremaining", 1)
		checkStartRecharge()

func checkStartRecharge():
	totalRechargeTime = 0.0
	if Data.of(playerId + ".resourcepacker.chargesremaining") < Data.of("resourcepacker.charges"):
		totalRechargeTime = Data.of("resourcepacker.rechargetime")
		remainingRechargeTime = totalRechargeTime

func executeSpecial1(keeper:Keeper) -> bool:
	if keeper != get_parent() or keeper.isInsideDome or GameWorld.paused:
		return false
	
	if useCooldown > 0.0:
		return false
	
	useCooldown = Data.of("resourcepacker.cooldown")
	var chargesremaining = Data.of(playerId + ".resourcepacker.chargesremaining")
	if chargesremaining > 0:
		Data.apply(playerId + ".resourcepacker.chargesremaining", chargesremaining - 1)
		$PackingSound.play()
		var resourcepacker = preload("res://content/gadgets/ressourcepacker/ResourcePackerEffect.tscn").instantiate()
		resourcepacker.position = global_position
		resourcepacker.set_carrier(keeper)
		Level.map.addTileOverlayEffect(resourcepacker)
		
		checkStartRecharge()
		return true
	else:
		Audio.sound("gui_err")
		return false
