extends Node2D

@export var GIZMO_SCENE: PackedScene
@export var type := "chamber"

enum State {HIDDEN, REVEALED, OPENING, OPEN, EMPTY}
var currentState = State.HIDDEN

var tileCoords := []
var coord:Vector2

var chamberType

func _ready():
	Style.init(self)
	
	$TileCover.modulate = Style.TILE_COVER_MODULATE

func serialize()->Dictionary:
	var tileCover = {}
	if has_node("TileCover"):
		for c in $TileCover.get_used_cells(MapData.DEFAULT_LAYER):
			tileCover[var_to_str(c)] = $TileCover.get_cell_source_id(MapData.DEFAULT_LAYER, Vector2i(c.x, c.y))

	var data = {
		"coord": var_to_str(coord),
		"tileCoords": var_to_str(tileCoords),
		"currentState": currentState,
		"type": type,
		"tileCover": tileCover
	}
	
	data["meta.priority"] = 100
	data["meta.kind"] = "chamber"
	data["meta.chamberType"] = chamberType
	data["meta.scenepath"] = scene_file_path
	
	return data
	
func deserialize(data: Dictionary):
	coord = BackwardCompatibilityUtils.str_to_var(data["coord"])
	tileCoords = BackwardCompatibilityUtils.str_to_var(data["tileCoords"])
	currentState = int(data["currentState"]) as State
	type = data["type"]
	
	if currentState == State.HIDDEN:
		if not Level.map.tiles.has(coord) and Level.map.visibleTileCoords.has(coord):
			currentState = State.REVEALED
			Logger.error("chamber was hidden but should have been revealed", "Chamber.deserialize", data)
	
	$TileCover.clear()
	for key in (data["tileCover"] as Dictionary).keys():
		var c = BackwardCompatibilityUtils.str_to_var(key)
		var v = int(data["tileCover"][key])
		$TileCover.set_cell(MapData.DEFAULT_LAYER, c, v, Vector2i(0,0))

	# Clear tiles that are no longer covered
	# This is here because addChamber() sets resource tiles
	# for the chamber when it is instanced
	for c in tileCoords:
		var absCoord = coord + Vector2(c)
		if $TileCover.get_cell_source_id(MapData.DEFAULT_LAYER,c) == CONST.TILEMAP_INVALID_CELL:
			Level.map.onTileRemoved(absCoord)
		
	var remainingCells = $TileCover.get_used_cells(MapData.DEFAULT_LAYER).size()
	if remainingCells == 0 and currentState == State.REVEALED:
		onExcavated()

	if currentState == State.REVEALED:
		show()
		onRevealed()
	if currentState == State.OPEN or currentState == State.OPENING:
		show()
		currentState = State.OPEN
	if currentState == State.EMPTY:
		show()
		onUsed()
	
func place(c:Vector2):
	var cells = $TileCover.get_used_cells(MapData.DEFAULT_LAYER)
	for cell in cells:
		tileCoords.append(cell)
	coord = c
	position = coord * GameWorld.TILE_SIZE - Vector2(GameWorld.TILE_SIZE, GameWorld.TILE_SIZE)*0.5
	visible = false

func tileDestroyed(tileCoord:Vector2):
	var c = tileCoord - coord
	$TileCover.set_cell(MapData.DEFAULT_LAYER, Vector2i(c.x, c.y), -1)
	var remainingCells = $TileCover.get_used_cells(MapData.DEFAULT_LAYER).size()
#	Backend.event("chamber_worked", {"coord":tileCoords, "remainingCells":remainingCells})
	if remainingCells == 0 and currentState == State.REVEALED:
		onExcavated()
#		Backend.event("chamber_excavated", {"coord":tileCoords, "type": type})
		
func open():
	currentState = State.OPENING
	$TileCover.queue_free()
	for c in tileCoords:
		Level.map.removeTileDestroyedListener(self, coord + Vector2(c))
	onOpening()
	Backend.event("chamber", {"status": "opened", "coord":tileCoords, "type": type})

func onRevealed():
	pass

func onExcavated():
	pass

func onUsed():
	pass

func onOpening():
	pass

func addCable(cable):
	pass

func tileRevealed(tileCoord:Vector2):
	if currentState == State.HIDDEN:
		currentState = State.REVEALED
		onRevealed()
		visible = true
		Backend.event("chamber", {"status": "revealed", "coord":tileCoords, "type": type})

func canFocusUse(keeper:Keeper) -> bool:
	return currentState == State.OPEN

func useHold(keeper:Keeper) -> bool:
	return useHit(keeper)

func useHit(keeper:Keeper) -> bool:
	if currentState == State.OPEN:
		if GIZMO_SCENE:
			var gizmo = GIZMO_SCENE.instantiate()
			gizmo.position = find_child("GizmoSpawn").global_position
			Level.map.addDrop(gizmo)
			keeper.attachCarry(gizmo)
		currentState = State.EMPTY
		onUsed()
		Backend.event("chamber", {"status": "used", "coord":tileCoords, "type": type})
		return true
	else:
		return false

func getCenter() -> Vector2:
	return $Usable.position

func getTileType() -> int:
	return Data.TILE_GADGET

func isRevealed() -> bool:
	return currentState != State.HIDDEN
