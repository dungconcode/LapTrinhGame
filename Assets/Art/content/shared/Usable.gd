extends Area2D

@export var modulateOnFocus: NodePath
@export var visibleOnFocus: NodePath
var inFocusArea := []
var focussed := false
var modulationNode:Node
var visibilityNode:Node

# --- PARENT NEEDS TO IMPLEMENT ---
#
#func canFocusUse(keeper:Keeper) -> bool:
#	return true
#
#func useHold(keeper:Keeper) -> bool:
#	return useHit(keeper)
#
#func useHit(keeper:Keeper) -> bool:
#	return false
# --------------------------------

func _ready():
	if visibleOnFocus:
		visibilityNode = get_node(visibleOnFocus)
		visibilityNode.visible = false
		visibilityNode.material = preload("res://content/shared/HighlightShader.tres")
	elif modulateOnFocus:
		modulationNode = get_node(modulateOnFocus)
	else:
		modulationNode = get_parent()
	
	get_parent().add_to_group("usables")
	get_parent().set_meta("usable", self)
	
func focusUse(keeper:Keeper):
	inFocusArea.append(keeper)
	updateFocus()

func updateFocus():
	var someoneCanFocusUse := false
	for keeper in inFocusArea:
		if not is_instance_valid(keeper):
			# Note: added during conversion to 4.x in reaction to failed type check of canFocusUse 
			# in case when instance has been freed
			keeper = null
		someoneCanFocusUse = someoneCanFocusUse or canFocusUse(keeper)

	if someoneCanFocusUse:
		if visibilityNode:
			visibilityNode.visible = true
		else:
			modulationNode.modulate = Style.FOCUS_MODULATE
		focussed = true
	else:
		if visibilityNode:
			visibilityNode.visible = false
		else:
			modulationNode.modulate = Color.WHITE
		focussed = false

func unfocusUse(keeper:Keeper):
	inFocusArea.erase(keeper)
	updateFocus()

func canFocusUse(keeper:Keeper) -> bool:
	return get_parent().canFocusUse(keeper)

func canPickup(keeper:Keeper) -> bool:
	return visibleOnFocus != null and canFocusUse(keeper)

func useHold(keeper:Keeper) -> bool:
	if focussed:
		var handled = get_parent().useHold(keeper)
		if handled:
			updateFocus()
		return handled
	else:
		return false

func useHit(keeper:Keeper) -> bool:
	if focussed:
		var parent = get_parent()
		var handled = parent.useHit(keeper)
		if handled:
			updateFocus()
		return handled
	else:
		return false
