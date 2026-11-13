extends Control

const BORDER_SPRITE = preload("res://content/hud/HudBorder.tscn")
const layouts := {
	1:  Vector2(0,0),
	2:  Vector2(1,0),
	3:  Vector2(2,0),
	4:  Vector2(3,0),
	5:  Vector2(0,1),
	6:  Vector2(1,1),
	7:  Vector2(2,1),
	8:  Vector2(3,1),
	9:  Vector2(0,2),
	10:  Vector2(1,2),
	11:  Vector2(2,2),
	12:  Vector2(3,2),
	13:  Vector2(0,3),
	14:  Vector2(1,3),
	15:  Vector2(3,3),
}

var hudElements := []
var sortedLocations := []
var availableLocations:Array

var isIn := true
var shouldRebuild := false

var borderSprites := {} # all hud borders by coord

var playerId:String

@onready var Layout:TileMap = $BorderSprites/Layout

func init(keeper:Keeper):
	self.playerId = keeper.playerId

	for x in range(0,20):
		for y in range(0,20):
			sortedLocations.append(Vector2(x,-y))
	sortedLocations.sort_custom(Callable(self, "sortByPlacingPriority"))
	availableLocations = sortedLocations.duplicate()
	addHudElement(preload("res://content/hud/wavemeter/WaveMeter.tscn").instantiate())

func sortByPlacingPriority(a:Vector2,b:Vector2):
	return sqrt(pow(a.x,2)*pow(a.y,2)) +a.length() < sqrt(pow(b.x,2)*pow(b.y,2)) + b.length()

func updateBorderSprite(x:int, y:int):
	var key = Vector2(x, y)
	var borderSprite:Sprite2D = borderSprites.get(key, null)
	var borderLayout := 0
	
	# the "or" part takes care of letting the special tiles like iron make their own border, instead of being covered through the tile system
	var r_tl:int = Layout.get_cell_source_id(MapData.DEFAULT_LAYER, Vector2i(x, y))
	var r_tr:int = Layout.get_cell_source_id(MapData.DEFAULT_LAYER, Vector2i(x + 1, y))
	var r_br:int = Layout.get_cell_source_id(MapData.DEFAULT_LAYER, Vector2i(x + 1, y + 1))
	var r_bl:int = Layout.get_cell_source_id(MapData.DEFAULT_LAYER, Vector2i(x, y + 1))
	borderLayout = int(r_tl > -1) * 1 + int(r_tr > -1) * 2 + int(r_br > -1) * 4 + int(r_bl > -1) * 8 # <- sorry
	
	if borderLayout > 0:
		if not borderSprite:
			borderSprite = BORDER_SPRITE.instantiate()
			borderSprite.position.x = x * Layout.tile_set.tile_size.x + Layout.tile_set.tile_size.x
			borderSprite.position.y = y * Layout.tile_set.tile_size.y
			$BorderSprites.add_child(borderSprite)
			borderSprites[key] = borderSprite
			Style.init(borderSprite)
		if not borderSprite.has_meta("type") or borderSprite.get_meta("type") != borderLayout:
			borderSprite.set_meta("type", borderLayout)
			borderSprite.set_frame_coords(layouts[borderLayout])
	elif borderSprite:
		borderSprite.queue_free()
		borderSprites.erase(key)

func _process(delta):
	if shouldRebuild:
		rebuildHud()
		shouldRebuild = false

func addHudElement(element):
	# Don't add duplicate HUD elements
	element.playerId = self.playerId
	for e in hudElements:
		if e.name == element.name:
			element.free()
			return e
	hudElements.append(element)
	shouldRebuild = true
	return element

func removeHudElement(data:Dictionary):
	if not data.has("hud"):
		return null
	
	var scene = load("res://"+data.get("hud"))
			
	if scene:
		var element = scene.instantiate()
		# Don't add duplicate HUD elements
		for e in hudElements:
			if e.name == element.name:
				e.queue_free()
				hudElements.erase(e)
				shouldRebuild = true
				return
	else:
		Logger.error("hud element does not exist", "hud.removeHudElement", data)
		return null

func place(element:HudElement):
	var bestRating := 99999999.0
	var bestLocation:Vector2
	for i in range(0, min(50, availableLocations.size())):
		var location = availableLocations[i]
		if not canBePlaced(element, location):
			continue
		var rx = pow(element.layoutWeights.x * location.x, 2)
		var ry = pow(element.layoutWeights.y * location.y, 2)
		var rating = 0.5*(rx+ry) + sqrt(rx*ry)
		if rating < bestRating:
			bestRating = rating
			bestLocation = location
	if element.get_parent() == null:
		$HudElements.add_child(element)
		element.init()
		element.connect("request_rebuild", Callable(self, "set").bind("shouldRebuild", true))
	element.position = (bestLocation-Vector2(0, element.element_size.y)) * Vector2(Layout.tile_set.tile_size)
	
	for w in range(0, element.element_size.x):
		for h in range(0, element.element_size.y):
			var cx = bestLocation.x+w
			var cy = bestLocation.y-h
			Layout.set_cell(MapData.DEFAULT_LAYER, Vector2i(cx, cy), 0, Vector2i(0,0))
			availableLocations.erase(Vector2(cx,cy))
			if cx == 0:
				Layout.set_cell(MapData.DEFAULT_LAYER, Vector2i(cx-1, cy), 0, Vector2i(0,0))
			if cy == 0:
				Layout.set_cell(MapData.DEFAULT_LAYER, Vector2i(cx, cy+1), 0, Vector2i(0,0))
	for w in range(-1, element.element_size.x+1):
		for h in range(-1, element.element_size.y+1):
			updateBorderSprite(bestLocation.x+w, bestLocation.y-h)

func canBePlaced(element:HudElement, p:Vector2):
	for w in range(0, element.element_size.x):
		for h in range(0, element.element_size.y):
			if Layout.get_cell_source_id(MapData.DEFAULT_LAYER, Vector2i(p.x+w, p.y-h)) != -1:
				return false
	return true

func rebuildHud():
	availableLocations = sortedLocations.duplicate()
	Layout.clear()
	for c in borderSprites:
		borderSprites[c].queue_free()
	borderSprites.clear()
	hudElements.sort_custom(Callable(self, "sortByPriority"))
	for element in hudElements:
		place(element)
	
	if not isIn:
		position.y = get_viewport_rect().size.y + 6 * 6 * scale.y

func sortByPriority(a,b):
	return a.layoutPriority < b.layoutPriority

func moveIn():
	if isIn:
		return
	
	if shouldRebuild:
		rebuildHud()
		shouldRebuild = false

	isIn = true
	$Tween.remove_all()
	$Tween.interpolate_property(self, "position:y", position.y, get_viewport_rect().size.y, 0.3, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.start()
	
func moveOut():
	if not isIn:
		return
	
	if shouldRebuild:
		rebuildHud()
		shouldRebuild = false

	var y = Layout.get_used_rect().size.y
	isIn = false
	$Tween.remove_all()
	$Tween.interpolate_property(self, "position:y", position.y, get_viewport_rect().size.y + y * 6 * scale.y, 0.3, Tween.TRANS_CUBIC, Tween.EASE_IN)
	$Tween.start()

func immediateMoveOut():
	if not isIn:
		return
	
	if shouldRebuild:
		rebuildHud()
		shouldRebuild = false

	isIn = false
	position.y = get_viewport_rect().size.y + 6 * 6 * scale.y
