extends "res://content/gadgets/CellarGadget.gd"

var producing := false
var hasExtractor := false
var growth := 0.0
var grownAfter := 0.0

func _ready():
	
	if not SaveGame.currentLoadingSavegame:
		addExtractor()
	$ExtraExtractor.visible = false
	$Sprite/WormSprite1.visible = false
	$Sprite/WormSprite2.visible = false
	
	Level.addTutorial(self, "extractor")
	
	Style.init(self)

func serialize()->Dictionary:
	var data = super.serialize()
	data["producing"] = producing
	data["hasExtractor"] = hasExtractor
	data["growth"] = growth
	data["grownAfter"] = grownAfter
	return data

func deserialize(data: Dictionary):
	super.deserialize(data)
	producing = data["producing"]
	hasExtractor = data["hasExtractor"]
	growth = data["growth"]
	grownAfter = data["grownAfter"]
	
	if hasExtractor:
		addExtractor()
	else:
		$ExtraExtractor.visible = false

func _process(delta):
	if GameWorld.softPaused():
		return
	
	if growth < grownAfter:
		growth += delta * GameWorld.cycleSpeed
		if growth >= grownAfter * 0.5 and not $Sprite/WormSprite1.visible:
			$Sprite/WormSprite1.visible = true
			$Sprite/WormSprite1.play("coming_out")
		if growth >= grownAfter * 0.8 and not $Sprite/WormSprite2.visible:
			$Sprite/WormSprite2.visible = true
			$Sprite/WormSprite2.play("coming_out")
		return
	
	if producing:
		addExtractor()

func addExtractor():
	$Sprite.play("producing")
	producing = false

func canFocusUse(keeper:Keeper) -> bool:
	return hasExtractor

func useHold(keeper:Keeper) -> bool:
	return useHit(keeper)

func useHit(keeper:Keeper) -> bool:
	if hasExtractor:
		for _i in Data.of("extractor.units"):
			var extractor = preload("res://content/gadgets/extractor/Extractor.tscn").instantiate()
			extractor.position = $ExtractorPosition.global_position
			Level.map.addDrop(extractor)
			keeper.attachCarry(extractor)
		hasExtractor = false
		$ExtraExtractor.visible = false
		$Sprite.play("empty")
		$ExtractorPickup.play()
		producing = true
		grownAfter = Data.of("extractor.buildcycles") * GameWorld.getTimeBetweenWaves()
		growth = 0
		
		$Sprite/WormSprite1.visible = false
		$Sprite/WormSprite2.visible = false
		return true
	return false

func _on_sprite_animation_finished() -> void:
	if $Sprite.animation == "producing":
		$Sprite.play("ready")
		hasExtractor = true
		if Data.of("extractor.units") > 1:
			if not $ExtraExtractor.visible:
				$Sprite.play("producing")
				$ExtraExtractor.visible = true
				$ExtraExtractor.position = Vector2(-2, -3)
				create_tween().tween_property($ExtraExtractor, "position", Vector2(-9, -1), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func _on_worm_sprite_1_animation_finished() -> void:
	if $Sprite/WormSprite1.animation == "coming_out":
		$Sprite/WormSprite1.play("idle")

func _on_worm_sprite_2_animation_finished() -> void:
	if $Sprite/WormSprite2.animation == "coming_out":
		$Sprite/WormSprite2.play("idle")
