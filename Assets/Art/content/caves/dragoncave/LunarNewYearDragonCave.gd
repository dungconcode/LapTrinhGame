extends "res://content/caves/Cave.gd"

var hasEgg := true
var needsCobalt := true

func _ready():
	super._ready()
	find_child("Egg").visible = false
	Style.init(find_child("Egg"))
	find_child("Dragon").visible = false
	find_child("CobaltDelivered").visible = false

func serialize()->Dictionary:
	var data = super.serialize()
	data["hasEgg"] = hasEgg
	data["needsCobalt"] = needsCobalt
	return data
	
func deserialize(data: Dictionary):
	super.deserialize(data)
	hasEgg = data["hasEgg"]
	needsCobalt = data["needsCobalt"]
	if needsCobalt:
		find_child("Egg").visible = false
	else:
		find_child("CobaltMarker").queue_free()
		if hasEgg:
			find_child("Egg").visible = true
		else:
			find_child("Egg").queue_free()
	
	if currentState == State.REVEALED:
		find_child("AmbSound").play()

func onRevealed():
	find_child("DiscoverSound").play()
	find_child("AmbSound").play()

func _on_ResourceGrabber_grabbed_resource():
	needsCobalt = false
	var dragon = find_child("Dragon")
	dragon.visible = true
	dragon.play()
	dragon.connect("frame_changed", Callable(self, "_on_Dragon_frame_changed").bind(dragon))
	var pos = dragon.global_position
	dragon.get_parent().remove_child(dragon)
	Level.map.addDrop(dragon)
	dragon.global_position = pos
	find_child("Tail").play()
	find_child("ActivatedSound").play()
	find_child("CobaltDelivered").visible = true
	

func _on_Dragon_frame_changed(dragon):
	if dragon.frame == 26:
		find_child("Lamp").play()
		find_child("Egg").visible = true
		find_child("CobaltMarker").queue_free()

func _on_Egg_egg_taken():
	find_child("Lamp").pause()
	find_child("Lamp").frame = 0
	hasEgg = false
