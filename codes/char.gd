extends CharacterBody3D

@onready var camera_pivot: Node3D = $CameraPivot

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

func _ready() -> void:
	set_multiplayer_authority(name.to_int())
	if is_multiplayer_authority():
		$CameraPivot/Camera3D.current = true
	else:
		$CameraPivot/Camera3D.current = false
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_multiplayer_authority():
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY		
		
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := (camera_pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
