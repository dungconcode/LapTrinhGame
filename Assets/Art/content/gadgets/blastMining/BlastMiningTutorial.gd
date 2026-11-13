extends Tutorial

func _ready() -> void:
	super._ready()

func process_trigger(delta:float) -> bool:
	if keeper.isInsideDome and not keeper.isInsideStation:
		return true
	return false

func process_confirm(delta:float):
	if not tutorialParent.hasMine():
		confirm()
