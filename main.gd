extends Node3D



# Properties
var selected_model = 0

# Alias for the 3D physics server singleton
var PS3D := PhysicsServer3D

# Whether gravity is currently turned on
var is_gravity_on: bool = true:
	get:
		return is_gravity_on
	set(val):
		is_gravity_on = val
		var gravity = 9.8 if is_gravity_on else 0.0
		PS3D.area_set_param(get_viewport().find_world_3d().space,
							PS3D.AREA_PARAM_GRAVITY,
							gravity)



# Methods

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Make sure gravity is set correctly
	is_gravity_on = is_gravity_on

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Update the label for the current frame
	$LabelsBox/ProcessFPS.text = " Process: " + str(roundf(1.0 / delta)) + " FPS"
	$LabelsBox/Droplets.text = " Droplets: " + str($DropletGenerator.num_droplets)
	
	var fps_label = $FrameLabel
	fps_label.text = "%d FPS (%.2f mspf)" % [Engine.get_frames_per_second(), 1000.0 / Engine.get_frames_per_second()]
	# Color FPS counter depending on framerate.
	# The Gradient resource is stored as metadata within the FPSLabel node (accessible in the inspector).
	fps_label.modulate = fps_label.get_meta("gradient").sample(remap(Engine.get_frames_per_second(), 0, 180, 0.0, 1.0))

# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Update the label for the current physics frame
	$LabelsBox/PhysicsFPS.text = " Physics: " + str(roundf(1.0 / delta)) + " FPS"

# Called when there is an input event.
func _input(event: InputEvent) -> void:
	# Turn gravity on or off
	if event.is_action_pressed("gravity_toggle"):
		is_gravity_on = not is_gravity_on
	# Change the direction of gravity
	elif event.is_action_pressed("gravity_up"):
		_set_gravity_vector(Vector3.UP)
	elif event.is_action_pressed("gravity_down"):
		_set_gravity_vector(Vector3.DOWN)
	elif event.is_action_pressed("gravity_left"):
		_set_gravity_vector(Vector3.LEFT)
	elif event.is_action_pressed("gravity_right"):
		_set_gravity_vector(Vector3.RIGHT)

# Helper function sets the direction of gravity
func _set_gravity_vector(gravity_vector: Vector3) -> void:
	PS3D.area_set_param(get_viewport().find_world_3d().space,
						PS3D.AREA_PARAM_GRAVITY_VECTOR,
						gravity_vector)

func _on_algorithm_select_item_selected(index: int) -> void:
	selected_model = int(index)
	var selected = $Editor/AlgorithmContainer/AlgorithmSelect.get_item_text(selected_model)
	print("当前选择的模型是：" + selected)

func _on_scene_selecter_item_selected(index: int) -> void:
	$DropletGenerator.delete_all()
	if index == 0:
		get_tree().change_scene_to_file("res://test.tscn")
	elif index == 1:
		get_tree().change_scene_to_file("res://main.tscn")

func _on_limit_fps_scale_value_changed(value: float) -> void:
	$Editor/LimitFPSContainer/Value.text = str(value)
	
	Engine.max_fps = roundi(value)
