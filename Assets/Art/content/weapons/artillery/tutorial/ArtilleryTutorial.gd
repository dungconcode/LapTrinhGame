extends "res://content/shared/VideoTutorial.gd"

func _ready():
	super._ready()
	splitTutorialText("level.tutorial.artillery.panel1content1", "LabelDesc1_1", "LabelDesc1_2")
	splitTutorialText("level.tutorial.artillery.panel2content1", "LabelDesc2_1", "LabelDesc2_2")
