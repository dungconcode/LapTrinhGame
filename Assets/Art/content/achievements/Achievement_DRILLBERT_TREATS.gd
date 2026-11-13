extends Node

var id:String

var count := 0
var lastVal := 0

func _ready():
	count = Data.ofOr("achievement.drillbert.treats", 0)
	lastVal = count

func _process(delta):
	var newVal = get_parent().remainingBuffedHits
	if newVal > lastVal:
		count += 1
		if count >= 10:
			Achievements.triggerIfOpen(id)
			queue_free()
			count = -99
		else:
			Data.apply("achievement.drillbert.treats", count)
	lastVal = newVal
