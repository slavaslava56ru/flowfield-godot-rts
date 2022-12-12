extends CharacterBody3D

@onready var Grid = get_node("/root/World/Grid");

@export var max_speed = 10;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):

	if (Grid == null):
		return
		
	velocity = steeringBehaviourFlowField() * max_speed
	move_and_slide()

func steeringBehaviourFlowField() -> Vector3 :

	var pos = Grid.getGridCellPos(position)

	var f00 : Vector2 = Vector2.ZERO

	if (Grid.isValid(pos.x, pos.y)) :
		f00 = Grid.flow_field[pos.x][pos.y]
	else :
		if (Grid.isValid(pos.x, pos.y + 1)) :
			f00 = Grid.flow_field[pos.x][pos.y + 1]
		else:
			if (Grid.isValid(pos.x + 1, pos.y)) :
				f00 = Grid.flow_field[pos.x + 1][pos.y]
			else:
				if (Grid.isValid(pos.x + 1, pos.y + 1)) :
					f00 = Grid.flow_field[pos.x + 1][pos.y + 1]

	return Vector3(f00.x, 0, f00.y)
