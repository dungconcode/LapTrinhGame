class_name TechTree extends Control

signal techFocussed(techPanel)

var trackIds := []

var focussedTechPanel

func _process(delta: float) -> void:
	var dirty := false
	for track in $Tracks.get_children():
		dirty = dirty or track.dirty
		track.dirty = false
	if dirty:
		_on_Tracks_sort_children2()
		
func build(prefixMappings:Dictionary, rootsToIgnore:Array):
	trackIds.clear()
	
	var upgrades = Data.orderedUpgradeKeys.duplicate()
	var toErase := []
	for i in Data.orderedUpgradeKeys.size():
		var u = Data.orderedUpgradeKeys[i]
		if not GameWorld.upgrades.has(u):
			continue
		
		var upgrade = GameWorld.upgrades[u]
		if upgrade["tier"] == 0 and u in GameWorld.boughtUpgrades and not GameWorld.isUpgradeLimited(upgrade):
			if prefixMappings.has(u):
				trackIds.append([[prefixMappings[u] + "." + u]])
			else:
				if not rootsToIgnore.has(u):
					trackIds.append([[u]])
			toErase.append(u)
			continue

		var root = upgrade.get("root", "")
		if prefixMappings.has(upgrade.get("root", "")):
			upgrades[i] = prefixMappings[root] + "." +  upgrades[i]

	for u in toErase:
		upgrades.erase(u)
	
	# build tracks
	for track in trackIds:
		var removed := 1
		var currentTier := 1
		while removed > 0:
			removed = 0
			var newTechs := []
			for u in upgrades:
				if not GameWorld.upgrades.has(u):
					continue
				if GameWorld.lockedUpgrades.has(u):
					continue
				
				var upgrade = GameWorld.upgrades[u]
				if GameWorld.isUpgradeLimited(upgrade):
					continue
				
				if upgrade["tier"] != track.size():
					continue
				
				var predecessors:Array = upgrade.get("predecessors")
				var missingPredecessorCount := 1 if upgrade.get("predecessorsany", false) else predecessors.size()
				for predecessor in predecessors:
					if track[currentTier - 1].has(predecessor):
						missingPredecessorCount -= 1
				if missingPredecessorCount <= 0:
					newTechs.append(u)
			
			if newTechs.size() > 0:
				track.append(newTechs)
			for u in newTechs:
				upgrades.erase(u)
				removed += 1
			currentTier += 1
	
	focussedTechPanel = null
	for t in trackIds:
		var track = preload("res://content/techtree/techtrack/TechTrack.tscn").instantiate()
		track.build(t, self)
		$Tracks.add_child(track)

# called by TechTreePopup, to give focus into the tech tree
func focus():
	if not focussedTechPanel:
		focussedTechPanel = $Tracks.get_children().front().panelsByTier.front().front()
	InputSystem.grabFocus(focussedTechPanel)

func showExplanation(techPanel, explanationBb):
	find_child("ExplanationLabel").text = tr(explanationBb)
	find_child("Explanation").global_position.x = techPanel.global_position.x
	find_child("Explanation").global_position.y = techPanel.global_position.y + techPanel.size.y
	find_child("Explanation").size.x = techPanel.size.x
	find_child("Explanation").size.y = 1

func _on_Tracks_sort_children2():
	for track in $Tracks.get_children():
		track.updateLines()
	
	var tracks:Array = $Tracks.get_children()
	for i in range(0, tracks.size()):
		var track = tracks[i]
		
		# does not seem necessary
		for tier in track.panelsByTier:
			for j in range(1, tier.size()):
				tier[j].focus_neighbor_top = tier[j-1].get_path()
				tier[j-1].focus_neighbor_bottom = tier[j].get_path()
		
		if i > 0:
			# transition from a track to the one above it
			var bottomSize = tracks[i-1].bottomTechPanelsByTier.size() - 1
			for j in range(0, track.topTechPanelsByTier.size()):
				track.topTechPanelsByTier[j].focus_neighbor_top = tracks[i-1].bottomTechPanelsByTier[min(j, bottomSize)].get_path()
		else:
			# for the up most track, don't do anything when trying to move to the track above it
			for j in range(0, track.topTechPanelsByTier.size()):
				track.topTechPanelsByTier[j].focus_neighbor_top = track.topTechPanelsByTier[j].get_path()
		
		if i < tracks.size() - 1:
			# transition from a track to the one below it
			var topSize = tracks[i+1].topTechPanelsByTier.size() - 1
			for j in range(0, track.bottomTechPanelsByTier.size()):
				track.bottomTechPanelsByTier[j].focus_neighbor_bottom = tracks[i+1].topTechPanelsByTier[min(j, topSize)].get_path()
		else:
			# for the bottom most track, don't do anything when trying to move to the track below it
			for j in range(0, track.bottomTechPanelsByTier.size()):
				track.bottomTechPanelsByTier[j].focus_neighbor_bottom = track.bottomTechPanelsByTier[j].get_path()
		
		for techPanel in track.rightTechPanels:
			techPanel.focus_neighbor_right = techPanel.get_path()

var tempLeftNeighborOverrides := {}
var tempRightNeighborOverrides := {}
func technologyFocussed(techPanel):
	if focussedTechPanel and focussedTechPanel.track == techPanel.track:
		# if going from right to left, you want to get to the same tech you were coming from if going back
		# this codes remembers the original right neighbor, but sets the one you were coming from as a temp neighbor
		if techPanel.global_position.x < focussedTechPanel.global_position.x:
			if not tempRightNeighborOverrides.has(techPanel):
				tempRightNeighborOverrides[techPanel] = techPanel.focus_neighbor_right
			techPanel.focus_neighbor_right = focussedTechPanel.get_path()
		elif tempRightNeighborOverrides.has(techPanel):
			techPanel.focus_neighbor_right = tempRightNeighborOverrides[techPanel]
			tempRightNeighborOverrides.erase(techPanel)
		
		# same for going left to right, but only if there is a tech with multiple predecessors, 
		# as otherwise the predessor takes precedence
		if techPanel.global_position.x > focussedTechPanel.global_position.x:
			if GameWorld.upgrades.get(techPanel.techId, {}).get("predecessors", []).has(focussedTechPanel.techId):
				if not tempLeftNeighborOverrides.has(techPanel):
					tempLeftNeighborOverrides[techPanel] = techPanel.focus_neighbor_left
				techPanel.focus_neighbor_left = focussedTechPanel.get_path()
		elif tempLeftNeighborOverrides.has(techPanel):
			techPanel.focus_neighbor_left = tempLeftNeighborOverrides[techPanel]
			tempLeftNeighborOverrides.erase(techPanel)
	
	if focussedTechPanel != techPanel:
		techPanel.focusCounter = 0
	focussedTechPanel = techPanel
	
	var scrollX = techPanel.global_position.x + get_parent().scroll_horizontal - get_parent().global_position.x - get_parent().size.x*0.5  + techPanel.size.x*0.5
	var scrollY = techPanel.track.global_position.y - get_parent().size.y*0.5 + techPanel.track.size.y*0.5 + get_parent().scroll_vertical - get_parent().global_position.y
	if abs(get_parent().scroll_horizontal - scrollX) > 30:
		$Tween.interpolate_property(get_parent(), "scroll_horizontal", get_parent().scroll_horizontal, scrollX, 0.2, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	if abs(get_parent().scroll_vertical - scrollY) > 30:
		$Tween.interpolate_property(get_parent(), "scroll_vertical", get_parent().scroll_vertical, scrollY, 0.2, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	$Tween.start()
	emit_signal("techFocussed", techPanel)

func techUnfocussed(techPanel):
	pass
#	if focussedTechPanel == techPanel:
#		print("old " + str(focussedTechPanel.rect_position))
#		focussedTechPanel = null

func techInput(event, techPanel):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if techPanel == focussedTechPanel:
			techPanel.focusCounter += 1
			if techPanel.focusCounter > 1:
				buyCurrentUpgrade()
#		else:
#		InputSystem.grabFocus(techPanel)
		pass

func buyCurrentUpgrade():
	if focussedTechPanel:
		var tech = GameWorld.upgrades.get(focussedTechPanel.techId)
		var bought := false
		if focussedTechPanel.state == 1:
			if GameWorld.canAfford(tech.get("cost", {})):
				bought = true
				GameWorld.buyUpgrade(focussedTechPanel.techId) 
				focussedTechPanel.upgrade()
				focussedTechPanel.track.updateState()
				emit_signal("techFocussed", focussedTechPanel)
				focussedTechPanel.track.updateLineColors()
				focussedTechPanel.track.updateLines()
		if not bought:
			focussedTechPanel.error()
	
func _on_Tracks_resized() -> void:
	pass # Replace with function body.
