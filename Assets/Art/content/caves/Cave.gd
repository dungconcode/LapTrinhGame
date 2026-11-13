extends Node2D

@export var biome := "" # (String, "", "grey", "green", "red", "blue", "yellow")
@export var minLayer := 1
@export var maxCount := 1
@export var minRelativeDepth := 0.0
@export var maxRelativeDepth := 0.8

enum State {HIDDEN, REVEALED}
var currentState = State.HIDDEN

var tileCoords := []
var coord:Vector2

func _ready():
	var a = find_child("AlphaMap")
	if a and Level.map:
		Level.map.addSpriteToBGAlpha(a)
	Style.init(self)

func serialize()->Dictionary:
	var data = {
		"coord": var_to_str(coord),
		"tileCoords": var_to_str(tileCoords),
		"currentState": currentState,
		"biome": biome
	}
	
	data["meta.priority"] = 100
	data["meta.kind"] = "cave"

	return data
	
func deserialize(data: Dictionary):
	coord = BackwardCompatibilityUtils.str_to_var(data["coord"])

	tileCoords = BackwardCompatibilityUtils.str_to_var(data["tileCoords"])
	biome = data["biome"]
	Level.map.addLandmark(coord, self)
	currentState = int(data["currentState"]) as State
	
	hide()
	if currentState == State.REVEALED:
		show()
	
func updateUsedTileCoords():
	tileCoords.clear()
	for x in ceil($Sprites.size.x / float(GameWorld.TILE_SIZE)):
		for y in ceil($Sprites.size.y / float(GameWorld.TILE_SIZE)):
			tileCoords.append(Vector2(x,y))

func getPixelSize() -> Vector2:
	return $Sprites.size

func place(c:Vector2):
	coord = c
	position = coord * GameWorld.TILE_SIZE - Vector2(GameWorld.TILE_SIZE, GameWorld.TILE_SIZE)*0.5
	visible = false

func tileRevealed(tileCoord:Vector2):
	if currentState == State.HIDDEN:
		currentState = State.REVEALED
		onRevealed()
		visible = true

func disableParallax():
	var s = find_child("Sprites")
	if s and s.has_method("disableParallax"):
		s.disableParallax()

func onRevealed():
	pass

func canFocusUse(keeper:Keeper) -> bool:
	return false

func useHold(keeper:Keeper) -> bool:
	return useHit(keeper)

func useHit(keeper:Keeper) -> bool:
	return false

func isRevealed() -> bool:
	return currentState != State.HIDDEN
