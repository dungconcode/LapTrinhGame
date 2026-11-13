extends "res://content/shared/VideoTutorial.gd"

func _ready():
	super._ready()
	splitTutorialText("level.tutorial.assessor.spheres.desc1", "LabelDesc1_1", "LabelDesc1_2")
	splitTutorialText("level.tutorial.assessor.carry.desc1", "LabelDesc3_1", "LabelDesc3_2")
	splitTutorialText("level.tutorial.assessor.carry.desc2", "LabelDesc4_1", "LabelDesc4_2")
