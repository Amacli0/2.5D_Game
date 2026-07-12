extends Node3D

@onready var camera: Camera3D = $Camera3D

var target_rotation_y:= 0.0
var target_zoom := 0.0

@export_group("Kamera Ayarları")
@export var rotation_speed := 5.0
@export var rotation_step := 45.0
@export var min_zoom := 1.0
@export var max_zoom := 20.0
@export var zoom_speed := 1.0
@export var zoom_smoothness := 10.0

func _ready() -> void:
	target_rotation_y = rotation.y
	target_zoom = camera.position.y

func _unhandled_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("camera_right"):
		target_rotation_y += deg_to_rad(rotation_step)		
	if event.is_action_pressed("camera_left"):
		target_rotation_y -= deg_to_rad(rotation_step)
	
	
	if event.is_action_pressed("camera_zoom"):
		target_zoom += -zoom_speed
		target_zoom = clamp(target_zoom, min_zoom, max_zoom)
	elif event.is_action_pressed("camera_zoom_out"):
		target_zoom += zoom_speed
		target_zoom = clamp(target_zoom, min_zoom, max_zoom)

func _process(delta: float) -> void:
	rotation.y = lerp_angle(rotation.y, target_rotation_y, rotation_speed * delta)
	camera.position.z = lerp(camera.position.z, target_zoom, zoom_smoothness * delta)
	camera.position.y = lerp(camera.position.y, target_zoom, zoom_smoothness * delta)

	camera.rotation.x = remap(camera.position.z, min_zoom , max_zoom, deg_to_rad(-40), deg_to_rad(-50))
