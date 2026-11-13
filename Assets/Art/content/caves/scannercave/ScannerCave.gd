extends "res://content/caves/Cave.gd"

var hasScanner := true
var activated := false
var grabs := 0

func _ready():
	super._ready()
	Style.init($Background/Left/Resource)
	Style.init($Background/Right/Resource)
	$Background/Left/Resource.visible = false
	$Background/Right/Resource.visible = false
	
	$Background.frame = 0

func serialize()->Dictionary:
	var data = super.serialize()
	data["hasScanner"] = hasScanner
	data["activated"] = activated
	data["grabs"] = grabs
	var leftRes = find_child("ResourceGrabberLeft")
	var rightRes = find_child("ResourceGrabberRight")
	if leftRes:
		data["resourceleftused"] = leftRes.spent
	else:
		data["resourceleftused"] = true
	if rightRes:
		data["resourcerightused"] = rightRes.spent
	else:
		data["resourcerightused"] = true
	return data
	
func deserialize(data: Dictionary):
	super.deserialize(data)
	hasScanner = data["hasScanner"]
	activated = data["activated"]
	grabs = data["grabs"]
	if hasScanner:
		var usedLeft = data.get("resourceleftused", false)
		var usedRight = data.get("resourcerightused", false)
		find_child("ResourceGrabberLeft").spent = usedLeft
		find_child("ResourceGrabberRight").spent = usedRight
		$Background/Left/Resource.visible = usedLeft
		$Background/Right/Resource.visible = usedRight
		if usedLeft:
			$Background/Left.play("idle")
		if usedRight:
			$Background/Right.play("idle")
		
		if grabs == 2 or (usedLeft and usedRight):
			$Background/Scanner/Spitze.play("spitze_idle")
			activated = true
		elif grabs == 1:
			$Background/Scanner.play("base_idle")
		if grabs >= 1:
			find_child("ActiveAmbSound").play()
	else:
		$Background.frame = 1
		$Background/Left.queue_free()
		$Background/Right.queue_free()
		$Background/Scanner.queue_free()

func canFocusUse(keeper:Keeper) -> bool:
	return hasScanner and activated

func useHold(keeper:Keeper) -> bool:
	return useHit(keeper)

func useHit(keeper:Keeper) -> bool:
	if not hasScanner:
		return false
	
	$ScannerTakenSound.play()
	hasScanner = false
	find_child("ActiveAmbSound").stop()
	$Background.frame = 1
	$Background/Left.queue_free()
	$Background/Right.queue_free()
	$Background/Scanner.queue_free()
	
	Data.apply("map.revealdistance", 2)
	
	Level.map.tileCoordsToReveal.append(Vector2(0, -1))
	Level.map.floodRevealTiles(true)
	Level.map.removeAllEmptyBorderTilesVisually() #force update rock textures for all borders
	return true

func _on_left_animation_looped() -> void:
	_leftAnimationFinishedCheck()

func _on_Left_animation_finished() -> void:
	_leftAnimationFinishedCheck()

func _leftAnimationFinishedCheck() -> void:
	if $Background/Left.animation == "start":
		$Background/Left.play("idle")

func _on_right_animation_looped() -> void:
	_rightAnimationFinishedCheck()

func _on_Right_animation_finished():
	_rightAnimationFinishedCheck()
	
func _rightAnimationFinishedCheck() -> void:
	if $Background/Right.animation == "start":
		$Background/Right.play("idle")

func _on_scanner_animation_looped() -> void:
	_scannerAnimationFinishedCheck()

func _on_Scanner_animation_finished():
	_scannerAnimationFinishedCheck()
	
func _scannerAnimationFinishedCheck() -> void:
	if $Background/Scanner.animation == "base_start":
		$Background/Scanner.play("base_idle")

func _on_spitze_animation_looped() -> void:
	_spitzeAnimationFinishedCheck()

func _on_Spitze_animation_finished():
	_spitzeAnimationFinishedCheck()
	
func _spitzeAnimationFinishedCheck() -> void:
	if $Background/Scanner/Spitze.animation == "spitze_start":
		$Background/Scanner/Spitze.play("spitze_idle")
		activated = true


func _on_ResourceGrabberRight_grabbed_resource():
	$Background/Right.play("start")
	$Background/Right/Resource.visible = true
	onResourceGrabbed()

func _on_ResourceGrabberLeft_grabbed_resource():
	$Background/Left.play("start")
	$Background/Left/Resource.visible = true
	onResourceGrabbed()

func onResourceGrabbed():
	grabs += 1
	if grabs == 1:
		find_child("ActiveAmbSound").play()
		$Background/Scanner.play("base_start")
	elif grabs >= 2:
		$Background/Scanner/Spitze.play("spitze_start")
