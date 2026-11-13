extends Container

func _ready():
	if not GameWorld.won or GameWorld.buildType == CONST.BUILD_TYPE.EXHIBITION:
		visible = false
		return
	
	var newDifficulty:bool = false
	
	var newWorld:bool = false
	var nextWorld = GameWorld.nextUnlock(Level.loadout.worldId)
	if nextWorld and GameWorld.unlockElement(nextWorld) != ""  and (Level.loadout.modeId == CONST.MODE_RELICHUNT or Level.loadout.modeId == CONST.MODE_ASSIGNMENTS):
		newWorld = true
		var id = nextWorld.to_upper() + "_UNLOCK"
		Achievements.triggerIfOpen(id)
	
	var newMapSize:bool = false
	var nextMapSize = GameWorld.nextUnlock(Level.loadout.modeConfig.get(CONST.MODE_CONFIG_MAP_ARCHETYPE, ""))
	if nextMapSize and GameWorld.unlockElement(nextMapSize) != "" and Level.loadout.modeId == CONST.MODE_RELICHUNT:
		newMapSize = true
	
	var newPet := false
	for p in get_tree().get_nodes_in_group("pets"):
		if not GameWorld.unlockedPets.has(p.id):
			GameWorld.unlockablePets.erase(p.id)
			GameWorld.unlockedPets.append(p.id)
			newPet = true
	
	var assignmentUnlocked = not GameWorld.unlockedElements.has(CONST.MODE_ASSIGNMENTS)
	if assignmentUnlocked:
		GameWorld.unlockElement(CONST.MODE_ASSIGNMENTS)
	
	var keeperId = Level.loadout.keepers.front().keeperId
	var unlockAssessorSkin:bool = keeperId == "keeper2"
	for id in ["KEEPER2_REFLECTIONS", "KEEPER2_SPHEREDURATION", "KEEPER2_BIGBUNDLE", "KEEPER2_SPLITS", "KEEPER2_EXPLODE", "KEEPER2_AMMO"]:
		if Achievements.isOpen(id):
			unlockAssessorSkin = false
			break
	if unlockAssessorSkin:
		GameWorld.newSkinsToUnlock.append("skin2")
	
	var newSkin := false
	for skin in GameWorld.newSkinsToUnlock:
		if not GameWorld.unlockedSkins.get(keeperId, []).has(skin):
			GameWorld.unlockSkin(keeperId, skin)
			newSkin = true
	
	var newGadget := false
	for gadgetId in Data.gadgets:
		if GameWorld.upgrades.has(gadgetId) and GameWorld.upgrades[gadgetId].get("type", "") == "gadget" and not GameWorld.unlockedElements.has(gadgetId):
			newGadget = true
			GameWorld.unlockElement(gadgetId)
	
	var proMode = not Achievements.isOpen("PRESTIGE_WIN") and not GameWorld.isUnlocked(CONST.MODE_PRESTIGE_PRO)
	if proMode:
		GameWorld.unlockElement(CONST.MODE_PRESTIGE_PRO)
	
	find_child("NewDifficultyUnlockedPanel").visible = newDifficulty
	find_child("NewWorldUnlockedPanel").visible = newWorld
	find_child("NewMapSizeUnlockedPanel").visible = newMapSize
	find_child("NewPetUnlockedPanel").visible = newPet
	find_child("SkinUnlockPanel").visible = newSkin
	find_child("NewGadgetPanel").visible = newGadget
	find_child("AssignmentPanel").visible = assignmentUnlocked
	find_child("ProModeUnlockPanel").visible = proMode
	
	var visiblePanels := []
	if assignmentUnlocked:
		visiblePanels.append(find_child("AssignmentPanel"))
	if newDifficulty:
		visiblePanels.append(find_child("NewDifficultyUnlockedPanel"))
	if newPet:
		visiblePanels.append(find_child("NewPetUnlockedPanel"))
	if newWorld:
		visiblePanels.append(find_child("NewWorldUnlockedPanel"))
	if newMapSize:
		visiblePanels.append(find_child("NewMapSizeUnlockedPanel"))

	var possibleModifiers = GameWorld.runModifiersToUnlock.duplicate()
	if visiblePanels.size() <= 2 and Level.loadout.modeId == CONST.MODE_RELICHUNT:
		Data.RUN_MODIFIERS.shuffle()
		possibleModifiers.append_array(Data.RUN_MODIFIERS)
	var modifierUnlocked := false
	for mod in possibleModifiers:
		if not GameWorld.unlockedRunModifiers.has(mod):
			GameWorld.unlockedRunModifiers.append(mod)
			visiblePanels.append(find_child("ModifiersUnlockedPanel"))
			modifierUnlocked = true
			break
	find_child("ModifiersUnlockedPanel").visible = modifierUnlocked

	if newSkin:
		visiblePanels.append(find_child("SkinUnlockPanel"))
	if proMode:
		visiblePanels.append(find_child("ProModeUnlockPanel"))
	if proMode:
		visiblePanels.append(find_child("NewGadgetPanel"))
	
	SaveGame.persistMetaState()

	var delay := 1.0
	for panel in visiblePanels:
		delay += animateUpdate(panel, delay)

const medalScale := 1.8
func animateUpdate(panel, delay:float) -> float:
	var duration1 = 0.5
	var duration2 = 0.15
	
	panel.scale = Vector2.ZERO
	panel.modulate.a = 0.0
	
#	$Tween.interpolate_callback(panel, delay - 0.1, "set", "texture", t)
	$Tween.interpolate_callback(panel, delay, "set", "modulate", Color.WHITE)
	panel.pivot_offset = panel.get_size()*0.5
	
#	var p = find_node("Particles2D")
#	$Tween.interpolate_callback(p, delay + duration1 + 0.0, "set", "emitting", true)
	$Tween.interpolate_property(panel, "scale", Vector2.ZERO, Vector2.ONE * medalScale, duration1, Tween.TRANS_CUBIC,Tween.EASE_OUT, delay)
	$Tween.interpolate_property(panel, "scale", Vector2.ONE * medalScale, Vector2.ONE, duration2, Tween.TRANS_CUBIC, Tween.EASE_IN, delay+duration1)
	$Tween.interpolate_callback(Audio, delay + duration1 + 0.0, "sound", "unlock_event")
	$Tween.start()
	
	return duration1 + duration2 + 0.4
