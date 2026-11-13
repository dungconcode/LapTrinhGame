extends TextureRect

func setStage(stage:int):
	match int(stage):
		-2:
			$Skull1.texture = preload("res://content/shared/difficulty/skull_difficulties_1.png")
			$Skull2.texture = null
			$Skull3.texture = null
		-1:
			$Skull1.texture = preload("res://content/shared/difficulty/skull_difficulties_1.png")
			$Skull2.texture = preload("res://content/shared/difficulty/skull_difficulties_1.png")
			$Skull3.texture = null
		0:
			$Skull1.texture = preload("res://content/shared/difficulty/skull_difficulties_1.png")
			$Skull2.texture = preload("res://content/shared/difficulty/skull_difficulties_1.png")
			$Skull3.texture = preload("res://content/shared/difficulty/skull_difficulties_1.png")
		1:
			$Skull1.texture = preload("res://content/shared/difficulty/skull_difficulties_2.png")
			$Skull2.texture = null
			$Skull3.texture = null
		2:
			$Skull1.texture = preload("res://content/shared/difficulty/skull_difficulties_2.png")
			$Skull2.texture = preload("res://content/shared/difficulty/skull_difficulties_2.png")
			$Skull3.texture = null
		3:
			$Skull1.texture = preload("res://content/shared/difficulty/skull_difficulties_2.png")
			$Skull2.texture = preload("res://content/shared/difficulty/skull_difficulties_2.png")
			$Skull3.texture = preload("res://content/shared/difficulty/skull_difficulties_2.png")
