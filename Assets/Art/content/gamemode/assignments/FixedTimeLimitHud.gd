extends HudElement

var secondsPerPixel := 18.0
var maxSpawnRectSize:float

func init():
	maxSpawnRectSize = floor((60 * Data.of("game.fixedtimelimit")) / secondsPerPixel)
	$TimeBar.custom_minimum_size.x = maxSpawnRectSize
	$TimeBar/Terminus.position.x = maxSpawnRectSize
	
	await get_tree().process_frame # ui often needs a frame to update properly
	await get_tree().process_frame
	element_size.x = ceil(maxSpawnRectSize / 6.0)
	emit_signal("request_rebuild")

func _process(delta):
	var goalRectSize:float = -1 + ((60 * Data.of("game.fixedtimelimit")) - GameWorld.runTime) / secondsPerPixel
	var sizeD = goalRectSize - %FillingBar.size.x
	sizeD += sign(sizeD)
	%FillingBar.size.x += delta * sizeD
	
