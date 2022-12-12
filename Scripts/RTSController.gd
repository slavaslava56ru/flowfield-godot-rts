extends Node3D

const MOVE_MARGIN : int = 20;
const MOVE_SPEED : int = 15;
@onready var cam : Camera3D = $Camera3D
@onready var grid = get_node("/root/World/Grid");
var m_pos := Vector2()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _input(event):
	if event is InputEventMouseButton :
		
		var space_state = get_world_3d().get_direct_space_state()
		var params = PhysicsRayQueryParameters3D.new()
		params.from = cam.project_ray_origin(event.position)
		params.to = params.from + cam.project_ray_normal(event.position) * 100
		params.exclude = []
		
		var result = space_state.intersect_ray(params)
		grid.generateFlowFieldPath(result.position)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	m_pos = get_viewport().get_mouse_position()
	camera_movement(m_pos, delta)

func camera_movement(m_pos, delta):
	var viewport_size : Vector2 = get_viewport().size
	var origin : Vector3 = global_transform.origin
	var move_vec := Vector3()
	
	if origin.x > -62:
		if m_pos.x < MOVE_MARGIN:
			move_vec.x -=1
	if origin.z > -65:
		if m_pos.y < MOVE_MARGIN:
			move_vec.z -=1
	if origin.x < 62:
		if m_pos.x > viewport_size.x - MOVE_MARGIN:
			move_vec.x +=1
	if origin.z < 90:
		if m_pos.y > viewport_size.y - MOVE_MARGIN:
			move_vec.z +=1
	move_vec = move_vec.rotated(Vector3(0,1,0), rad_to_deg(rotation.y))
	global_translate(move_vec * delta * MOVE_SPEED)
