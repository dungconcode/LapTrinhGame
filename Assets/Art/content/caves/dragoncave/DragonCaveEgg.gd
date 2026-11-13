extends Sprite2D

signal egg_taken

func canFocusUse(keeper:Keeper) -> bool:
	return visible

func useHold(keeper:Keeper) -> bool:
	return useHit(keeper)

func useHit(keeper:Keeper) -> bool:
	var gizmo = preload("res://content/drop/egg/Egg.tscn").instantiate()
	gizmo.position = global_position
	gizmo.forcePetId = "pet8"
	Style.init(gizmo)
	Level.map.addDrop(gizmo)
	keeper.attachCarry(gizmo)
	visible = false
	emit_signal("egg_taken")
	queue_free()
	return true
