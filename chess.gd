extends Sprite2D

const BOARD_SIZE = 8
const CELL_WIDTH = 18
const BOARD_PIXEL_SIZE = BOARD_SIZE * CELL_WIDTH

const TEXTURE_HOLDER = preload("res://Scenes/texture_holder.tscn")

const BLACK_BISHOP = preload("res://Assets/black_bishop.png")
const BLACK_KING = preload("res://Assets/black_king.png")
const BLACK_KNIGHT = preload("res://Assets/black_knight.png")
const BLACK_PAWN = preload("res://Assets/black_pawn.png")
const BLACK_QUEEN = preload("res://Assets/black_queen.png")
const BLACK_ROOK = preload("res://Assets/black_rook.png")
const WHITE_BISHOP = preload("res://Assets/white_bishop.png")
const WHITE_KING = preload("res://Assets/white_king.png")
const WHITE_KNIGHT = preload("res://Assets/white_knight.png")
const WHITE_PAWN = preload("res://Assets/white_pawn.png")
const WHITE_QUEEN = preload("res://Assets/white_queen.png")
const WHITE_ROOK = preload("res://Assets/white_rook.png")

const PIECE_MOVE = preload("res://Assets/Piece_move.png")

@onready var pieces = $pieces
@onready var dots = $dots

# Piece values:
# -6 = black king
# -5 = black queen
# -4 = black rook
# -3 = black bishop
# -2 = black knight
# -1 = black pawn
#  0 = empty
#  1 = white pawn
#  2 = white knight
#  3 = white bishop
#  4 = white rook
#  5 = white queen
#  6 = white king

var board: Array = []
var white: bool = true
var moves: Array = []
var selected_piece: Vector2


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
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var board_pos = local_to_board_position(to_local(get_global_mouse_position()))

			if board_pos == null:
				return

			var row = int(board_pos.x)
			var col = int(board_pos.y)

			# At this stage we only select a piece and calculate/show its moves.
			if board[row][col] != 0:
				white = board[row][col] > 0
				selected_piece = Vector2(row, col)
				show_options()


func local_to_board_position(local_pos: Vector2):
	var half_board = BOARD_PIXEL_SIZE / 2.0
	var col = int(floor((local_pos.x + half_board) / CELL_WIDTH))
	var row = int(floor((local_pos.y + half_board) / CELL_WIDTH))

	if row < 0 or row >= BOARD_SIZE or col < 0 or col >= BOARD_SIZE:
		return null

	return Vector2(row, col)


func board_to_local_position(row: int, col: int):
	var half_board = BOARD_PIXEL_SIZE / 2.0

	return Vector2(
		col * CELL_WIDTH + (CELL_WIDTH / 2.0) - half_board,
		row * CELL_WIDTH + (CELL_WIDTH / 2.0) - half_board
	)


func display_board():
	for child in pieces.get_children():
		child.queue_free()

	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = TEXTURE_HOLDER.instantiate()
			pieces.add_child(holder)
			holder.position = board_to_local_position(i, j)

			match board[i][j]:
				-6: holder.texture = BLACK_KING
				-5: holder.texture = BLACK_QUEEN
				-4: holder.texture = BLACK_ROOK
				-3: holder.texture = BLACK_BISHOP
				-2: holder.texture = BLACK_KNIGHT
				-1: holder.texture = BLACK_PAWN
				0: holder.texture = null
				1: holder.texture = WHITE_PAWN
				2: holder.texture = WHITE_KNIGHT
				3: holder.texture = WHITE_BISHOP
				4: holder.texture = WHITE_ROOK
				5: holder.texture = WHITE_QUEEN
				6: holder.texture = WHITE_KING


func show_options():
	delete_dots()
	moves = get_moves(selected_piece)
	show_dots()


func show_dots():
	for move in moves:
		var holder = TEXTURE_HOLDER.instantiate()
		dots.add_child(holder)
		holder.texture = PIECE_MOVE
		holder.position = board_to_local_position(int(move.x), int(move.y))


func delete_dots():
	for child in dots.get_children():
		child.queue_free()


func get_moves(selected: Vector2):
	var _moves = []

	match abs(board[selected.x][selected.y]):
		1: _moves = get_pawn_moves(selected)
		2: _moves = get_knight_moves(selected)
		3: _moves = get_bishop_moves(selected)
		4: _moves = get_rook_moves(selected)
		5: _moves = get_queen_moves(selected)
		6: _moves = get_king_moves(selected)

	return _moves


func get_rook_moves(piece_position: Vector2):
	var _moves = []
	var directions = [
		Vector2(0, 1),
		Vector2(0, -1),
		Vector2(1, 0),
		Vector2(-1, 0)
	]

	for direction in directions:
		var pos = piece_position + direction

		while is_valid_position(pos):
			if is_empty(pos):
				_moves.append(pos)
			elif is_enemy(pos):
				_moves.append(pos)
				break
			else:
				break

			pos += direction

	return _moves


func get_bishop_moves(piece_position: Vector2):
	var _moves = []
	var directions = [
		Vector2(1, 1),
		Vector2(1, -1),
		Vector2(-1, 1),
		Vector2(-1, -1)
	]

	for direction in directions:
		var pos = piece_position + direction

		while is_valid_position(pos):
			if is_empty(pos):
				_moves.append(pos)
			elif is_enemy(pos):
				_moves.append(pos)
				break
			else:
				break

			pos += direction

	return _moves


func get_queen_moves(piece_position: Vector2):
	var _moves = []
	var directions = [
		Vector2(0, 1),
		Vector2(0, -1),
		Vector2(1, 0),
		Vector2(-1, 0),
		Vector2(1, 1),
		Vector2(1, -1),
		Vector2(-1, 1),
		Vector2(-1, -1)
	]

	for direction in directions:
		var pos = piece_position + direction

		while is_valid_position(pos):
			if is_empty(pos):
				_moves.append(pos)
			elif is_enemy(pos):
				_moves.append(pos)
				break
			else:
				break

			pos += direction

	return _moves


func get_king_moves(piece_position: Vector2):
	var _moves = []
	var directions = [
		Vector2(0, 1),
		Vector2(0, -1),
		Vector2(1, 0),
		Vector2(-1, 0),
		Vector2(1, 1),
		Vector2(1, -1),
		Vector2(-1, 1),
		Vector2(-1, -1)
	]

	for direction in directions:
		var pos = piece_position + direction

		if is_valid_position(pos):
			if is_empty(pos) or is_enemy(pos):
				_moves.append(pos)

	return _moves


func get_knight_moves(piece_position: Vector2):
	var _moves = []
	var directions = [
		Vector2(2, 1),
		Vector2(2, -1),
		Vector2(1, 2),
		Vector2(1, -2),
		Vector2(-2, 1),
		Vector2(-2, -1),
		Vector2(-1, 2),
		Vector2(-1, -2)
	]

	for direction in directions:
		var pos = piece_position + direction

		if is_valid_position(pos):
			if is_empty(pos) or is_enemy(pos):
				_moves.append(pos)

	return _moves


func get_pawn_moves(piece_position: Vector2):
	var _moves = []
	var direction: Vector2
	var is_first_move = false

	if white:
		direction = Vector2(1, 0)
	else:
		direction = Vector2(-1, 0)

	if white and piece_position.x == 1:
		is_first_move = true
	elif not white and piece_position.x == 6:
		is_first_move = true

	# One square forward.
	var pos = piece_position + direction
	if is_valid_position(pos) and is_empty(pos):
		_moves.append(pos)

	# Two squares forward from the starting rank.
	pos = piece_position + direction * 2
	if is_first_move and is_valid_position(pos):
		if is_empty(piece_position + direction) and is_empty(pos):
			_moves.append(pos)

	# Captures diagonally.
	pos = piece_position + Vector2(direction.x, 1)
	if is_valid_position(pos) and is_enemy(pos):
		_moves.append(pos)

	pos = piece_position + Vector2(direction.x, -1)
	if is_valid_position(pos) and is_enemy(pos):
		_moves.append(pos)

	return _moves


func is_valid_position(pos: Vector2):
	return pos.x >= 0 and pos.x < BOARD_SIZE and pos.y >= 0 and pos.y < BOARD_SIZE


func is_empty(pos: Vector2):
	return board[pos.x][pos.y] == 0


func is_enemy(pos: Vector2):
	if white and board[pos.x][pos.y] < 0:
		return true
	if not white and board[pos.x][pos.y] > 0:
		return true
	return false
