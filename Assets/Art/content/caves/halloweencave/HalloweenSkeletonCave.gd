extends "res://content/caves/Cave.gd"

var hasSkeleton := true

func _ready():
	super._ready()
	find_child("Skeleton3D").play()
	
	$Explosion.visible = false

func serialize()->Dictionary:
	var data = super.serialize()
	data["hasSkeleton"] = hasSkeleton
	return data
	
func deserialize(data: Dictionary):
	super.deserialize(data)
	hasSkeleton = data["hasSkeleton"]
	find_child("Skeleton3D").visible = hasSkeleton
	if currentState == State.REVEALED:
		find_child("AmbSound").play()

func onRevealed():
	find_child("AmbSound").play()
	find_child("DiscoverySound").play()

func canFocusUse(keeper:Keeper) -> bool:
	return hasSkeleton and keeper.techId == "keeper1"

func useHold(keeper:Keeper) -> bool:
	return useHit(keeper)

var keeper
func useHit(keeper:Keeper) -> bool:
	if not hasSkeleton:
		return false
	
	self.keeper = keeper
	hasSkeleton = false
	keeper.externallyMoved = true
	keeper.move *= 0
	$Tween.interpolate_property(keeper, "position", keeper.position, $Usable.global_position, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	$Tween.interpolate_callback(self, 0.3, "takeSkeleton")
	$Tween.start()
	return true

func _on_Explosion_animation_finished():
	$Explosion.visible = false

func takeSkeleton():
	find_child("ActivatedSound").play()
	keeper.externallyMoved = false
	$Explosion.visible = true
	$Explosion.frame = 0
	$Explosion.play()

func _on_Explosion_frame_changed():
	if $Explosion.frame == 2:
		find_child("Skeleton3D").visible = false
		if keeper and keeper.techId == "keeper1":
			keeper.setSkin("skin3")
			GameWorld.newSkinsToUnlock.append("skin3")
