extends "res://content/monster/WaveSnippet.gd"

class_name Wave

var snippets := []
var maxMonsters:int

func addSnippet(snippet:WaveSnippet):
	snippets.append(snippet)
	rebuildEntries()

func rebuildEntries():
	entries.clear()
	for snippet in snippets:
		for entry in snippet.entries:
			if entry.type != "snippet":
				addEntry(entry)

func getWeightWithSnippet(extraSnippet) -> float:
	var e = entries.duplicate()
	for entry in extraSnippet.entries:
		if entry.type != "snippet":
			e.append(entry)
	return getWeight(e, true)

func getMonsterCount() -> int:
	var i := 0
	for entry in entries:
		if entry.type == "add":
			i += 1
	return i

func _to_string():
	return str(snippets)

func generateSpawnPlan() -> Array:
	var spawns := []
	var time := 0.0
	var mod = Data.of("monsters.timingmod")
	for entry in entries:
		match entry.type: 
			"add":
				var spawn = TimedSpawn.new()
				spawn.time = time
				spawn.breed = entry.breed
				spawn.variant = entry.variant
				spawns.append(spawn)
			"wait":
				var change = mod * float(Data.of("monsters.timebetweenmonsters"))
				time += change
	return spawns
