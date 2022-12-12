extends Node3D

class PathItem:
	var PosGrid: Vector2;
	var Distance: int;
	
@export var grid_size = 5;
@export var enabled_debug = false;
@export var enabled_los = true;

@onready var Land = $Land;
@onready var Debug = $Debug;

# Наш грид где будет лежать навигация
var grid = [[]]
var current_grid = [[]]
var grid_los = [[]]
var debug_grid = [[]]
var flow_field = [[]]
var debug_grid_text = [[]]
var debug_grid_arrow = [[]]

var grid_width = 0;
var grid_height = 0;
var max_number = 2147483647;

# Called when the node enters the scene tree for the first time.
func _ready():
	
	grid_width = round(Land.get_aabb().size.x/grid_size)
	grid_height = round(Land.get_aabb().size.z/grid_size)
	generateDijkstraGrid()
	if enabled_debug:
		drawDebug()
	
	generateFlowFieldPath(Vector3(35, 0, 35))

# Генерируем навигационную сетку
func generateDijkstraGrid():

	grid.resize(grid_width)
	grid_los.resize(grid_width)
	for x in range (grid_width):
		
		var arr =[]
		arr.resize(grid_height)
		arr.fill(null)
		grid[x] = arr
		
		var arr2 =[]
		arr2.resize(grid_height)
		arr2.fill(false)
		grid_los[x] = arr2
	
	var obstacles = get_tree().get_nodes_in_group("obstacles")
	for obstacle in obstacles:
		
		var pos = obstacle.get_transform().origin
		pos.x = pos.x - obstacle.get_aabb().size.x/2
		pos.z = pos.z - obstacle.get_aabb().size.z/2
		var obstacle_pos_start = getGridCellPos(pos)
		
		pos.x += obstacle.get_aabb().size.x
		pos.z += obstacle.get_aabb().size.z
		var obstacle_pos_end = getGridCellPos(pos)
		
		for i in range(obstacle_pos_start.x, obstacle_pos_end.x + 1):
			for j in range(obstacle_pos_start.y, obstacle_pos_end.y + 1):
				
				grid[i][j] = max_number

func getGridCellPos(target : Vector3) -> Vector2 :
	
	var diff = Land.get_transform().origin - Land.get_aabb().size/2 - target
	var result := Vector2()
	result.x = abs(round((diff.x - grid_size/2)/grid_size))
	result.y = abs(round((diff.z - grid_size/2)/grid_size))
	
	if (result.x >= grid_width):
		result.x = grid_width -1
	if (result.y >= grid_height):
		result.y = grid_height -1	
	return result

func getLandPos(target : Vector2) -> Vector3 :
	
	var diff = Land.get_transform().origin - Land.get_aabb().size/2
	return Vector3( target.x * grid_size + diff.x, 0,   target.y * grid_size + diff.z)
	
# Генерируем путь
func generateFlowFieldPath(destinationV3 : Vector3):
	
	var destination : Vector2 = getGridCellPos(destinationV3)
	flow_field.resize(grid_width)
	for x in range (grid_width):
		
		var arr =[]
		arr.resize(grid_height)
		arr.fill(null)
		flow_field[x] = arr
	
	
	var path_end : PathItem = PathItem.new()
	path_end.PosGrid = destination
	path_end.Distance = 0
	
	current_grid = grid.duplicate(true)
	current_grid[path_end.PosGrid.x][path_end.PosGrid.y] = 0
	grid_los[path_end.PosGrid.x][path_end.PosGrid.y] = true

	var to_visit : Array[PathItem] = [path_end]

	for at in to_visit:

		if at != path_end:
			calculateLos(at.PosGrid, path_end.PosGrid)

		var neighbours = straightNeighboursOf(at)

		for n in neighbours:

			if current_grid[n.PosGrid.x][n.PosGrid.y] == null:
				n.Distance = at.Distance + 1
				current_grid[n.PosGrid.x][n.PosGrid.y] = n.Distance
				to_visit.append(n)
	
	for x in range (grid_width):
		for y in range (grid_height):

			# если встретили препятсвие, пропускаем
			if current_grid[x][y] == max_number:
				continue

			if enabled_los:
				if grid_los[x][y]:
				
					var p :Vector2 = destination
					p.x -= x
					p.y -= y
					p = p.normalized()
					flow_field[x][y] = p
					continue;

			var pos = Vector2(x, y)
			var neighbours = allNeighboursOf(pos)

			var min = null
			var minDist = 0
			for n in neighbours:
				var dist = current_grid[n.x][n.y] - current_grid[pos.x][pos.y]

				if dist < minDist :
					min = n
					minDist = dist

			if min != null :
				var v :Vector2 = min - pos;
				v = v.normalized()
				flow_field[x][y] = v
	
	if enabled_debug:
		drawDebugPath()

func allNeighboursOf(pos : Vector2) -> Array:
	
	var res = []
	var x = pos.x
	var y = pos.y

	var up = isValid(x, y - 1)
	var	down = isValid(x, y + 1)
	var	left = isValid(x - 1, y)
	var	right = isValid(x + 1, y)

	if left :
		res.append(Vector2(x - 1, y))

		if up && isValid(x - 1, y - 1) :
			res.append(Vector2(x - 1, y - 1))

	if up :
		res.append(Vector2(x, y - 1));

		if right && isValid(x + 1, y - 1) :
			res.append(Vector2(x + 1, y - 1))

	if right :
		res.append(Vector2(x + 1, y));

		if down && isValid(x + 1, y + 1) :
			res.append(Vector2(x + 1, y + 1))

	if down :
		res.append(Vector2(x, y + 1));

		if left && isValid(x - 1, y + 1) :
			res.append(Vector2(x - 1, y + 1))

	return res;

func straightNeighboursOf(v : PathItem) -> Array[PathItem] :
	
	var res : Array[PathItem] = [];
	if v.PosGrid.x > 0:
		
		var item : PathItem = PathItem.new()
		item.PosGrid = Vector2(v.PosGrid.x - 1, v.PosGrid.y)
		res.append(item)
	if v.PosGrid.y > 0:
		
		var item : PathItem = PathItem.new()
		item.PosGrid = Vector2(v.PosGrid.x, v.PosGrid.y - 1)
		res.append(item)

	if v.PosGrid.x < grid_width - 1:
		
		var item : PathItem = PathItem.new()
		item.PosGrid = Vector2(v.PosGrid.x + 1, v.PosGrid.y)
		res.append(item)
	
	if v.PosGrid.y < grid_height - 1:
		
		var item : PathItem = PathItem.new()
		item.PosGrid = Vector2(v.PosGrid.x, v.PosGrid.y + 1)
		res.append(item)

	return res;
	
func isValid(x : int, y : int) -> bool :
	
	return x >= 0 && y >= 0 && x < grid_width && y < grid_height && current_grid[x][y] !=max_number;

func calculateLos(at : Vector2, pathEnd : Vector2) :
	
	var x_dif = pathEnd.x - at.x
	var y_dif = pathEnd.y - at.y

	var x_dif_abs = abs(x_dif)
	var y_dif_abs = abs(y_dif)

	var hasLos = false

	var x_dif_one = sign(x_dif)
	var y_dif_one = sign(y_dif)

	if x_dif_abs >= y_dif_abs :

		if grid_los[at.x + x_dif_one][at.y]:
			hasLos = true
	
	if y_dif_abs >= x_dif_abs:

		if grid_los[at.x][at.y + y_dif_one] :
			hasLos = true

	if y_dif_abs > 0 && x_dif_abs > 0:
		
		if !grid_los[at.x + x_dif_one][at.y + y_dif_one]:
			hasLos = false
		else : 
			if y_dif_abs == x_dif_abs:
				if current_grid[at.x + x_dif_one][at.y] == max_number || current_grid[at.x][at.y + y_dif_one] == max_number:
					hasLos = false
	grid_los[at.x][at.y] = hasLos

		
func drawDebug() :
	
	debug_grid.resize(grid_width)
	debug_grid_text.resize(grid_width)
	debug_grid_arrow.resize(grid_width)
	for x in len(grid):
		
		var arr =[]
		arr.resize(grid_height)
		debug_grid[x] = arr
		
		var arr2 =[]
		arr2.resize(grid_height)
		debug_grid_text[x]= arr2
		
		var arr3 =[]
		arr3.resize(grid_height)
		debug_grid_arrow[x] = arr3
		for y in len(grid[x]):
			
			var block = MeshInstance3D.new()
			var mesh = PlaneMesh.new()
			mesh.size.x = grid_size-0.1
			mesh.size.y = grid_size-0.1
			block.mesh = mesh
			
			block.mesh.material = StandardMaterial3D.new()
			
			var pos = getLandPos(Vector2(x,y))
			pos.x = pos.x -grid_size/2
			pos.y = 0.05
			pos.z = pos.z -grid_size/2
			block.position = pos
			
			debug_grid[x][y] = block
			Debug.add_child(block)
			
			var arrow_block = MeshInstance3D.new()
			var arrow_mesh = PlaneMesh.new()
			arrow_mesh.size.x = grid_size-0.1
			arrow_mesh.size.y = 0.1
			arrow_block.mesh = arrow_mesh
			
			arrow_block.mesh.material = StandardMaterial3D.new()
			
			arrow_block.position = pos
			arrow_block.position.y += 0.1
			
			debug_grid_arrow[x][y] = arrow_block
			Debug.add_child(arrow_block)
			
			var text_block = MeshInstance3D.new()
			var text_mesh = TextMesh.new()
			
			text_block.rotate_x(-90)
			text_block.mesh = text_mesh
			text_block.mesh.material = StandardMaterial3D.new()
			text_block.mesh.material.set_albedo(Color(0, 0, 0, 1))
			text_block.position = pos
			text_block.position.y += 0.05
			text_mesh.pixel_size=1
			text_mesh.font_size=2
			
			debug_grid_text[x][y] = text_block
			Debug.add_child(text_block)
	pass
	
func drawDebugPath() :
	
	var green = Color(0.0, 1.0, 0.0, 1)
	var red = Color(1.0, 0.0, 0.0, 1)
	var blue  = Color(0.0, 0.0, 1.0, 1)
	
	for x in len(current_grid):
		for y in len(current_grid[x]):
			
			var color = green
			if current_grid[x][y] == max_number :
				color = red
			if current_grid[x][y] == 0 :
				color = blue
	
			debug_grid[x][y].mesh.material.set_albedo(color)
		
			if current_grid[x][y] != 0 && current_grid[x][y] != max_number :
				debug_grid_text[x][y].mesh.text = str(current_grid[x][y])	
				
			if flow_field[x][y] != null:
				var arrow_vector :Vector2 = flow_field[x][y]
				debug_grid_arrow[x][y].set_rotation(Vector3( 0, 0, 0 ))
				debug_grid_arrow[x][y].rotate_y(-arrow_vector.angle())
