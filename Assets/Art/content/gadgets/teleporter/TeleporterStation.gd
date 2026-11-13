extends "res://content/gadgets/CellarGadget.gd"

@export var effect_curve : Curve

var hasTeleporter := true
var teleporter

func _ready():
	$Sprite2D.play("default")
	
	Style.init(self)
	
	Level.addTutorial(self, "teleporter_take")

func serialize()->Dictionary:
	var data = super.serialize()
	data["hasTeleporter"] = hasTeleporter
	return data

func deserialize(data: Dictionary):
	super.deserialize(data)
	hasTeleporter = data["hasTeleporter"]
	for teleporter in get_tree().get_nodes_in_group("teleporters"):
		teleporter.station = self
		setTeleporter(teleporter)

func useHold(keeper:Keeper) -> bool:
	if hasTeleporter:
		return useHit(keeper)
	return false

func canFocusUse(keeper:Keeper) -> bool:
	return true

func setTeleporter(new_teleporter):
	teleporter = new_teleporter
	teleporter.station = self
	hasTeleporter = false
	$Teleporter.queue_free()

func useHit(keeper:Keeper) -> bool:
	if hasTeleporter:
		teleporter = preload("res://content/gadgets/teleporter/Teleporter.tscn").instantiate()
		teleporter.position = $DropPosition.global_position
		Level.map.addDrop(teleporter)
		keeper.attachCarry(teleporter)
		setTeleporter(teleporter)
		return true
	elif teleporter and Data.of("teleporter.teleportTo") and teleporter.position.y > 50:
		teleporter.teleporting = true
		var shrinkTime: float = min(2.0, Data.of("teleporter.teleportDuration") * 0.33)
		var transitionTime:float = Data.of("teleporter.teleportDuration") - (2*shrinkTime)
		$"%EffectTween".interpolate_method(self, "setEffectPower", 0.0, 1.0, shrinkTime, Tween.TRANS_SINE, Tween.EASE_OUT)
		$"%EffectTween".interpolate_method(self, "setEffectPower", 1.0, 0.0, 0.01, Tween.TRANS_SINE, Tween.EASE_OUT, shrinkTime)
		$"%EffectTween".start()
		keeper.startTeleportation(self, shrinkTime, teleportPosition(), teleporter.global_position, Data.ofOr("teleporter.teleportitems", false))
		get_tree().create_timer(shrinkTime).timeout.connect(complete_teleport.bind(false, keeper, shrinkTime, transitionTime))
		return true
	else:
		return false

func keeperWantsToAbort(keeper:Keeper):
	if not teleporter.teleporting:
		return
	complete_teleport(true, keeper, 0, 0.2)

func complete_teleport(abort:bool, keeper, shrinkTime: float, transitionTime: float) -> void:
	if not teleporter.teleporting: 
		return
		
	$TeleportEffect.show()
	$TeleportEffect.frame = 0
	$TeleportEffect.play()
	keeper.teleportComplete()
	if not abort:
		keeper.teleport(teleporter.getTeleportPosition())
		teleporter.onTeleported(shrinkTime, transitionTime - 0.2)
	else:
		Level.viewports.abortTeleportAnimation(keeper)
	keeper.grow(shrinkTime, transitionTime - 0.2)
	teleporter.teleporting = false

func onTeleported(duration:float, delay := 0.0):
	$"%EffectTween".interpolate_callback($Effects/AppearParticles, delay, "set_emitting", true)
	$"%EffectTween".interpolate_callback($Effects/AppearParticles2, delay, "set_emitting", true)
	$"%EffectTween".interpolate_callback($Effects/AppearParticles, duration+delay, "set_emitting", false)
	$"%EffectTween".interpolate_callback($Effects/AppearParticles2, duration+delay, "set_emitting", false)
	$"%EffectTween".interpolate_method(self, "setEffectPower", 0.0, 1.0, duration, Tween.TRANS_SINE, Tween.EASE_OUT)
	$"%EffectTween".interpolate_method(self, "setEffectPower", 1.0, 0.0, 0.01, Tween.TRANS_SINE, Tween.EASE_OUT, duration+delay)
	$"%EffectTween".start()

func setEffectPower(value:float):
	if not %ChargingEffect.is_playing():
		%ChargingEffect.play()
	
	$"%ChargingEffect".visible = value > 0.01
	var val = effect_curve.sample(value)
	$"%ChargingEffect".self_modulate.a = val
	

func teleportPosition() -> Vector2:
	return $DropPosition.global_position

func pauseChanged():
	$Timer.paused = GameWorld.paused
