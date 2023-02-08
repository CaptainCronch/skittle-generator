extends Node2D

export var radius := 10
export var base_width := 500
export var base_height := 500
export var background := Color8(15, 15, 15) # dark gray
export var colors : PoolColorArray = []
export var max_drops := 100
export var inner = false

var _table_area : Rect2
var _color_area : Rect2
var _picture_area : Rect2
var _poisson_disc_sampling = PoissonDiscSampling.new()
var _points : PoolVector2Array = []
var _last_color := Color.white
var _random_color := 0
var _border_offset := 0
var _width := base_width
var _height := base_height
var _offset := 0
var _duplicated_colors : PoolColorArray = []
var _original_window := Vector2.ZERO
var _image_index := 0

var circle := preload("res://circle.tscn")
var chance_ui := preload("res://color_chance.tscn")

onready var table : Polygon2D = $Rectangle
onready var circle_holder : Node2D = $CircleHolder
onready var chance_holder : Label = $"../UI/BackgroundPicker/SelectedColors"
onready var UI : Control = $"../UI"


func _ready():
	_original_window = OS.window_size


func _process(_delta):
	
	_color_area.size.x = base_width
	_color_area.size.y = base_height
	
	_picture_area.size = _color_area.size
	_picture_area.position = global_position
	
	_table_area.size.x = _width
	_table_area.size.y = _height
	
	if inner: 
		_width = base_width - (radius * 2)
		_height = base_height - (radius * 2)
		
		table.position = Vector2(-radius, -radius)
		_picture_area.position += Vector2(-radius, radius)
	else:
		_width = base_width
		_height = base_height
		
		table.position = Vector2.ZERO
	
	global_position = Vector2((get_viewport_rect().end.x - (base_width + 50)),
			get_viewport_rect().get_center().y - (base_height / 2.0))
	
	var square : PoolVector2Array = [_color_area.position, Vector2(_color_area.end.x, _color_area.position.y),
			_color_area.end, Vector2(_color_area.position.x, _color_area.end.y)]
	table.polygon = square
	table.color = background
	
	var i = 0
	_duplicated_colors = []
	for color in colors:
		for _x in range(0, chance_holder.get_child(i).value):
			_duplicated_colors.append(color)
		
		i += 1


func generate():
#	var failures := 0
#	var drops := 0
#
#	while failures <= 50:
#		drops += 1
#		if drops > max_drops:
#			break
#		var random_position := Vector2(rand_range(_table_area.position.x, _table_area.end.x),
#				rand_range(_table_area.position.y, _table_area.end.y))
#		if not _big_points.empty():
#			for big_point in _big_points:
#				if big_point.distance_to(random_position) <= big_radius * 2:
#					failures += 1
#				else:
#					_big_points.append(random_position)
#					break
#		else:
#			_big_points.append(random_position)
	pass


func _on_generate_pressed():
	update()
	_points = _poisson_disc_sampling.generate_points(radius * 2, _table_area, max_drops)
	
	for child in circle_holder.get_children():
		child.queue_free()
	
	for point in _points:
		var new_circle = circle.instance()
		circle_holder.add_child(new_circle)
		new_circle.size = Vector2(radius * 2, radius * 2)
		new_circle.position = point
		
		if not _duplicated_colors.empty():
			_random_color = round(rand_range(0, _duplicated_colors.size() - 1))
			new_circle.color = _duplicated_colors[int(_random_color)]
		else:
			new_circle.color = Color.white


func _on_background_color_changed(color):
	background = color


func _on_disc_popup_closed():
	colors.append(_last_color)
	
	var chance := chance_ui.instance()
	chance_holder.add_child(chance)
	
	chance.margin_top = colors.size() * 30
	chance.get_node("Label").text = "#" + _last_color.to_html()


func _on_disc_color_changed(color):
	_last_color = color


func _on_reset_pressed():
	colors = []
	_duplicated_colors = []
	for child in chance_holder.get_children():
		child.queue_free()


func _on_width_value_changed(value):
	base_width = value
	for child in circle_holder.get_children():
		child.queue_free()
	update()


func _on_length_value_changed(value):
	base_height = value
	for child in circle_holder.get_children():
		child.queue_free()
	update()


func _on_fullscreen_pressed():
	OS.window_fullscreen = !OS.window_fullscreen


func _on_exit_pressed():
	get_tree().quit()


func _on_radius_value_changed(value):
	radius = value


func _on_drops_value_changed(value):
	max_drops = value


func _on_inner_toggled(button_pressed):
	inner = button_pressed


func _on_save_pressed():
	UI.visible = false
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	var img = get_viewport().get_texture().get_data().get_rect(_picture_area)
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	img.flip_y()
	var dir = Directory.new()
	dir.open(OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP))
	_image_index += 1
	img.save_png(dir.get_current_dir() + "/skittles-" + String(_image_index) + ".png")
	UI.visible = true
	
