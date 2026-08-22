extends Sprite2D

const BOARD_SIZE = 8
const CELL_WIDTH = 18

const TEXTURE_HOLDER = preload("uid://b7m1yfdh8mmw0")
const PIECE_MOVE = preload("uid://b82dmpbmvnvq3")


const BLACK_BISHOP = preload("uid://ueg18buu3rxy")
const BLACK_KING = preload("uid://cja8lj6vhkhl4")
const BLACK_KNIGHT = preload("uid://dfav220b5vlny")
const BLACK_PAWN = preload("uid://cossfpe8ypg1c")
const BLACK_QUEEN = preload("uid://f80jjqa0ir84")
const BLACK_ROOK = preload("uid://drd2s5g14dj6p")
const WHITE_BISHOP = preload("uid://cbwmbupywfelr")
const WHITE_KING = preload("uid://cf1rbmrqelxme")
const WHITE_KNIGHT = preload("uid://d2al00w70n1nu")
const WHITE_PAWN = preload("uid://bfkfbxsupvby7")
const WHITE_QUEEN = preload("uid://dyfhhhidvs03n")
const WHITE_ROOK = preload("uid://cn4b6j0ydgc2y")

const TURN_BLACK = preload("uid://cn12c5yh5pp7p")
const TURN_WHITE = preload("uid://b71gcxq0avufr")

@onready var pieces: Node2D = $Pieces
@onready var dots: Node2D = $Dots
@onready var turn: Sprite2D = $Turn

# Variaveis
# -6 = Rei preto
# -5 = Rainha preto
# -4 = Torre preto
# -3 = Bispo preto
# -2 = Cavalo preto
# -1 = Peao preto
# 0 = Vazio
# 1 = Peao branco
# 2 = Cavalo branco
# 3 = Bispo branco
# 4 = Torre branco
# 5 = Rainha branco
# 6 = Rei branco

var board : Array
var white : bool = true
var state : bool = false
var moves = []
var selected_piece : Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	board.append([4, 2, 3, 5, 6, 3, 2, 4])
	board.append([1, 1, 1, 1, 1, 1, 1, 1])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([-1, -1, -1, -1, -1, -1, -1, -1])
	board.append([-4, -2, -3, -5, -6, -3, -2, -4])
	
	display_board()

func _input(event):
	if event is InputEventMouseButton && event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_mouse_out(): return
			var var1 = snapped(get_global_mouse_position().x, 0) / CELL_WIDTH
			var var2 = abs(snapped(get_global_mouse_position().y, 0)) / CELL_WIDTH
			if !state && (white && board[var2][var1] > 0 || !white && board[var2][var1] < 0):
				selected_piece = Vector2(var2, var1)
				show_options()
				state = true
			elif state: set_move(var2, var1)
 			
func is_mouse_out():
	if get_global_mouse_position().x < 0 || get_global_mouse_position().x > 144 || get_global_mouse_position().y > 0 || get_global_mouse_position().y < -144: return true
	return false
	
func display_board():
	for child in pieces.get_children():
		child.queue_free()
		
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = TEXTURE_HOLDER.instantiate()
			pieces.add_child(holder)
			@warning_ignore("integer_division")
			holder.global_position = Vector2(j * CELL_WIDTH + (CELL_WIDTH / 2), -i * CELL_WIDTH - (CELL_WIDTH / 2))
			
			match board[i][j] :
				-6: holder.texture = BLACK_KING
				-5: holder.texture = BLACK_QUEEN
				-4: holder.texture = BLACK_ROOK
				-3: holder.texture = BLACK_BISHOP
				-2: holder.texture = BLACK_KNIGHT
				-1: holder.texture = BLACK_PAWN
				0: holder.texture = null
				6: holder.texture = WHITE_KING
				5: holder.texture = WHITE_QUEEN
				4: holder.texture = WHITE_ROOK
				3: holder.texture = WHITE_BISHOP
				2: holder.texture = WHITE_KNIGHT
				1: holder.texture = WHITE_PAWN
				
	if white: turn.texture = TURN_WHITE
	else: turn.texture = TURN_BLACK

func show_options():
	moves = get_moves()
	if moves == []:
		state = false
		return
	show_dots()
	
func show_dots():
	for i in moves:
		var holder = TEXTURE_HOLDER.instantiate()
		dots.add_child(holder)
		holder.texture = PIECE_MOVE
		holder.global_position = Vector2(i.y * CELL_WIDTH + (CELL_WIDTH / 2), -i.x * CELL_WIDTH - (CELL_WIDTH / 2))
	
func delete_dots():
	for child in dots.get_children():
		child.queue_free()
		
func set_move(var2, var1):
	for i in moves:
		if i.x == var2 && i.y == var1:
			board[var2][var1] = board[selected_piece.x][selected_piece.y]
			board[selected_piece.x][selected_piece.y] = 0
			white = !white
			display_board()
			break
	delete_dots()
	state = false
	
	
func get_moves():
	var _moves = []
	match abs(board[selected_piece.x][selected_piece.y]):
		1: _moves = get_pawn_moves()
		2: _moves = get_knight_moves()
		3: _moves = get_bishop_moves()
		4: _moves = get_rook_moves()
		5: _moves = get_queen_moves()
		6: _moves = get_king_moves()
	return _moves
	
func get_rook_moves():
	var _moves = []
	var directions = [Vector2(0,1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]
	
	for i in directions:
		var pos = selected_piece
		pos += i
		while is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
			elif is_enemy(pos): 
				_moves.append(pos)
				break
			else: break
			pos += i
	return _moves
	
func get_bishop_moves():
	var _moves = []
	var directions = [Vector2(1,1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	
	for i in directions:
		var pos = selected_piece
		pos += i
		while is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
			elif is_enemy(pos): 
				_moves.append(pos)
				break
			else: break
			pos += i
	return _moves
	
func get_queen_moves():
	var _moves = []
	var directions = [Vector2(0,1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0), Vector2(1,1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	
	for i in directions:
		var pos = selected_piece
		pos += i
		while is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
			elif is_enemy(pos): 
				_moves.append(pos)
				break
			else: break
			pos += i
	return _moves
	
func get_king_moves():
	var _moves = []
	var directions = [Vector2(0,1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0), Vector2(1,1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	
	for i in directions:
		var pos = selected_piece + i
		if is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
			elif is_enemy(pos): 
				_moves.append(pos)
	return _moves
	
func get_knight_moves():
	var _moves = []
	var directions = [Vector2(2, 1), Vector2(2, -1), Vector2(1, 2), Vector2(-1, 2), 
	Vector2(-2, 1), Vector2(-2, -1), Vector2(-1, 2), Vector2(-1, -2)]
	
	for i in directions:
		var pos = selected_piece + i
		if is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
			elif is_enemy(pos): 
				_moves.append(pos)
	return _moves
	
func get_pawn_moves():
	var _moves = []
	var direction
	var is_first_move = false
	
	if white: direction = Vector2(1, 0)
	else: direction = Vector2(-1, 0)
	
	if white && selected_piece.x == 1 || !white && selected_piece.x == 6: is_first_move = true
	
	var pos = selected_piece + direction
	if is_empty(pos): _moves.append(pos)
	
	pos = selected_piece + Vector2(direction.x, 1) 
	if is_valid_position(pos):
		if is_enemy(pos): _moves.append(pos)
	pos = selected_piece + Vector2(direction.x, -1) 
	if is_valid_position(pos):
		if is_enemy(pos): _moves.append(pos)
		
	pos = selected_piece + direction * 2
	if is_first_move && is_empty(pos) && is_empty(selected_piece + direction): _moves.append(pos)
	
	return _moves
	
func is_valid_position(pos: Vector2):
	if pos.x >= 0 && pos.x < BOARD_SIZE && pos.y >= 0 && pos.y < BOARD_SIZE: return true
	return false

func is_empty(pos: Vector2):
	if board[pos.x][pos.y] == 0: return true
	return false
	
func is_enemy(pos: Vector2):
	if white && board[pos.x][pos.y] < 0 || !white && board[pos.x][pos.y] > 0: return true
	return false
	
