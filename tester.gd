extends WorldEnvironment

const ROT_SPEED = 0.003
const ZOOM_SPEED = 0.125
const MAIN_BUTTONS = MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE

var tester_index := 0
var rot_x := deg_to_rad(-22.5)  # This must be kept in sync with RotationX.
var rot_y := deg_to_rad(90)  # This must be kept in sync with CameraHolder.
var zoom := 2.5
var base_height := int(ProjectSettings.get_setting("display/window/size/viewport_height"))
var selected_model = 0 # 0: pbf, 1: lbm, 2: mpm

@onready var testers: Node3D = $Testers
@onready var camera_holder: Node3D = $CameraHolder # Has a position and rotates on Y.
@onready var rotation_x: Node3D = $CameraHolder/RotationX
@onready var camera: Camera3D = $CameraHolder/RotationX/Camera3D
@onready var fps_label: Label = $FrameLabel
@onready var particles_force_field: CPUParticles3D = $Testers/CPUParticlesForceField/CPUParticles3D
@onready var particles_explosion: CPUParticles3D = $Testers/CPUParticlesExplosion/CPUParticles3D
@onready var particles_fire: GPUParticles3D = $Testers/GPUParticlesFire/GPUParticles3D


func _ready() -> void:
	camera_holder.transform.basis = Basis.from_euler(Vector3(0, rot_y, 0))
	rotation_x.transform.basis = Basis.from_euler(Vector3(rot_x, 0, 0))
	update_gui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_left"):
		_on_previous_pressed()
	if event.is_action_pressed(&"ui_right"):
		_on_next_pressed()

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom -= ZOOM_SPEED
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom += ZOOM_SPEED
		zoom = clamp(zoom, 1.5, 8)

	if event is InputEventMouseMotion and event.button_mask & MAIN_BUTTONS:
		# Compensate motion speed to be resolution-independent (based on the window height).
		var relative_motion: Vector2 = event.relative * DisplayServer.window_get_size().y / base_height
		rot_y -= relative_motion.x * ROT_SPEED
		rot_x -= relative_motion.y * ROT_SPEED
		rot_x = clamp(rot_x, deg_to_rad(-90), 0)
		camera_holder.transform.basis = Basis.from_euler(Vector3(0, rot_y, 0))
		rotation_x.transform.basis = Basis.from_euler(Vector3(rot_x, 0, 0))


func _process(delta: float) -> void:
	var current_tester: Node3D = testers.get_child(tester_index)
	# This code assumes CameraHolder's X and Y coordinates are already correct.
	var current_position := camera_holder.global_transform.origin.z
	var target_position := current_tester.global_transform.origin.z
	camera_holder.global_transform.origin.z = lerpf(current_position, target_position, 3 * delta)
	camera.position.z = lerpf(camera.position.z, zoom, 10 * delta)
	
	fps_label.text = "%d FPS (%.2f mspf)" % [Engine.get_frames_per_second(), 1000.0 / Engine.get_frames_per_second()]
	# Color FPS counter depending on framerate.
	# The Gradient resource is stored as metadata within the FPSLabel node (accessible in the inspector).
	fps_label.modulate = fps_label.get_meta("gradient").sample(remap(Engine.get_frames_per_second(), 0, 180, 0.0, 1.0))


func _on_previous_pressed() -> void:
	tester_index = max(0, tester_index - 1)
	update_gui()


func _on_next_pressed() -> void:
	tester_index = min(tester_index + 1, testers.get_child_count() - 1)
	update_gui()


func update_gui() -> void:
	$TestName.text = str(testers.get_child(tester_index).name).capitalize()
	$Previous.disabled = tester_index == 0
	$Next.disabled = tester_index == testers.get_child_count() - 1


func _on_paritcles_number_scale_value_changed(value: float) -> void:
	$Editor/ParticlesNumberContainer/Value.text = str(value)

	particles_force_field.amount = roundi(value)
	particles_explosion.amount = roundi(value)
	particles_fire.amount = roundi(value)


func _on_limit_fps_scale_value_changed(value: float) -> void:
	$Editor/LimitFPSContainer/Value.text = str(value)
	
	Engine.max_fps = roundi(value)


func _on_algorithm_select_item_selected(index: int) -> void:
	selected_model = int(index)
	var selected = $Editor/AlgorithmContainer/AlgorithmSelect.get_item_text(selected_model)
	print("当前选择的模型是：" + selected)


func _on_scene_selecter_item_selected(index: int) -> void:
	if index == 0:
		get_tree().change_scene_to_file("res://test.tscn")
	elif index == 1:
		get_tree().change_scene_to_file("res://main.tscn")
