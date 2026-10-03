extends Sprite2D

const BOARD_SIZE = 8
const CELL_WIDTH = 18
const BOARD_PIXEL_SIZE = BOARD_SIZE * CELL_WIDTH
const TARGET_PIECE_SIZE = Vector2(16, 16)
const TARGET_TURN_SIZE = Vector2(16, 16)

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

const TURN_BLACK = preload("res://Assets/turn-black.png")
const TURN_WHITE = preload("res://Assets/turn-white.png")

@onready var pieces: Node2D = $pieces
@onready var dots: Node2D = $dots
@onready var turn: Sprite2D = $turn


# -6 = Rei preto
# -5 = Rainha preta
# -4 = Torre preta
# -3 = Bispo preto
# -2 = Cavalo preto
# -1 = Peao preto
#  0 = Vazio
#  1 = Peao branco
#  2 = Cavalo branco
#  3 = Bispo branco
#  4 = Torre branca
#  5 = Rainha branca
#  6 = Rei branco

var board: Array = []
var white: bool = true
var state: bool = false
var moves: Array = []
var selected_piece: Vector2


func _ready():
	board.append([-4, -2, -3, -5, -6, -3, -2, -4])
	board.append([-1, -1, -1, -1, -1, -1, -1, -1])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([1, 1, 1, 1, 1, 1, 1, 1])
	board.append([4, 2, 3, 5, 6, 3, 2, 4])
	display_board()


func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		var board_pos = local_to_board_position(
			to_local(get_global_mouse_position())
		)

		if board_pos == null:
			return

		var row = int(board_pos.x)
		var col = int(board_pos.y)

		# Nenhuma peça selecionada
		if not state:
			# Só pode selecionar peça da cor que está jogando
			if (white and board[row][col] > 0) or (not white and board[row][col] < 0):
				selected_piece = Vector2(row, col)
				show_options()
				state = true

		# Já existe uma peça selecionada
		else:
			set_move(row, col)


func local_to_board_position(local_pos: Vector2):
	var half_board = BOARD_PIXEL_SIZE / 2.0

	var col = int(floor((local_pos.x + half_board) / CELL_WIDTH))
	var row = int(floor((local_pos.y + half_board) / CELL_WIDTH))

	if row < 0 or row >= BOARD_SIZE:
		return null

	if col < 0 or col >= BOARD_SIZE:
		return null

	return Vector2(row, col)


func board_to_local_position(row: int, col: int):
	var half_board = BOARD_PIXEL_SIZE / 2.0

	return Vector2(
		col * CELL_WIDTH + (CELL_WIDTH / 2.0) - half_board,
		row * CELL_WIDTH + (CELL_WIDTH / 2.0) - half_board
	)


func apply_texture_and_scale(holder: Node, texture: Texture2D):
	holder.texture = texture

	if texture and holder.is_in_group("pieces"):
		var tex_size = texture.get_size()

		holder.scale = Vector2(
			TARGET_PIECE_SIZE.x / tex_size.x,
			TARGET_PIECE_SIZE.y / tex_size.y
		)


func display_board():
	for child in pieces.get_children():
		child.queue_free()

	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = TEXTURE_HOLDER.instantiate()

			holder.add_to_group("pieces")
			pieces.add_child(holder)

			holder.position = board_to_local_position(i, j)

			var tex: Texture2D = null

			match board[i][j]:
				-6:
					tex = BLACK_KING
				-5:
					tex = BLACK_QUEEN
				-4:
					tex = BLACK_ROOK
				-3:
					tex = BLACK_BISHOP
				-2:
					tex = BLACK_KNIGHT
				-1:
					tex = BLACK_PAWN
				0:
					tex = null
				1:
					tex = WHITE_PAWN
				2:
					tex = WHITE_KNIGHT
				3:
					tex = WHITE_BISHOP
				4:
					tex = WHITE_ROOK
				5:
					tex = WHITE_QUEEN
				6:
					tex = WHITE_KING

			apply_texture_and_scale(holder, tex)

	# Atualiza indicador de turno
	if white:
		turn.texture = TURN_WHITE
		# Branco: barra embaixo
		turn.position = Vector2(0, BOARD_PIXEL_SIZE / 2.0)
	else:
		turn.texture = TURN_BLACK
		# Preto: barra em cima
		turn.position = Vector2(0, -BOARD_PIXEL_SIZE / 2.0)

	# Mantém o tamanho original da barra
	turn.scale = Vector2.ONE


func show_options():
	delete_dots()

	moves = get_moves()

	if moves.is_empty():
		state = false
		return

	show_dots()


func show_dots():
	for move in moves:
		var holder = TEXTURE_HOLDER.instantiate()

		dots.add_child(holder)

		apply_texture_and_scale(holder, PIECE_MOVE)

		holder.position = board_to_local_position(
			int(move.x),
			int(move.y)
		)


func delete_dots():
	for child in dots.get_children():
		child.queue_free()


func set_move(row: int, col: int):
	# Verifica se a posição clicada é um movimento válido
	for move in moves:
		if move.x == row and move.y == col:

			# Move a peça
			board[row][col] = board[selected_piece.x][selected_piece.y]

			# Esvazia a posição antiga
			board[selected_piece.x][selected_piece.y] = 0

			# Troca o turno
			white = not white

			# Atualiza o tabuleiro
			display_board()

			break

	delete_dots()
	state = false


func get_moves():
	var _moves = []

	match abs(board[selected_piece.x][selected_piece.y]):
		1:
			_moves = get_pawn_moves()
		2:
			_moves = get_knight_moves()
		3:
			_moves = get_bishop_moves()
		4:
			_moves = get_rook_moves()
		5:
			_moves = get_queen_moves()
		6:
			_moves = get_king_moves()

	return _moves


func get_rook_moves():
	var _moves = []

	var directions = [
		Vector2(0, 1),
		Vector2(0, -1),
		Vector2(1, 0),
		Vector2(-1, 0)
	]

	for direction in directions:
		var pos = selected_piece + direction

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


func get_bishop_moves():
	var _moves = []

	var directions = [
		Vector2(1, 1),
		Vector2(1, -1),
		Vector2(-1, 1),
		Vector2(-1, -1)
	]

	for direction in directions:
		var pos = selected_piece + direction

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


func get_queen_moves():
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
		var pos = selected_piece + direction

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


func get_king_moves():
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
		var pos = selected_piece + direction

		if is_valid_position(pos):
			if is_empty(pos) or is_enemy(pos):
				_moves.append(pos)

	return _moves


func get_knight_moves():
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
		var pos = selected_piece + direction

		if is_valid_position(pos):
			if is_empty(pos) or is_enemy(pos):
				_moves.append(pos)

	return _moves


func get_pawn_moves():
	var _moves = []

	var direction: Vector2

	if white:
		direction = Vector2(-1, 0)
	else:
		direction = Vector2(1, 0)

	var is_first_move = false

	if white and selected_piece.x == 6:
		is_first_move = true
	elif not white and selected_piece.x == 1:
		is_first_move = true


	# Movimento para frente
	var pos = selected_piece + direction

	if is_valid_position(pos) and is_empty(pos):
		_moves.append(pos)


	# Movimento de duas casas
	pos = selected_piece + direction * 2

	if is_first_move and is_valid_position(pos):
		if is_empty(selected_piece + direction) and is_empty(pos):
			_moves.append(pos)


	# Captura diagonal direita
	pos = selected_piece + Vector2(direction.x, 1)

	if is_valid_position(pos) and is_enemy(pos):
		_moves.append(pos)


	# Captura diagonal esquerda
	pos = selected_piece + Vector2(direction.x, -1)

	if is_valid_position(pos) and is_enemy(pos):
		_moves.append(pos)

	return _moves


func is_valid_position(pos: Vector2):
	return (
		pos.x >= 0
		and pos.x < BOARD_SIZE
		and pos.y >= 0
		and pos.y < BOARD_SIZE
	)


func is_empty(pos: Vector2):
	return board[pos.x][pos.y] == 0


func is_enemy(pos: Vector2):
	if white and board[pos.x][pos.y] < 0:
		return true

	if not white and board[pos.x][pos.y] > 0:
		return true

	return false
