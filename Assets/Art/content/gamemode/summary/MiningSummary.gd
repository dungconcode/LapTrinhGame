extends Control

const GIFExporter = preload("res://addons/gdgifexporter_custom/exporter.gd")
const GIF_PATH := "user://gif/"
const UPSCALE_FACTOR := 8
const HEADER_DRAW_OFFSET := 8
const BORDER_TEX := preload("res://gui/panels/panel_outside.png")
const BORDER_SIZE := 32
const FRAME_DELAY :=0.05

var paused := false
var max_cooldown := 0.04
var timestep := 0.4
var cooldown:float
var currentEventIndex := 0

var exporting := false
var export_progress := 0.0
var overlay_image:Image
var aborted := false
var thread:Thread = null
var final_path = null
@onready var gif_export_overlay_viewport = %GifExportOverlayViewport

func _ready() -> void:
	$ColorRect.color = Style.OVERLAY_COLOR_OUT
	Style.init(self)
	InputSystem.grabFocus(find_child("CancelButton"))
	%ShowImagesButton.visible = false
	aborted = false
	if get_parent() == get_tree().root:
		Recorder.initialMapData = load("res://content/map/data/TileDataGenerated.tscn").instantiate()
	
	setMapToInitial()
	
	var rect = %MapData.get_used_rect()
	const MIN_SIZE := 40
	if rect.size.y > 0:
		if rect.size.x <MIN_SIZE or rect.size.y < MIN_SIZE:
			var w = max(MIN_SIZE, rect.size.x)
			rect.size = Vector2i(w,max(MIN_SIZE, rect.size.y))
			rect.position = Vector2i(-w*0.5,0)
			
		var size_scale = round(700 / (max(rect.size.x,rect.size.y)))
		size_scale = size_scale / 4.0
		%MapData.scale = Vector2.ONE * size_scale
		%MapData.position.y = 30
		%MapContainer.custom_minimum_size = rect.size * 4 * size_scale
		%MapContainer.custom_minimum_size.y += 10

func setMapToInitial():
	currentEventIndex = 0
	cooldown = 0.1
	setMapTo(Recorder.initialMapData)

func setMapToFinal():
	currentEventIndex = Recorder.tileEvents.size()
	cooldown = 0.1
	setMapTo(Recorder.finalMapData)
	for event in Recorder.tileEvents:
		%MapData.set_resourcev(event.coord, event.type if event.type >= 0 else 20)

func setMapTo(map:MapData):
	if map:
		%MapData.clear()
		for cell in map.get_used_cells(1):
			var res = map.get_resourcev(cell)
			%MapData.set_resourcev(cell, res)

func _process(delta: float) -> void:
	if exporting:
		if export_progress < 1.0:
			%LabelSaveInfo.text = "%.02f%%" % (export_progress * 100.0)
			%ShowImagesButton.visible = false
		else:
			%LabelSaveInfo.text = tr("level.gameover.findimages") + " " + ProjectSettings.globalize_path(final_path)
			%ShowImagesButton.visible = true
			%ButtonSave.visible = true
	
	if paused:
		return
	
	if currentEventIndex >= Recorder.tileEvents.size():
		return
	
	if cooldown > 0.0:
		cooldown -= delta
		return
	
	var event:TileDestroyedEvent = Recorder.tileEvents[currentEventIndex]
	var startTime = event.time
	while event.time <= startTime + timestep and currentEventIndex < Recorder.tileEvents.size() - 1:
		%MapData.set_resourcev(event.coord, event.type if event.type >= 0 else 20)
		currentEventIndex += 1
		event = Recorder.tileEvents[currentEventIndex]
	cooldown = max_cooldown

func _on_button_speed_1_pressed() -> void:
	Audio.sound("gui_select")
	max_cooldown = 0.2
	timestep = 0.1

func _on_button_speed_2_pressed() -> void:
	Audio.sound("gui_select")
	max_cooldown = 0.05
	timestep = 0.4

func _on_button_speed_3_pressed() -> void:
	Audio.sound("gui_select")
	max_cooldown = 0.0
	timestep = 1.0

func _on_button_initial_pressed() -> void:
	Audio.sound("gui_select")
	setMapToInitial()

func _on_button_pause_pressed() -> void:
	Audio.sound("gui_select")
	paused = not paused

func _on_button_end_pressed() -> void:
	Audio.sound("gui_select")
	setMapToFinal()

func _on_button_save_pressed() -> void:
	$FileDialog.file_selected.disconnect(on_save_file_selected)
	$FileDialog.file_selected.connect(on_save_file_selected)
	var time = Time.get_datetime_dict_from_system()
	var timestr = "run_%s_%s_%s_%s_%s" %[time.year, time.month, time.day, time.hour, time.minute]
	$FileDialog.current_dir = ProjectSettings.globalize_path(GIF_PATH)
	$FileDialog.current_file = timestr + '.gif'
	$FileDialog.show()
	
func on_save_file_selected(path:String) -> void:
	if path == null or path.is_empty():
		return
	final_path = path
	%ButtonSave.visible = false
	%LabelSaveInfo.visible = true
	%ButtonPause.grab_focus()
	
	await get_tree().process_frame
	
	exporting = true
	update_and_render_overlay()
	gif_export_overlay_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	#wait for rendering
	await RenderingServer.frame_post_draw
	#save overlay, has to be done on main thread
	overlay_image = gif_export_overlay_viewport.get_texture().get_image()
	
	thread = Thread.new()
	thread.start(export_as_gif_threaded, Thread.PRIORITY_NORMAL)


func export_as_gif_threaded():
	if Recorder.tileEvents.size() == 0:
		return
	
	export_progress = 0.01
	
	if not DirAccess.dir_exists_absolute(GIF_PATH):
		DirAccess.make_dir_absolute(GIF_PATH)
	
	var usedRect = Recorder.initialMapData.get_used_rect()
	var image_size = get_image_size()
	
	var background_frame = create_initial_buffer()
	var background_palette = create_color_table()
	
	var arr = bake_header_into_background(background_frame, image_size, background_palette)
	background_frame = arr[0]
	image_size = arr[1]
	
	background_frame = upscale_buffer(background_frame,image_size)
	image_size = image_size * UPSCALE_FACTOR
	
	var new_size = bake_overlay_into_background(background_frame, image_size, background_palette)
	image_size = new_size
	
	arr = add_border(background_frame, image_size, background_palette)
	background_frame = arr[0]
	image_size = arr[1]
	
	if aborted:
		return
	
	var exporter = GIFExporter.new(image_size.x, image_size.y)
	exporter.lzw.run_c_converter = true #custom fast converter written by us
	#draw initial frame, whole map + overlay
	exporter.add_frame_domekeeper_custom_raw(background_palette,background_frame , 1.0,image_size, Vector2.ZERO, ColorIdx.Transparent)
	
	var points := []
	
	var borderOffset = Vector2i.ONE * BORDER_SIZE/ UPSCALE_FACTOR
	var i := 0
	var rect = null
	var timestep_in_frame = FRAME_DELAY * 60.0 #3 sec per frame
	var current_frame_end_time = Recorder.tileEvents.front().time + timestep_in_frame;
	
	#add mining frames
	for event:TileDestroyedEvent in Recorder.tileEvents:
		if aborted:
			return
		
		i += 1
		#do not include last frame, since we want it to be longer
		if event.time > current_frame_end_time and i != Recorder.tileEvents.size():
			if not points.is_empty():
				add_frame(exporter, background_palette,points,rect,FRAME_DELAY)
				rect = null
				points.clear()
			#prepare end-time for next frame
			current_frame_end_time = event.time + timestep_in_frame;
		
		var pos  = Vector2i( event.coord.x - usedRect.position.x, event.coord.y - usedRect.position.y + HEADER_DRAW_OFFSET) + borderOffset
		points.append(pos)
		if rect:
			rect = rect.expand(pos)	
		else:
			rect = Rect2i(pos, Vector2i(1,1))
		export_progress = float(i)/len(Recorder.tileEvents)
	
	if not points.is_empty():
		add_frame(exporter, background_palette,points,rect,3.0)
		
	if aborted:
		return
	
	#export gif
	var file: FileAccess = FileAccess.open(final_path, FileAccess.WRITE)
	file.store_buffer(exporter.export_file_data())
	file.close()
	export_progress = 1.0

func update_and_render_overlay():
	%LabelUsernameData.text = Platform.get_username() + "    " + Time.get_date_string_from_system()
	var modetext;
	if Level.loadout.modeId == Const.MODE_PRESTIGE:
		match Level.loadout.modeConfig.get(CONST.MODE_CONFIG_PRESTIGE_VARIANT):
			CONST.MODE_PRESTIGE_COUNTDOWN:
				modetext = tr("loadout.prestige.countdown")
			CONST.MODE_PRESTIGE_PROVOCATION:
				modetext = tr("loadout.prestige.provocation")
			CONST.MODE_PRESTIGE_MINER:
				modetext = tr("loadout.prestige.miner")
			CONST.MODE_PRESTIGE_ENDLESS:
				modetext = tr("loadout.prestige.endless")
		modetext = str(Data.ofOr("prestige.score",0)) + "    " + modetext
	else:
		modetext = tr("upgrades." + Level.loadout.modeId+ ".title")
		
	%LabelGamemodeScore.text = modetext
	#force shrink to content	
	var e = %GifExportOverlayEntries
	e.size = Vector2(0,0)
	gif_export_overlay_viewport.size = e.size

func bordertex_to_index_buffer():
	var colormap := {
		Color("#0006dc") : ColorIdx.Stone,
		Color("#604cdc") : ColorIdx.Iron,
		}
	var out :=[]
	var i = BORDER_TEX.get_image()
	i.convert(Image.FORMAT_RGBA8)
	for y in i.get_height():
		for x in i.get_width():
			var c = i.get_pixel(x,y)
			if c.a == 0:
				out.append(ColorIdx.Transparent)
			elif colormap.has(c):
				out.append(colormap[c])
			else:
				out.append(ColorIdx.Background)
	return out

func add_horizontal_border(out, image_size, borderw, data, offset):
	for y in BORDER_SIZE:
		for x in image_size.x + BORDER_SIZE * 2:
			var col := ColorIdx.Background
			if x < BORDER_SIZE:
				col = data[offset + y*borderw + x]
			elif x > image_size.x + BORDER_SIZE:
				col = data[offset + y*borderw + (x - image_size.x - BORDER_SIZE) + borderw - BORDER_SIZE]
			else:
				col = data[offset + y*borderw + BORDER_SIZE +1]
			out.append(col)
	
func add_border(bg, image_size, palette):
	var data = bordertex_to_index_buffer()
	var out := []
	var borderw = BORDER_TEX.get_width()
	
	#top border
	add_horizontal_border(out,image_size, borderw, data, 0)
	
	for y in image_size.y:
		#add left border
		for x in BORDER_SIZE:
			out.append(data[(BORDER_SIZE+1) * borderw + x])
		
		#add normal tex line
		out.append_array(bg.slice(y * image_size.x, y * image_size.x + image_size.x))
		
		#add right border
		for x in BORDER_SIZE:
			out.append(data[(BORDER_SIZE+1) * borderw + (borderw - BORDER_SIZE) + x])
		
	#bottom border
	var offset = (BORDER_TEX.get_height()-(BORDER_SIZE+1)) *borderw
	add_horizontal_border(out,image_size, borderw, data, offset)
		
	image_size += BORDER_SIZE * 2 * Vector2i.ONE
	return [out, image_size]

func position_header(header_buffer, header_width, expected_width, center_x):
	var height = header_buffer.size()/header_width
	
	var newdata := []
	
	for y in height:
		for x in expected_width:
			var px = x - center_x + header_width/2 
			var py = y 
			if px >= 0 and px < header_width:
				newdata.append(header_buffer[py*header_width + px])
			else:
				newdata.append(ColorIdx.Background)
	return newdata

func bake_header_into_background(bg,image_size, palette):
	var img = preload("res://content/gamemode/summary/summary_overworld.png").get_image()
	img.convert(Image.FORMAT_RGBA8)
	var buf = convert_image_to_buffer(img, palette)
	
	var rect = Recorder.initialMapData.get_used_rect()
	var center_x = - rect.position.x + 1 #magic offset from sprite
	buf = position_header(buf, img.get_size().x, image_size.x, center_x) #todo Center.x
	buf.append_array(bg)
	
	image_size.y += img.get_height()
	return [buf,image_size]
	

func bake_overlay_into_background(bg, image_size, palette):
	var i:Image = overlay_image
	i.convert(Image.FORMAT_RGBA8)
	
	#pad at the bottom to make space
	image_size = add_empty_lines(bg,image_size, i.get_size().y)
	
	#bottom right pivot
	var offset = image_size
	offset -= i.get_size()
	overlay_image_into_buffer(i,bg, offset, image_size,palette)
	return image_size

func add_empty_lines(bg, image_size, amount):
	for y in amount:
		for x in image_size.x:
			
			bg.append(ColorIdx.Background)
	
	return Vector2i(image_size.x, image_size.y + amount)

func convert_image_to_buffer(image, color_palette):
	var image_data = image.get_data()
	var color_map := {}
	for x in color_palette.size():
		color_map[color_palette[x]] = x
	#transparent info is lost and rendered as clear-color black
	#so i assume black is transparent
	color_map[[0,0,0,255]] = ColorIdx.Transparent
	
	#convert image to palette index based
	var index_data := []
	for i in range(0, image_data.size(), 4):
		var color: Array = [
			int(image_data[i]),
			int(image_data[i + 1]),
			int(image_data[i + 2]),
			int(image_data[i + 3])
		]
		
		if color[3] == 0:
			index_data.append(ColorIdx.Transparent)
		elif color_map.has(color):
			index_data.append(color_map[color])
		else:
			#new color add to palette
			color_palette.append(color)
			color_map[color] = color_palette.size()-1
			index_data.append( color_palette.size()-1)
	
	return index_data

func overlay_image_into_buffer(image, buffer, offset, _size, color_palette):
	var index_data = convert_image_to_buffer(image,color_palette)
	var image_size = image.get_size()
	for i in index_data.size():
		var v = index_data[i]
		if v != ColorIdx.Transparent:
			var x = i%image_size.x
			var y = i/image_size.x
			buffer[(offset.y + y)*_size.x + offset.x + x] =v 

func add_frame(exporter, palette, points, rect, delay):
	var buf = []
	rect.size += Vector2i(1,1)
	buf.resize(rect.size.x * rect.size.y)
	buf.fill(ColorIdx.Transparent)
	for p in points:
		var x = p.x - rect.position.x
		var y = p.y - rect.position.y
		buf[y * rect.size.x + x] = ColorIdx.Mined
	
	exporter.add_frame_domekeeper_custom_raw(palette, upscale_buffer(buf,rect.size), delay, rect.size * UPSCALE_FACTOR,rect.position * UPSCALE_FACTOR, ColorIdx.Transparent)

func upscale_buffer(buf, image_size) -> PackedByteArray:
	var newbuffer = PackedByteArray()
	
	var i := 0
	var nextlimit = image_size.x
	var xrepeat := 0
	var length = buf.size()
	while(true):
		for x in UPSCALE_FACTOR:
			newbuffer.append(buf[i])
			
		i+= 1
		if i >= nextlimit:
			xrepeat += 1
			if xrepeat >= UPSCALE_FACTOR:
				xrepeat = 0
				nextlimit += image_size.x
			else:
				i -= image_size.x
			
			if i >= length:
				break
			
	return newbuffer

func _on_show_images_button_pressed():
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path(final_path))

func create_initial_buffer() -> PackedByteArray:
	var usedRect = Recorder.initialMapData.get_used_rect()
	var arr = PackedByteArray()
	
	for y in range(usedRect.position.y, usedRect.end.y):
		for x in range(usedRect.position.x, usedRect.end.x ):
			var res = Recorder.initialMapData.get_resource(x, y)
			match res:
				Data.TILE_EMPTY: arr.append(ColorIdx.Background)
				Data.TILE_IRON: arr.append(ColorIdx.Iron)
				Data.TILE_WATER: arr.append(ColorIdx.Water)
				Data.TILE_SAND: arr.append(ColorIdx.Kobalt)
				Data.TILE_GADGET: arr.append(ColorIdx.Gadget)
				Data.TILE_RELIC: arr.append(ColorIdx.Relic)
				Data.TILE_NEST: arr.append(ColorIdx.Hole)
				Data.TILE_RELIC_SWITCH: arr.append(ColorIdx.Relic)
				Data.TILE_SUPPLEMENT: arr.append(ColorIdx.Gadget)
				Data.TILE_CAVE: arr.append(ColorIdx.Hole)
				Data.TILE_BORDER: arr.append(ColorIdx.Border)
				_: arr.append(ColorIdx.Stone)
	
	return arr

func get_image_size() -> Vector2i:
	var usedRect = Recorder.initialMapData.get_used_rect()
	var mapSize = usedRect.size
	return mapSize

enum  ColorIdx 
{
	Background,
	Mined,
	Stone,
	Border,
	Relic,
	Gadget,
	Iron,
	Kobalt,
	Water,
	Hole,
	Transparent
}

func create_color_table() -> Array:
	var pal = preload("res://content/gamemode/summary/summary_palette.png").get_image()
	var colors := []
	for y in pal.get_size().y:
		for x in pal.get_size().x:
			colors.append(pal.get_pixel(x,y))
	return color_arr_to_table(colors)

func color_arr_to_table(colors : Array):
	var arr := []
	
	for x in colors:
		arr.append([int(x.r*255),int(x.g*255),int(x.b*255),int(x.a*255)])
	return arr

func _exit_tree() -> void:
	aborted = true
	if thread and thread.is_alive():
		thread.wait_to_finish()
