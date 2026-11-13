extends Node2D

class_name Worldd

var walk_mediumPaths := {CONST.LEFT:[], CONST.RIGHT:[]}
var walk_largePaths := {CONST.LEFT:[], CONST.RIGHT:[]}
var walk_mediumPathOccupations := {}
var walk_largePathOccupations := {}

var tween:DeprecatedTween
var showSimpson := true

func _ready():
	for moveType in ["walk_medium", "walk_large"]:
		var nodeName = moveType.capitalize().replace(" ", "")
		var node = find_child(nodeName + "Paths")
		if not node:
			continue
		for c in node.get_children():
			if c.name.begins_with("LeftPath"):
				get(moveType + "Paths")[CONST.LEFT].append(c)
				get(moveType + "PathOccupations")[c] = []
			elif c.name.begins_with("RightPath"):
				get(moveType + "Paths")[CONST.RIGHT].append(c)
				get(moveType + "PathOccupations")[c] = []
	Style.init(self)
	
	var cg = find_child("Couchgag")
	if cg:
		if showSimpson and GameWorld.isUpgradeLimitAvailable("hostile"):
			var animations = cg.sprite_frames.get_animation_names()
			cg.play(animations[randi() % animations.size()])
			cg.frame = 0
		else:
			cg.queue_free()
	
	updateBackgroundVisibility()

func assignRandomPath(moveType:String, variant:String, monster):
	var occupations = get(moveType + "PathOccupations")
	var path:Path2D = getPath(moveType, variant)
	occupations[path].append(monster)
	monster.connect("died", Callable(self, "freePathOccupation").bind(moveType, path, monster))
	
	return path

func getPath(moveType:String, variant:String) -> Path2D:
	var paths:Array = get(moveType + "Paths").get(variant, [])
	var occupations = get(moveType + "PathOccupations")
	var path:Path2D = null
	var monsterCount := 9999
	for p in paths:
		var m = occupations[p].size()
		if m < monsterCount:
			path = p
			monsterCount = m
	
	return path

var sortOccupations
func getDefensivePaths(moveType:String, variant:String):
	var paths:Array = get(moveType + "Paths").get(variant, [])
	sortOccupations = get(moveType + "PathOccupations")
	var r = paths.duplicate()
	r.sort_custom(Callable(self, "sortByOccupations"))
	sortOccupations = null
	return r

func sortByOccupations(p1, p2):
	return sortOccupations[p1].size() > sortOccupations[p2].size()

func assignPathOccupation(moveType, path, monster):
	get(moveType + "PathOccupations")[path].append(monster)

func freePathOccupation(moveType, path, monster):
	get(moveType + "PathOccupations")[path].erase(monster)
	monster.disconnect("died", Callable(self, "freePathOccupation"))

func ambience() -> AudioStreamPlayer:
	return $Ambience as AudioStreamPlayer

func getFlyerPathProvider():
	return $FlyerPaths

func addBackgroundHub(hub):
	var bgh = find_child("BackgroundHub")
	if bgh:
		find_child("BackgroundHub").add_child(hub)
	else:
		Logger.error(name + " has no Background Hub Spot", "world.addBackgroundHub")

func domeImpact():
	var cg = find_child("Couchgag")
	if cg:
		cg.visible = false
		cg.queue_free()

func updateBackgroundVisibility():
	var bg = find_child("SimpleBackground")
	if bg:
		bg.visible = Options.disableWorldBackgrounds
