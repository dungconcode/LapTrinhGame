extends RigidBody2D

class_name Carryable

# in percent
@export var additionalSlowdown := 0.0

@export var carryableType := ""
@export var canTeleport := false
var carriedBy := []
var inFocusArea := []
var focussed := false
var deactivated := false
var independent := false
var isAutoTransported := false
var UID := -1

var physicsOverrides := []
var carryInfluence
@export var carryInfluenceSize := 1.0 # (float, 1.0, 5.0)

var teleportDestination

func _ready():
	UID = randi()
	
	if not is_instance_valid(physics_material_override):
		physics_material_override = PhysicsMaterial.new()
	var originalPhysics := CarryablePhysicsOverride.new(self)
	originalPhysics.linear_damp = linear_damp
	originalPhysics.angular_damp = angular_damp
	originalPhysics.gravity_scale = gravity_scale
	originalPhysics.friction = physics_material_override.friction
	physicsOverrides.append(originalPhysics)
	
	$FocusSprite.visible = false
	$CarrySprite.visible = false
	
	add_to_group("carryable")
	add_to_group("pauseL")

func teleport(to:Vector2):
	teleportDestination = to

func _integrate_forces(state):
	if teleportDestination:
		state.transform.origin = teleportDestination
		teleportDestination = null

var oldVelocity = Vector2()
func pauseChanged():
	if GameWorld.paused and not independent:
		oldVelocity = linear_velocity
		set_axis_velocity(Vector2.ZERO)
		freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
		freeze = true
	else:
		freeze = false
		if not independent:
			set_axis_velocity(oldVelocity)

func serialize()->Dictionary:
	var data = {}

	data["carriedBy"] = []
	for carrier in carriedBy:
		if carrier and carrier is Keeper:
			data["carriedBy"].append(carrier.playerId)

	data["meta.priority"] = 100
	data["meta.kind"] = "generic"
	data["UID"] = UID

	return data

func deserialize(data: Dictionary):
	UID = data["UID"]
	for carrierPlayerId in data["carriedBy"]:
		var keeper = Keepers.getKeeper(carrierPlayerId)
		if keeper:
			keeper.attachCarry(self)

func setIndependent(b:bool):
	independent = b
	process_mode = Node.PROCESS_MODE_ALWAYS if independent else Node.PROCESS_MODE_INHERIT
	if independent:
		$FocusSprite.visible = false

# TODO: Conversion: removing p:Keeper type since LiftOrb is not a Keeper
func focusCarry(p):
	inFocusArea.append(p)
	updateFocus()

# TODO: Conversion: removing p:Keeper type since LiftOrb is not a Keeper (called by LiftOrb.attachCarry)
func unfocusCarry(p):
	inFocusArea.erase(p)
	updateFocus()

func updateFocus():
	if canFocusCarry() and inFocusArea.size() > 0:
		focussed = true
		get_node("FocusSprite").visible = true
	else:
		focussed = false
		get_node("FocusSprite").visible = false

func isCarried() -> bool:
	return carriedBy.size() > 0

func isCarriedBy(carrier) -> bool:
	return carriedBy.has(carrier)

func canFocusCarry() -> bool:
	return not independent

# TODO: Conversion: removing p:Keeper type since LiftOrb is not a Keeper (called by LiftOrb.attachCarry)
func setCarriedBy(p):
#	Can't use that for now because
#	1. not every carryable has a tween. If this should be different, carryable should ensure a tween is ther. But it's obsolete with Godot 4 anyway.
#	2. looks bad on large carryables like gadget
#	$Tween.interpolate_property($Sprite, "scale", Vector2.ONE*2.0, Vector2.ONE, 0.6, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
#	$Tween.interpolate_property($Sprite, "modulate", Color(2.9, 2.9, 1.9, 1.0), Color.white, 0.6, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
#	$Tween.interpolate_property($CarrySprite, "scale", Vector2.ONE*1.5, Vector2.ONE, 0.6, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
#	$Tween.start()
	$CarrySprite.visible = true
	carriedBy.append(p)
	if carriedBy.size() == 1:
		onCarried(p)

# TODO: Conversion: removing p:Keeper type since LiftOrb is not a Keeper (called by LiftOrb.dropCarry)
func freeCarry(p):
	removePhysicsOverride(p)
	carriedBy.erase(p)
	if carriedBy.size() == 0:
		$CarrySprite.visible = false
		onDropped(p)

# TODO: Conversion: removing p:Keeper type since LiftOrb is not a Keeper
func onCarried(p):
	pass

# TODO: Conversion: removing p:Keeper type since LiftOrb is not a Keeper
func onDropped(p):
	pass

func carrierCount() -> int:
	return carriedBy.size()

func getOrCreateCarryInfluence(carrier):
	if carryInfluence == null:
		carryInfluence = load("res://content/shared/drops/CarryInfluence.tscn").instantiate()
		add_child(carryInfluence)
	carryInfluence.carrier = carrier
	return carryInfluence

func dissolveCarryInfluence():
	if carryInfluence:
		# dissolve() handles the rest of removing from carryable, as dissolve might be called directly
		carryInfluence.dissolve()

func hasCarryInfluence() -> bool:
	return carryInfluence != null

func getCarryInfluence():
	return carryInfluence

func addPhysicsOverride(physics:CarryablePhysicsOverride):
	physicsOverrides.append(physics)
	_updatePhysicsOverrides()

func removePhysicsOverride(creator):
	for p in physicsOverrides.duplicate():
		if p.creator == creator:
			physicsOverrides.erase(p)
	_updatePhysicsOverrides()

func _updatePhysicsOverrides():
	for p in physicsOverrides:
		p.apply(self)
