extends Container

var isIn := false

var animationDone:bool
var focussedPanel

var prefixMappings := {}
var rootsToIgnore := []
var defaultFontColor

func _ready():
	position.y += size.y
	find_child("TechTree").build(prefixMappings, rootsToIgnore)
	
	find_child("Inventory").visible = true
	find_child("LabelIron").text = str(Data.getInventory(CONST.IRON))
	find_child("LabelWater").text = str(Data.getInventory(CONST.WATER))
	find_child("LabelSand").text = str(Data.getInventory(CONST.SAND))

	Data.listen(self, "inventory.iron")
	Data.listen(self, "inventory.water")
	Data.listen(self, "inventory.sand")
	
	Style.init(self)
	
	#duplicate to override color
	%LabelIronCost.label_settings = %LabelIronCost.label_settings.duplicate()
	%LabelWaterCost.label_settings = %LabelWaterCost.label_settings.duplicate()
	%LabelSandCost.label_settings  =%LabelSandCost.label_settings.duplicate()
	
	defaultFontColor = %LabelIronCost.label_settings.font_color

# Add a prefix for instance specific upgrades.
# Additionally make sure to only show the relevant upgrade tree, ignoring that of other instance types (like engineer should see no assessor upgrade tree).
func addPrefixMapping(generalPrefix:String, instancePrefix:String):
	prefixMappings[generalPrefix] = instancePrefix
	if Data.loadoutKeepers.has(generalPrefix):
		for keeper in Data.loadoutKeepers:
			if keeper != generalPrefix:
				rootsToIgnore.append(keeper)
	if Data.loadoutDomes.has(generalPrefix):
		for dome in Data.loadoutDomes:
			if dome != generalPrefix:
				rootsToIgnore.append(dome)

func propertyChanged(property:String, oldValue, newValue):
	match property:
		"inventory.iron":
			find_child("LabelIron").text = str(clamp(newValue, 0, 999))
		"inventory.water":
			find_child("LabelWater").text = str(clamp(newValue, 0, 999))
		"inventory.sand":
			find_child("LabelSand").text = str(clamp(newValue, 0, 999))
	updateCostLabels()

func focus():
	find_child("TechTree").focus()

func setFocussedTechPanel(p):
	focussedPanel = p

func getFocussedTechPanel():
	return focussedPanel

func moveIn():
	if isIn:
		return
	
	visible = true
	isIn = true
	animationDone = false
	
	$Tween.interpolate_property(self, "position:y", position.y, get_viewport_rect().size.y-size.y, 0.3, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.interpolate_callback(self, 0.4, "set", "animationDone", true)
	$Tween.start()
	
func moveOut():
	if not isIn:
		return
	
	isIn = false
	
	Data.unlisten(self, "inventory.iron")
	Data.unlisten(self, "inventory.water")
	Data.unlisten(self, "inventory.sand")
	Data.apply("dome.potentialrepair", 0)

	$Tween.interpolate_property(self, "position:y", position.y, get_viewport_rect().size.y, 0.3, Tween.TRANS_CUBIC, Tween.EASE_IN)
	$Tween.interpolate_callback(self, 0.5, "queue_free")
	$Tween.start()
	
	if focussedPanel:
		focussedPanel.release_focus()
	focussedPanel = null
	
func buyUpgrade():
	if animationDone:
		find_child("TechTree").buyCurrentUpgrade()
		updateCostLabels()

# Get all visible properties of the root tech
func getRootTechs(techPanel) -> Dictionary:
	var allProps := {}
	var rootTech = GameWorld.upgrades.get(techPanel.track.rootTechId)
	if rootTech and rootTech.has("propertychanges"):
		for prop in rootTech.propertychanges:
			if prop.hidden:
				continue
			allProps[prop.key] = prop

	return allProps

func removeHiddenProperties(techId:String, allProps:Dictionary) -> Dictionary:
	var newProps = {}

	for p in allProps:
		if not isHidden(techId, p):
			newProps[p] = allProps[p]
	
	return newProps

func isHidden(techId:String, property:String) -> bool:
	var tech = GameWorld.upgrades.get(techId)
	
	if tech.has("propertychanges"):
		for p in tech.propertychanges:
			if p.key == property:
				return p.hidden

	if tech.has("predecessors"):
		var isHidden = true
		for pred in tech.predecessors:
			isHidden = isHidden and isHidden(pred, property)
		return isHidden
			
	return false
	
func getAncestors(techId:String) -> Array:
	var ancestors := []
	
	var tech = GameWorld.upgrades.get(techId)
	
	# Root node
	if tech and not tech.has("predecessors"):
		return []
	
	if tech.tier == 2:
		for pred in tech.predecessors:
			if not ancestors.has(pred): ancestors.append(pred)
		return ancestors
		
	if tech.tier == 1:
		if not ancestors.has(tech.id): ancestors.append(tech.id)
		return ancestors
	
	for pred in tech.predecessors:
		if not ancestors.has(pred) and GameWorld.upgrades.has(pred):
			var ancestorPreds = getAncestors(pred)
			for ancestorPred in ancestorPreds:
				if not ancestors.has(ancestorPred):
					ancestors.append(ancestorPred)
	
	return ancestors
	
# Get all property changes for techs descending from these ancestors
func getCoreProperties(ancestors:Array, techs:Dictionary, maxTier) -> Dictionary:
	var allProps = {}
	
	# Search all children of these ancestors
	for a in ancestors:
		if not techs.has(a):
			continue

		var tech = GameWorld.upgrades.get(a)
		
		if techs[a].children.size():
			var childProps = getCoreProperties(techs[a].children, techs, maxTier)
			for p in childProps:
				allProps[p] = childProps[p]

		if tech and tech.has("propertychanges"):
			for p in tech.propertychanges:
				if p.hidden:
					continue
				if tech.has("repeatable"):
					continue
				allProps[p.key] = p
	
	return allProps
	
func _on_TechTree_techFocussed(techPanel) -> void:
	if not isIn:
		return
	
	find_child("TechTitle").text = techPanel.title
	find_child("TechDescription").text = tr(techPanel.explanationBb)
	
	# clean old state
	var bonusSection = find_child("BonusSection")
	for c in bonusSection.get_children():
		c.free()

	# This tech
	var tech = GameWorld.upgrades.get(techPanel.techId)
	
	# Get all core techs
	var ancestors := getAncestors(techPanel.techId)
	var allProps := getCoreProperties(ancestors, techPanel.track.techs, tech.tier)
	allProps = removeHiddenProperties(techPanel.techId, allProps)
	
	# Override with properties of this tech
	var thisProps := []
	for prop in techPanel.propertyChanges:
		if prop.hidden:
			continue
		prop = prop.duplicate()
		allProps[prop.key] = prop
		thisProps.append(prop.key)

	# Controls which properties are highlighted
	# The root tier is never highlighted
	# Properties that have already been purchased are not highlighted
	# Repeatable properties are always highlighted
	var highlight = GameWorld.upgrades.get(techPanel.techId).tier != 0
	if tech and tech.has("repeatable"):
		highlight = true
	var alreadyBought = GameWorld.boughtUpgrades.has(techPanel.techId)
	
	# build property changes
	var regex = RegEx.new()
	regex.compile("\\{.*\\}[^\\s]*")
	var regex2 = RegEx.new()
	regex2.compile("\\{.*\\}")
	
	# Sort keys so that the property change labels don't jump around
	var sortedKeys = allProps.keys()
	sortedKeys.sort()
	
	for p in sortedKeys:
		var propertyChange = allProps[p]
		if propertyChange.hidden:
			continue
		
		var outString = null
		var statString := ""
		var newValueString := ""
		var translationKey:String
		if propertyChange.key.count(".") == 2:
			translationKey = "properties." + propertyChange.key.substr(propertyChange.key.find(".") + 1)
		else:
			translationKey = "properties." + propertyChange.key
		var template = tr(translationKey)
		if template != translationKey:
			var result = regex.search(template)
			if not result or result.strings.is_empty():
				# No placeholder found, so just show the template
				outString = template
				# Debug
				#if thisProps.has(propertyChange.key):
				#	printt(tech.id, p, template)
				# Hide props without values if not on this tech
				if not thisProps.has(propertyChange.key):
					continue
			else:
				# We found a placeholder
				var placeholder = result.strings[0]
				var after
				var before
				var replacement := ""
				var unit := ""
				var dotPos = placeholder.find(".")
				var isPercent = placeholder.find(".percent") != -1

				# Remove the placeholder {...} template from the label
				outString = regex.sub(template, "").strip_edges()
				outString = outString.replace("  ", " ")
				
				var beforeAfter = getBeforeAfterValues(propertyChange, tech.id)
				before = beforeAfter["before"]
				after = beforeAfter["after"]

				# Get units string if there's a dot
				if dotPos > 1:
					unit = placeholder.substr(1, dotPos-1)
				
				# Modify before/after if it's a percentage
				if isPercent:
					after = int(after * 100)
					unit = "%"
					if before and not propertyChange.multiplicative:
						before = int(before * 100)
				
				# Format stat string for ints and reals
				if (typeof(before) == TYPE_INT or typeof(before) == TYPE_FLOAT):
					var valueTemplate:String
					if before == int(before):
						valueTemplate = "%d"
					else:
						valueTemplate = "%0.2f"

					if propertyChange.multiplicative:
						replacement += valueTemplate % [before]
					else:
						replacement += valueTemplate % [before] + unit
						
					if highlight and thisProps.has(propertyChange.key):
						statString = regex2.sub(placeholder, replacement)

				# Already bought it so just show the current value
				if alreadyBought and not is_repeatable(tech):
					statString = ""
					highlight = false
					after = Data.of(propertyChange.key)
					if isPercent:
						after = int(after * 100)
						unit = "%"

				if after == int(after):
					replacement = "%d" % after
				else:
					replacement = "%0.2f" % after
				replacement = regex2.sub(placeholder, replacement)
				newValueString += replacement + unit

			# Update BonusSection grid UI
			var icon = TextureRect.new()
			icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			bonusSection.add_child(icon)

			var label: Label = Label.new()
			label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
			label.autowrap_mode = TextServer.AutowrapMode.AUTOWRAP_WORD_SMART
			label.size_flags_horizontal = SIZE_EXPAND_FILL
			label.text = outString
			bonusSection.add_child(label)
			
			var labelStat = Label.new()
			labelStat.text = str(statString)
			labelStat.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT
			bonusSection.add_child(labelStat)
			
			var centerContainer = CenterContainer.new()
			if statString:
				var changeIcon = TextureRect.new()
				changeIcon.texture = load("res://content/techtree/common/change-icon.png")
				centerContainer.add_child(changeIcon)
			bonusSection.add_child(centerContainer)

			var labelNew = Label.new()
			labelNew.text = str(newValueString)
			labelNew.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT
			bonusSection.add_child(labelNew)

			# Highlight properties of this tech only
			# Core techs that aren't modified in this tech are not highlighted
			if highlight and thisProps.has(propertyChange.key):
				var markerColor = Style.mapColor(Color("D89DDC"))
				label.set("theme_override_colors/font_color", markerColor)
				labelStat.set("theme_override_colors/font_color", markerColor)
				labelNew.set("theme_override_colors/font_color", markerColor)
				icon.texture = preload("res://content/techtree/common/star.png")
			else:
				icon.texture = preload("res://content/techtree/common/dot.png")

			Style.init(bonusSection)
	
	focussedPanel = techPanel
	updateCostLabels()

func is_repeatable(tech) -> bool:
	if not tech.has("repeatable"):
		return false
	
	var repeatableTimes = -1
	for change in tech.get("repeatable"):
			if change.keyClass == "times":
				repeatableTimes = change.value
	return repeatableTimes != 0

#	if techPanel.state == 3:
#		find_node("TechInfo").find_node("lockIcon").show()
#	else:
#		find_node("TechInfo").find_node("lockIcon"q).hide()

# Compute all of the upgrades backwards until you get to an ugprade
# that has already been purchased or is an absolute value
# Explore multiple predecessors (e.g. orchard overcharge buff duration)
# For cumulative, compute what the new AFTER value would be
# For absolute, compute the new BEFORE value
func getBeforeAfterValues(propertyChange, techId):
	var before = null
	var after = null
	var values = getPropertyValue(propertyChange.key, techId)
	
	if not propertyChange.doesRepair:
		before = values["before"]
	after = values["after"]
	
	return { "before": before, "after": after }

func getPropertyValue(propertyKey, techId, depth = 0):
	var tech = GameWorld.upgrades.get(techId)
	
	if not tech.has("repeatable") and (GameWorld.boughtUpgrades.has(techId) or not tech.has("predecessors")):
		return { "before": null, "after": Data.of(propertyKey) }
		
	if not tech["predecessors"].is_empty():
		#in case of multiple predecessors go down the first predecessor that was purchased
		var target = null
		for x in tech["predecessors"]:
			if GameWorld.boughtUpgrades.has(x):
				target = x
				break
		if not target:
			target = tech["predecessors"].front()
				
		var values = getPropertyValue(propertyKey, target)
		values["before"] = values["after"]
		
		if tech and tech.has("propertychanges"):
			for prop in tech["propertychanges"]:
				if prop.key == propertyKey:
					if prop.cumulative:
						values["after"] += prop.value
					elif prop.multiplicative:
						values["after"] *= prop.value
					else:
						values["after"] = prop.value
		
		return values
	
	Logger.error("invalid state of property, can't find before and after values", "TechTreePopup.getPropertyValue", {"propertyKey": propertyKey, "techId": techId, "depth": depth})
	return { "before": "error", "after": "error"}

func updateCostLabels():
	find_child("LabelIronCost").text = ""
	find_child("LabelWaterCost").text = ""
	find_child("LabelSandCost").text = ""
	
	if not focussedPanel:
		return
	
	var upgrade = GameWorld.upgrades[focussedPanel.techId]
	var costs = upgrade.get("cost", [])
	for costType in costs:
		var cost = costs[costType]
		var newInventory = int(Data.getInventory(costType)) - int(cost)
		var color = defaultFontColor
		if GameWorld.boughtUpgrades.has(focussedPanel.techId) and not upgrade.has("repeatable"):
			newInventory = 0
		if newInventory < 0:
			color = Style.FONT_COLOR_WARNING
		find_child("Label"+costType.capitalize()+"Cost").text = "%s" % cost
		find_child("Label"+costType.capitalize()+"Cost").label_settings.font_color = color
