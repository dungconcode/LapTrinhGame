class_name TechTrack extends PanelContainer

var techs := {}
var lockGroupBoxes := {}
var rootTechId := ""

var techPanels := {}
var topTechPanelsByTier := []
var bottomTechPanelsByTier := []
var rightTechPanels := []
var panelsByTier := []
var edges := []

var invisId := 0
var lockGroupsByTier := []
var prevTier:Array

var dirty := false

const vIn = Vector2(-30, 0)
const vOut = Vector2(30, 0)
var linesByTech := []
var curve: Curve2D = Curve2D.new()
@onready var linesHolder: Node = $Lines

func build(techsByTier:Array, focusListener: TechTree):
	# build tech data
	var tierN := 0
	var biggestTierSize = 1
	for tier in techsByTier:
		biggestTierSize = max(biggestTierSize, tier.size())
		var index = 0
		for techId in tier:
			var tierData := {"id":techId, "tier":tierN, "index":index, "children":[]}
			var tech = GameWorld.upgrades.get(techId)
			if tech.has("locks"):
				tierData["locks"] = tech.get("locks")
			if tech.has("requires"):
				tierData["requires"] = tech.get("requires")
			if tech.has("predecessors"):
				tierData["predecessors"] = tech.get("predecessors")
				var predecessorCount = getValidPredecessorCount(tech["predecessors"])
				index += predecessorCount - 1
				tierData["index"] = index
			techs[techId] = tierData
			if tierN == 0:
				rootTechId = techId
			index += 1
		tierN += 1

	# build forward links to child techs
	for tier in techsByTier:
		for techId in tier:
			var tech = GameWorld.upgrades.get(techId)
			if tech.has("predecessors"):
				for predId in tech.predecessors:
					if techs.has(predId):
						techs[predId].children.append(techId)

	# build lock groups
	for tier in techsByTier:
		var remainingTechs = tier.duplicate()
		
		var lockGroups := []
		while remainingTechs.size() > 0:
			var techId = remainingTechs.pop_front()
			var tech = techs[techId]
			if tech.has("locks"):
				var lockGroup := []
				for l in tech.get("locks"):
					if tier.has(l):
						lockGroup.append(l)
						remainingTechs.erase(l)
						techs[l]["lockGroup"] = lockGroup
				if lockGroup.size() > 0:
					lockGroup.append(techId)
					lockGroups.append(lockGroup)
					techs[techId]["lockGroup"] = lockGroup
		
		lockGroupsByTier.append(lockGroups)
	
	# create the ui elements
	var i := 0
	for tier in techsByTier:
		tier.sort_custom(Callable(self, "sortByPredecessorIndex"))
		var box := VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if i < 2:
			box.alignment = BoxContainer.ALIGNMENT_CENTER
		else:
			box.alignment = BoxContainer.ALIGNMENT_BEGIN
		i +=1
		box.set("theme_override_constants/separation", 20)
		var panelsOfTier := []
		var index = 0
		for techId in tier:
			var tech = techs[techId]
			if i > 2 and tier.size() == 1 and tech.has("predecessors"):
				var predecessorCount = getValidPredecessorCount(tech["predecessors"])
				if predecessorCount > 1 and predecessorCount == prevTier.size():
					box.alignment = BoxContainer.ALIGNMENT_CENTER
			var boxToUse
			if tech.has("lockGroup"):
				var lockGroupId = tech.get("lockGroup").front()
				if lockGroupBoxes.has(lockGroupId):
					boxToUse = lockGroupBoxes.get(lockGroupId)
				else:
					var lockBox := PanelContainer.new()
					lockBox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
					lockBox.mouse_filter = Control.MOUSE_FILTER_IGNORE
					boxToUse = VBoxContainer.new()
					boxToUse.mouse_filter = Control.MOUSE_FILTER_IGNORE
					boxToUse.alignment = BoxContainer.ALIGNMENT_CENTER
					boxToUse.set("theme_override_constants/separation", 20)
					lockBox.set('theme_override_styles/panel', preload("res://content/techtree/panels/panel_lockgroup_open.tres"))
					lockGroupBoxes[lockGroupId] = boxToUse
					lockBox.add_child(boxToUse)
					box.add_child(lockBox)
			else:
				boxToUse = box
			
			# Add an empty tech to align vertically
			if i > 2 and techs.has(tech["predecessors"][0]) and techs[tech["predecessors"][0]]["index"] > index and tier.size() < biggestTierSize:
				for _n in range(techs[tech["predecessors"][0]]["index"] - index):
					techs[techId]["index"] = index+1
					var empty = preload("res://content/techtree/EmptyTech.tscn").instantiate()
					box.add_child(empty)
					box.move_child(empty, index)
					index += 1

			var panel = preload("res://content/techtree/Tech2.tscn").instantiate()
			panel.build(techId, i)
			panel.track = self
			techPanels[techId] = panel
			panelsOfTier.append(panel)
			boxToUse.add_child(panel)
			panel.connect("focus_entered", focusListener.technologyFocussed.bind(panel))
			panel.connect("focus_entered", techFocussed.bind(panel))
			panel.connect("focus_exited", Callable(focusListener, "techUnfocussed").bind(panel))
			panel.connect("gui_input", Callable(focusListener, "techInput").bind(panel))
			panel.connect("resized", Callable(self, "set").bind("dirty", true))

			index += 1

		find_child("Tiers").add_child(box)
		topTechPanelsByTier.append(panelsOfTier.front())
		bottomTechPanelsByTier.append(panelsOfTier.back())
		panelsByTier.append(panelsOfTier)
		rightTechPanels = panelsOfTier
		prevTier = tier
	
	# store information about the edges
	var lastTier := []
	for tier in techsByTier:
		for techId in tier:
			if techs[techId].has("predecessors"):
				var predecessors = techs[techId].get("predecessors")
				for r in predecessors:
					if lastTier.has(r):
						# a tech can have "any predecessor", where not every possible predecessor is there 
						edges.append([r, techId])
		lastTier = tier

func getValidPredecessorCount(predecessors):
	var count = 0
	for t in predecessors:
		if techs.has(t):
			count += 1
	return count
	
func techFocussed(panel):
	for c in get_tree().get_nodes_in_group("techpanel"):
		if c.state != 3:
			c.hideLockGroup()
		
	if not techs[panel.techId].has("lockGroup"):
		return
		
	var lockGroupId = techs[panel.techId].get("lockGroup").front()
	var box = lockGroupBoxes[lockGroupId]
	var groupLocked := false
	for tech in box.get_children():
		if GameWorld.boughtUpgrades.has(tech.techId):
			groupLocked = true
	for tech in box.get_children():
		if tech.state == 2:
			tech.hideLockGroup()
		elif not groupLocked and (tech.state == 2 or panel != tech):
			tech.showLockGroup()

func sortByPredecessorIndex(a,b):
	if not prevTier:
		return false

	var up1 = techs[a]
	var up2 = techs[b]
	
	if up1.has("predecessors") and up2.has("predecessors"):
		var r1 = up1.get("predecessors")
		var p1 = 999
		for pred in r1:
			var index = prevTier.find(pred)
			if index >= 0:
				p1 = min(p1, index)
		var r2 = up2.get("predecessors")
		var p2 = 999
		for pred in r2:
			var index = prevTier.find(pred)
			if index >= 0:
				p2 = min(p2, index)
		return p1 < p2
	return false

func updateState():
	for techPanelId in techPanels:
		var techPanel = techPanels[techPanelId]
		techPanel.updateState()
		if techPanel.isLocked():
			var tech = techs[techPanelId]
			if tech.has("lockGroup"):
				var lockGroupId = tech.get("lockGroup").front()
				if lockGroupBoxes.has(lockGroupId):
					var box = lockGroupBoxes.get(lockGroupId)
					box.get_parent().set('theme_override_styles/panel', preload("res://content/techtree/panels/panel_lockgroup_closed.tres"))

func updateLines():
	for c in linesHolder.get_children():
		linesHolder.remove_child(c)
		c.queue_free()
	linesByTech.clear()
	
	var line_width = 8
	
	for edge in edges:
		curve.clear_points()
		
		if not edge[0]:
			continue
		
		# 782, 88
		# 753, 71
		# 194, 114
		
		var t1 = techPanels[edge[0]]
		var t2 = techPanels[edge[1]]
		var t1BaseSize = t1.size # tried to normalize by scale here, does not work
		var t2BaseSize = t2.size
		var t2OffsetX = -40 if t2.hasMultiplePredecessorLock() else -15
		var t1BasePos = t1.global_position + (t1.size * t1.scale - t1.size) * 0.5
		var t2BasePos = t2.global_position + (t2.size * t2.scale - t2.size) * 0.5
		var p1 = t1BasePos + Vector2(t1BaseSize.x - 20, t1BaseSize.y * 0.5 - line_width) - global_position
		var p2 = t2BasePos + Vector2(t2OffsetX, t2BaseSize.y * 0.5 - line_width) - global_position
		if t2.focus_neighbor_left.is_empty():
			t2.focus_neighbor_left = t1.get_path()
		if t1.focus_neighbor_right.is_empty():
			t1.focus_neighbor_right = t2.get_path()
		else:
			# switch to a neighbor that is actually closer
			var currentNeighbor = get_tree().root.get_node(t1.focus_neighbor_right)
			if abs(t1.global_position.y - t2.global_position.y) < abs(t1.global_position.y - currentNeighbor.global_position.y):
				t1.focus_neighbor_right = t2.get_path()
			
		curve.add_point(p1, vIn, vOut)
		curve.add_point(p2, vIn, vOut)
		
		var l := Line2D.new()
		l.z_index = 0
		l.texture_mode = Line2D.LINE_TEXTURE_TILE
		l.end_cap_mode = Line2D.LINE_CAP_ROUND
		l.begin_cap_mode = Line2D.LINE_CAP_ROUND
		l.antialiased = true
		l.width = line_width
		l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		l.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		l.material = preload("res://content/techtree/common/marching-ants-material.tres")
		for point in curve.get_baked_points():
			l.add_point(point)
		linesHolder.add_child(l)
		linesByTech.append([edge[0], edge[1], l])
	
	Style.init(linesHolder)
	updateLineColors()

func updateLineColors():
	for line in linesByTech:
		if GameWorld.lockedUpgrades.has(line[0]) or GameWorld.lockedUpgrades.has(line[1]):
			line[2].texture = preload("res://content/techtree/common/line-locked.png")
		elif techPanels[line[0]].state != 0:
			if techPanels[line[1]].state != 0:
				line[2].texture = preload("res://content/techtree/common/line-bought.png")
			else:
				line[2].texture = preload("res://content/techtree/common/line-available.png")
		else:
			line[2].texture = preload("res://content/techtree/common/line-unavailable.png")

func _on_TechTrack_sort_children():
	dirty = true
