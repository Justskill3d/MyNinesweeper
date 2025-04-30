extends TileMap

@export_category("Board")
@export var cell_rows: int = 15
@export var cell_columns: int = 15
@export var monstercount: int = int(cell_rows * cell_columns * 0.2)
const CELL_SIZE = 16
@onready var myTileMap = $"."

var tile_id = 0

# Layers
var background_layer: int = 0
var monster_layer: int = 1
var numbers_layer: int = 2
var cover_layer: int = 3
var mark_layer: int = 4
var hover: int = 5

# Atlas-Koordinaten
var monster_atlas := Vector2i(5, 3)
var number_1_atlas := Vector2i(0, 0)
var number_2_atlas := Vector2i(1, 0)
var number_3_atlas := Vector2i(2, 0)
var number_4_atlas := Vector2i(3, 0)
var number_5_atlas := Vector2i(4, 0)
var number_6_atlas := Vector2i(0, 1)
var number_7_atlas := Vector2i(1, 1)
var number_8_atlas := Vector2i(2, 1)
var number_9_atlas := Vector2i(3, 1)
var number_0_atlas := Vector2i(4, 1)

var mark_atlas := Vector2i(4,3)

# Board als Array
var board_array = []  # speichert die Werte der Zellen
var monster_array = []  # speichert die Positionen der Monster

func _ready():
	newGame()

func _process(delta):
	pass
	
func newGame():
	CreateBoardArray()
	monster_array.clear()
	generate_mines()
	generate_numbers()
	generate_Numbers_onboard()
	printBoard()
	coverBoard()
	
func CreateBoardArray():
	# board_array[y][x] mit y als Zeile und x als Spalte
	board_array.clear()
	for y in range(cell_rows):
		board_array.append([])
		for x in range(cell_columns):
			board_array[y].append(0)
	
func generate_mines():
	# Setze den Hintergrund
	var odd = true
	for y in range(cell_rows):
		for x in range(cell_columns):
			if odd:
				set_cell(background_layer, Vector2i(x, y), tile_id, Vector2i(0, 6))
				odd = false
			else:
				set_cell(background_layer, Vector2i(x, y), tile_id, Vector2i(1, 6))
				odd = true
				
	# Platziere die Monster zufällig
	for i in range(monstercount):
		var monster_position = Vector2i(randi_range(0, cell_columns - 1), randi_range(0, cell_rows - 1))
		while monster_array.has(monster_position):
			monster_position = Vector2i(randi_range(0, cell_columns - 1), randi_range(0, cell_rows - 1))
		monster_array.append(monster_position)
		# Füge das Monster der Monster-Layer hinzu
		set_cell(monster_layer, monster_position, tile_id, monster_atlas)

func generate_numbers():
	# Für jede Zelle: Falls ein Monster vorhanden ist, erhöhe die Zähler der umliegenden Zellen
	for y in range(cell_rows):
		for x in range(cell_columns):
			if is_monster(x, y):
				print("Monster bei ", str(x) + " " + str(y))
				addCount(x, y)
			
func printBoard():
	var myoutput = ""
	for y in range(cell_rows):
		for x in range(cell_columns):	
			myoutput += " " + str(board_array[y][x])
		myoutput += "\n"
	print(myoutput)	
	
func is_monster(x, y):
	# x = Spalte, y = Zeile
	return get_cell_source_id(monster_layer, Vector2i(x, y)) != -1
	
func addCount(x, y):
	# Erhöhe die Werte in den umliegenden 8 Zellen (3x3-Umgebung um das Monster)
	for xi in range(3):
		for yi in range(3):
			var nx = x + xi - 1
			var ny = y + yi - 1
			if nx >= 0 and ny >= 0 and nx < cell_columns and ny < cell_rows:
				# Überspringe das Monster selbst
				if nx == x and ny == y:
					continue
				board_array[ny][nx] += 1
				print(ny, " ", nx)
				print("")

func generate_Numbers_onboard():
	# Platziere die Zahlen basierend auf board_array
	for y in range(cell_rows):
		for x in range(cell_columns):
			var value_in_cell = board_array[y][x]
			var number_atlas = get_number_atlas(value_in_cell)
			if is_monster(x,y):
				pass
			else:
				set_cell(numbers_layer, Vector2i(x, y), tile_id, number_atlas)
	pass
		
func get_number_atlas(value: int) -> Vector2i:
	match value:
		0: return number_0_atlas
		1: return number_1_atlas
		2: return number_2_atlas
		3: return number_3_atlas
		4: return number_4_atlas
		5: return number_5_atlas
		6: return number_6_atlas
		7: return number_7_atlas
		8: return number_8_atlas
		9: return number_9_atlas
	return Vector2i(-1, -1)  # Falls ein ungültiger Wert kommt

func coverBoard():
	# Decke alle Zellen mit einem Cover-Tile zu
	for y in range(cell_rows):
		for x in range(cell_columns):
			set_cell(cover_layer, Vector2i(x, y), tile_id, Vector2i(1, 3))
			
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()  # Mausposition holen
		var cell = local_to_map(to_local(mouse_pos)) # In TileMap-Koordinaten umwandeln

		# Prüfen, ob der Klick innerhalb des Spielfelds liegt
		if cell.x < 0 or cell.x >= cell_columns or cell.y < 0 or cell.y >= cell_rows:
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			# Linksklick: Zelle aufdecken
			reveal_cell(cell.x, cell.y)
			try_open_surrounding_cells(cell.x, cell.y)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Rechtsklick: Markierung setzen oder entfernen
			if get_cell_source_id(mark_layer, cell) == -1:
				set_cell(mark_layer, cell, tile_id, mark_atlas) # Markierungs-Tile
			else:
				erase_cell(mark_layer, cell)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			# Mittelklick: Prüfen, ob genug Markierungen vorhanden sind
			try_open_surrounding_cells(cell.x, cell.y)


func reveal_cell(x: int, y: int):
	# 1. Stelle sicher, dass die Koordinaten gültig sind
	if x < 0 or x >= cell_columns or y < 0 or y >= cell_rows:
		return  # Außerhalb des Spielfelds

	# 2. Falls die Zelle bereits aufgedeckt wurde
	if get_cell_source_id(cover_layer, Vector2i(x, y)) == -1:
		return  # Bereits aufgedeckt

	# 3. Falls die Zelle ein Monster enthält, nichts unternehmen
	if is_monster(x, y):
		"""Eigene Funktion einfügen """
		clickedMonster(x,y)
		$"../player".setLives($"../player".lives-1)
		erase_cell(cover_layer, Vector2i(x, y))
		print ($"../player".lives)
		print("Monster gefunden bei: ", x, ", ", y)
		return

	# 4. Wert der aktuellen Zelle abrufen (board_array[y][x])
	var value = board_array[y][x]
	print("Revealing cell at: ", x, ", ", y, " with value: ", value)
	erase_cell(cover_layer, Vector2i(x, y))  # Zelle aufdecken

	# 5. Falls der Wert > 0 ist, Rekursion abbrechen
	if value > 0:
		return

	# 6. Falls es eine 0 ist, alle 8 Nachbarn aufdecken
	var directions = [
		Vector2i(1, 0),   # Rechts
		Vector2i(-1, 0),  # Links
		Vector2i(0, 1),   # Unten
		Vector2i(0, -1),  # Oben
		Vector2i(1, 1),   # Unten rechts (Diagonal)
		Vector2i(-1, -1), # Oben links (Diagonal)
		Vector2i(1, -1),  # Oben rechts (Diagonal)
		Vector2i(-1, 1)   # Unten links (Diagonal)
	]

	# Rekursiver Aufruf für alle benachbarten Zellen
	for dir in directions:
		reveal_cell(x + dir.x, y + dir.y)

func clickedMonster(x,y):
	#update Playerstats
	$"../player".updateStats(1)
	
func try_open_surrounding_cells(x: int, y: int):
	# Stelle sicher, dass die Zelle bereits aufgedeckt ist
	if get_cell_source_id(cover_layer, Vector2i(x, y)) != -1:
		return  # Noch nicht aufgedeckt, daher keine Aktion

	var value = board_array[y][x]  # Zahl in der Zelle
	if value == 0:
		return  # Falls es eine 0 ist, gibt es nichts zu öffnen

	# Zählen, wie viele markierte und aufgedeckte Minen drumherum sind
	var marked_mines = 0
	var revealed_mines = 0
	var neighbors = get_neighbors(x, y)

	for neighbor in neighbors:
		# Prüfen, ob eine Flagge gesetzt ist
		if get_cell_source_id(mark_layer, neighbor) != -1:
			marked_mines += 1  

		# Prüfen, ob es eine aufgedeckte Mine ist
		if is_monster(neighbor.x, neighbor.y) and get_cell_source_id(cover_layer, neighbor) == -1:
			revealed_mines += 1  

	# Falls die Anzahl der Flaggen oder der aufgedeckten Minen übereinstimmt, öffne Nachbarzellen
	if marked_mines == value or revealed_mines == value:
		for neighbor in neighbors:
			# Nur aufdecken, wenn kein Marker gesetzt ist und es nicht bereits offen ist
			if get_cell_source_id(mark_layer, neighbor) == -1 and get_cell_source_id(cover_layer, neighbor) != -1:
				reveal_cell(neighbor.x, neighbor.y)


				
func get_neighbors(x: int, y: int) -> Array:
	var directions = [
		Vector2i(1, 0),   # Rechts
		Vector2i(-1, 0),  # Links
		Vector2i(0, 1),   # Unten
		Vector2i(0, -1),  # Oben
		Vector2i(1, 1),   # Unten rechts
		Vector2i(-1, -1), # Oben links
		Vector2i(1, -1),  # Oben rechts
		Vector2i(-1, 1)   # Unten links
	]

	var neighbors = []
	for dir in directions:
		var neighbor = Vector2i(x + dir.x, y + dir.y)
		if neighbor.x >= 0 and neighbor.x < cell_columns and neighbor.y >= 0 and neighbor.y < cell_rows:
			neighbors.append(neighbor)

	return neighbors


