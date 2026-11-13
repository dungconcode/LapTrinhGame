extends Node

var lastMonsters := []
var allSnippets := []

var DEFAULT_WAVE:Wave

func _ready():
	DEFAULT_WAVE = Wave.new()
	var s = WaveSnippet.new()
	if randf() > 0.5:
		s.addEntry(WaveEntry.new("add.walker.left"))
	else:
		s.addEntry(WaveEntry.new("add.walker.right"))
	DEFAULT_WAVE.addSnippet(s)
	
	var waveData = FileAccess.open("res://wavepart.txt", FileAccess.ModeFlags.READ)
	if waveData != null:
		while not waveData.eof_reached():
			var line:String = waveData.get_line()
			if line.strip_edges().length() > 1:
				var snippet = WaveSnippet.new()
				for entry in BackwardCompatibilityUtils.str_to_var(line):
					var e = WaveEntry.new(entry)
					snippet.addEntry(e)
				snippet.addEntry(WaveEntry.new("wait.2"))
				allSnippets.append(snippet)
	waveData.close()
	
#	for i in range(15, 300, 2000):
#		var w = generateWave(i)
#		print()
#		print(i)
#		for e in w.entries:
#			print(str(e))
#		yield(get_tree().create_timer(0.5), "timeout")

func setAllowedMonsters(allowedMonsters:Array):
	self.allowedMonsters = allowedMonsters

func pickFallbackWave(allowedMonsters:Array):
	#usually we fallback to a single walker wave, but with new assignments
	#there is a chance we never want walkers there, in that case we 
	#fallback to the first allowed enemy
	if allowedMonsters.size() > 0 and not allowedMonsters.has("walker"):
		var fallback = Wave.new()
		var s = WaveSnippet.new()
		if randf() > 0.5:
			s.addEntry(WaveEntry.new("add.%s.left" % allowedMonsters[0]))
		else:
			s.addEntry(WaveEntry.new("add.%s.right"% allowedMonsters[0]))
		fallback.addSnippet(s)
		return fallback
	
	return DEFAULT_WAVE

func generateWave(baseWeight:float, weightModifier:float) -> Wave:
	var goalWeight = baseWeight * weightModifier
	
	var allowedMonsters:Array = Data.ofOr("monsters.allowedtypes", ["mucker"])
	
	var allowedSnippets := []
	for snippet in allSnippets:
		var ok := true
		
		var weight := 0
		for monster in snippet.monsters:
			weight += Data.of(monster + ".weight")
			if Data.of(monster + ".minRunWeight") > baseWeight:
				ok = false
				break
			
			if allowedMonsters and not allowedMonsters.has(monster):
				ok = false
				break
			
			if lastMonsters.size() > 0 and not Data.ofOr(monster + ".repeatable", true):
				if lastMonsters[0].has(monster):
					ok = false
					break
		if ok:
			snippet.remainingUses = floor((baseWeight * 0.4) / weight)
			for monster in snippet.monsters:
				var maxRelativeWeightInWave = Data.ofOr(monster + ".maxRelativeWeightInWave", 1.0)
				var maxUses:int = round((maxRelativeWeightInWave * goalWeight) / float(Data.of(monster + ".weight")))
				snippet.remainingUses = min(snippet.remainingUses, maxUses)
			allowedSnippets.append(snippet)
	
	if allowedSnippets.is_empty():
		return pickFallbackWave(allowedMonsters)
	
	var currentWave = Wave.new()
	currentWave.maxMonsters = 12 + Level.loadout.difficulty + round(log(goalWeight) - 1.5 + floor(goalWeight / 10000.0)) + (Keepers.getKeeperCount() - 1) * 2
	var failsafe := 1000
	var deviation = 0.1
	var maxWeight = goalWeight * (1.0 + deviation) + 5
	var minWeight = goalWeight * (1.0 - deviation) - 5
	while true:
		if currentWave.getWeight() >= minWeight and currentWave.getWeight() <= maxWeight:
			return currentWave
		
		failsafe -= 1
		if failsafe == 0:
			if deviation == 0.1:
				deviation = 0.2
				maxWeight = goalWeight * (1.0 + deviation) + 5
				minWeight = goalWeight * (1.0 - deviation) - 5
				failsafe = 1000
			else:
				Logger.warn("failed to generate wave", "WaveGenerator.generateWave", {"goalWeight":goalWeight,"currentWeight":currentWave.getWeight(), "currentWaveSize":currentWave.entries.size(), "allowedSnippets":allowedSnippets})
				if currentWave.getMonsterCount() == 0:
					return DEFAULT_WAVE
				else:
					return currentWave
		
		var flipWeight := 0.5
		allowedSnippets.shuffle()
		for i in min(allowedSnippets.size(), 5):
			var snippet = allowedSnippets[i]
			if randf() > flipWeight:
				snippet.flipVariants()
				if flipWeight < 0.4:
					flipWeight += 0.2
				else:
					flipWeight += 0.1
			else:
				if flipWeight > 0.6:
					flipWeight -= 0.2
				else:
					flipWeight -= 0.1
			var newW = currentWave.getWeightWithSnippet(snippet)
			if newW < maxWeight:
				currentWave.addSnippet(snippet.duplicate())
				currentWave.weight = newW
				
				snippet.remainingUses -= 1
				if snippet.remainingUses <= 0:
					allowedSnippets.erase(snippet)
				
				for monster in snippet.monsters:
					if Data.ofOr(monster + ".single", false):
						allowedSnippets.erase(snippet)
						break
				break
	
	return DEFAULT_WAVE

func waveFinished(wave:Wave):
	if not wave:
		return
	
	var monsters := []
	for snippet in wave.snippets:
		for monster in snippet.monsters:
			if not monsters.has(monster):
				monsters.append(monster)
	
	lastMonsters.push_front(monsters)
	if lastMonsters.size() > 2:
		lastMonsters.pop_back()


