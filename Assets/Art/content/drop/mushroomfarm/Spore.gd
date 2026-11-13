extends Carryable

func _ready():
	super._ready()
	Style.init(self)

func _on_body_entered(body: Node) -> void:
	if body is Tile and not isCarried() and not body.hasTileOverlay():
		body.setTileOverlay(Data.TILE_OVERLAY_MYZEL)
		var s = $InfectSound
		remove_child(s)
		get_parent().add_child(s)
		s.play()
		queue_free()
