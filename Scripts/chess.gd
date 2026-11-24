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

# Substitua pelos caminhos reais dos seus arquivos de áudio (.wav, .ogg ou .mp3)
const MOVE_SOUND = preload("res://Assets/move-self.mp3")
const CAPTURE_SOUND = preload("res://Assets/capture.mp3")

@onready var pieces: Node2D = $pieces
@onready var dots: Node2D = $dots
@onready var turn: Sprite2D = $turn
@onready var white_pieces: Control = $"../../CanvasLayer/white_pieces"
@onready var black_pieces: Control = $"../../CanvasLayer/black_pieces"

var move_audio_player: AudioStreamPlayer
var pending_promotion_capture: bool = false

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
var w_king_moved : bool = false
var b_king_moved : bool = false
var w_rook_left_moved : bool = false
var w_rook_right_moved : bool = false
var b_rook_left_moved : bool = false
var b_rook_right_moved : bool = false
var en_passant: Vector2 = Vector2(-1,-1)

var vs_ai: bool = true
var ai_plays_white: bool = false # false = IA joga de pretas, true = IA joga de brancas
var ai_thinking: bool = false
var ai_search_depth: int = 3 # Profundidade padrão (1 = muito fácil, 2 = casual, 3 = desafiador)

var promotion_square = null
var game_over: bool = false

var fifty_move_rule = 0
var unique_board_moves : Array = []
var amount_of_same : Array = []

func _ready():
	# Configura o player de áudio automaticamente
	move_audio_player = AudioStreamPlayer.new()
	add_child(move_audio_player)

	board.append([-4, -2, -3, -5, -6, -3, -2, -4])
	board.append([-1, -1, -1, -1, -1, -1, -1, -1])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([1, 1, 1, 1, 1, 1, 1, 1])
	board.append([4, 2, 3, 5, 6, 3, 2, 4])
	display_board()
	
	var white_buttons = get_tree().get_nodes_in_group("white_pieces")
	var black_buttons = get_tree().get_nodes_in_group("black_pieces")
	
	for button in white_buttons:
		button.pressed.connect(self._on_button_pressed.bind(button))
		
	for button in black_buttons:
		button.pressed.connect(self._on_button_pressed.bind(button))

	if vs_ai and white == ai_plays_white:
		trigger_ai_turn()


func play_move_sound(is_capture: bool):
	move_audio_player.stream = CAPTURE_SOUND if is_capture else MOVE_SOUND
	move_audio_player.play()


func _input(event):
	if game_over or ai_thinking:
		return
	if vs_ai and white == ai_plays_white:
		return
	
	if game_over:
		return

	if event is InputEventMouseButton and event.pressed && promotion_square == null:
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
				state = true
				show_options()

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
			# Verifica se o lance resulta em captura (normal ou en passant)
			var is_capture: bool = is_enemy(Vector2(row, col))
			if abs(board[selected_piece.x][selected_piece.y]) == 1 and col != selected_piece.y and board[row][col] == 0:
				is_capture = true

			match board[selected_piece.x][selected_piece.y]:
				1:
					if move.x == 0:
						pending_promotion_capture = is_capture
						promote(move)
						delete_dots()
						state = false
						return
				-1:
					if move.x == 7:
						pending_promotion_capture = is_capture
						promote(move)
						delete_dots()
						state = false
						return

			# Esvazia a posição sofrida pelo en passant
			if en_passant == Vector2(row-1,col) and board[selected_piece.x][selected_piece.y] == 1:
				board[row+1][col] = 0
			elif en_passant == Vector2(row+1,col) and board[selected_piece.x][selected_piece.y] == -1:
				board[row-1][col] = 0
			
			# Passagem do posto do en passante entre os peões da rodada
			if white and board[selected_piece.x][selected_piece.y] == 1 and selected_piece.x == 6 and row == 4:
				en_passant = selected_piece
			elif not white and board[selected_piece.x][selected_piece.y] == -1 and selected_piece.x == 1 and row == 3:
				en_passant = selected_piece
			else:
				en_passant = Vector2(-1,-1)
			
			# Lógica da Regra dos 50 Movimentos
			fifty_move_rule += 1
			if is_capture or abs(board[selected_piece.x][selected_piece.y]) == 1:
				fifty_move_rule = 0

			# Move a peça
			board[row][col] = board[selected_piece.x][selected_piece.y]

			# Esvazia a posição antiga
			board[selected_piece.x][selected_piece.y] = 0
			
			# Verifica se o rei se moveu
			if not w_king_moved and white and not board[7][4] == 6:
				w_king_moved = true
				if abs(col - selected_piece.y) == 2:
					roque(row, col)
			if not b_king_moved and not white and not board[0][4] == -6:
				b_king_moved = true
				if abs(col - selected_piece.y) == 2:
					roque(row, col)

			# Verifica se as torres saíram (ou foram capturadas) da casa original
			if not board[7][0] == 4:
				w_rook_left_moved = true
			if not board[7][7] == 4:
				w_rook_right_moved = true
			if not board[0][0] == -4:
				b_rook_left_moved = true
			if not board[0][7] == -4:
				b_rook_right_moved = true

			# Troca o turno
			white = not white

			# Atualiza o tabuleiro e toca o som correspondente
			display_board()
			play_move_sound(is_capture)

			# Verifica xeque, xeque-mate, afogamento e empates
			check_game_state()
			if vs_ai and not game_over and white == ai_plays_white:
				trigger_ai_turn()
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

	# Remove os movimentos que deixam o próprio rei em xeque
	var legal_moves = []
	for move in _moves:
		if not leaves_king_in_check(move):
			legal_moves.append(move)

	return legal_moves


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
	
	# Adiciona as posições do roque
	# (não pode rocar em xeque nem passando por casa atacada)
	if white:
		if not w_king_moved and not is_in_check(white):
			if is_empty(selected_piece + Vector2(0,1)) and is_empty(selected_piece + Vector2(0,2)) and board[7][7] == 4 and not w_rook_right_moved and not is_square_attacked(selected_piece + Vector2(0,1), not white):
				_moves.append(selected_piece + Vector2(0,2))
			if is_empty(selected_piece + Vector2(0,-1)) and is_empty(selected_piece + Vector2(0,-2)) and is_empty(selected_piece + Vector2(0,-3)) and board[7][0] == 4 and not w_rook_left_moved and not is_square_attacked(selected_piece + Vector2(0,-1), not white):
				_moves.append(selected_piece + Vector2(0,-2))
	else:
		if not b_king_moved and not is_in_check(white):
			if is_empty(selected_piece + Vector2(0,1)) and is_empty(selected_piece + Vector2(0,2)) and board[0][7] == -4 and not b_rook_right_moved and not is_square_attacked(selected_piece + Vector2(0,1), not white):
				_moves.append(selected_piece + Vector2(0,2))
			if is_empty(selected_piece + Vector2(0,-1)) and is_empty(selected_piece + Vector2(0,-2)) and is_empty(selected_piece + Vector2(0,-3)) and board[0][0] == -4 and not b_rook_left_moved and not is_square_attacked(selected_piece + Vector2(0,-1), not white):
				_moves.append(selected_piece + Vector2(0,-2))

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
	
	# Verificar se é possível realizar o en passante pela direita
	if white:
		if is_valid_position(pos) and en_passant == Vector2(pos.x-1,pos.y):
			_moves.append(pos)
	else:
		if is_valid_position(pos) and en_passant == Vector2(pos.x+1,pos.y):
			_moves.append(pos)

	# Captura diagonal esquerda
	pos = selected_piece + Vector2(direction.x, -1)

	if is_valid_position(pos) and is_enemy(pos):
		_moves.append(pos)
	
	# Verificar se é possível realizar o en passante pela esquerda
	if white:
		if is_valid_position(pos) and en_passant == Vector2(pos.x-1,pos.y):
			_moves.append(pos)
	else:
		if is_valid_position(pos) and en_passant == Vector2(pos.x+1,pos.y):
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


func promote(_var : Vector2):
	promotion_square = _var
	board[selected_piece.x][selected_piece.y] = 0
	
	# Se for a vez da IA, promove automaticamente (padrão: Rainha = 5)
	if vs_ai and white == ai_plays_white:
		var chosen_piece = choose_ai_promotion()
		board[promotion_square.x][promotion_square.y] = chosen_piece if white else -chosen_piece
		promotion_square = null
		fifty_move_rule = 0
		white = not white
		display_board()
		play_move_sound(pending_promotion_capture)
		pending_promotion_capture = false
		check_game_state()
		return

	white_pieces.visible = white
	black_pieces.visible = !white


func _on_button_pressed(button):
	var num_char = int(button.name.substr(0, 1))
	board[promotion_square.x][promotion_square.y] = num_char if white else -num_char
	white_pieces.visible = false
	black_pieces.visible = false
	promotion_square = null
	fifty_move_rule = 0
	white = not white
	display_board()
	play_move_sound(pending_promotion_capture)
	pending_promotion_capture = false

	# Verifica xeque, xeque-mate, afogamento e empates
	check_game_state()
	if vs_ai and not game_over and white == ai_plays_white:
		trigger_ai_turn()


func insuficient_material() -> bool:
	var white_piece = 0
	var black_piece = 0

	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			match board[i][j]:
				2, 3:
					if white_piece == 0:
						white_piece += 1
					else:
						return false
				-2, -3:
					if black_piece == 0:
						black_piece += 1
					else:
						return false
				6, -6, 0:
					pass
				_:
					return false
	return true


func threefold_position(var1 : Array) -> bool:
	for i in unique_board_moves.size():
		if var1 == unique_board_moves[i]:
			amount_of_same[i] += 1
			if amount_of_same[i] >= 3:
				return true
	unique_board_moves.append(var1.duplicate(true))
	amount_of_same.append(1)
	
	return false


func roque(row: int, col: int):
	if board[row][col + 1] == 4 or board[row][col + 1] == -4:
		board[row][col-1] = board[row][col+1]
		board[row][col+1] = 0
	else:
		if board[row][col - 2] == 4 or board[row][col - 2] == -4:
			board[row][col+1] = board[row][col-2]
			board[row][col-2] = 0


# Verifica se a casa "pos" é atacada por alguma peça da cor "by_white"
func is_square_attacked(pos: Vector2, by_white: bool):
	var s = 1 if by_white else -1

	# Peões (o peão branco ataca para cima, então fica uma linha abaixo)
	var pawn_row = pos.x + 1 if by_white else pos.x - 1
	for p in [Vector2(pawn_row, pos.y + 1), Vector2(pawn_row, pos.y - 1)]:
		if is_valid_position(p) and board[p.x][p.y] == 1 * s:
			return true

	# Cavalos
	var knight_directions = [
		Vector2(2, 1),
		Vector2(2, -1),
		Vector2(1, 2),
		Vector2(1, -2),
		Vector2(-2, 1),
		Vector2(-2, -1),
		Vector2(-1, 2),
		Vector2(-1, -2)
	]

	for direction in knight_directions:
		var p = pos + direction
		if is_valid_position(p) and board[p.x][p.y] == 2 * s:
			return true

	# Rei, torre, bispo e rainha
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
		var straight = direction.x == 0 or direction.y == 0
		var p = pos + direction
		var distance = 1

		while is_valid_position(p):
			if not is_empty(p):
				var piece = board[p.x][p.y]
				if piece == 5 * s:
					return true
				if straight and piece == 4 * s:
					return true
				if not straight and piece == 3 * s:
					return true
				if distance == 1 and piece == 6 * s:
					return true
				break

			p += direction
			distance += 1

	return false


func is_in_check(is_white: bool):
	var king = 6 if is_white else -6

	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			if board[i][j] == king:
				return is_square_attacked(Vector2(i, j), not is_white)

	return false


# Simula o movimento, verifica o rei e desfaz a simulação
func leaves_king_in_check(move: Vector2):
	var piece = board[selected_piece.x][selected_piece.y]
	var captured = board[move.x][move.y]

	# En passant: o peão capturado não está na casa de destino
	var en_passant_capture = abs(piece) == 1 and move.y != selected_piece.y and captured == 0
	var en_passant_piece = 0
	if en_passant_capture:
		en_passant_piece = board[selected_piece.x][move.y]
		board[selected_piece.x][move.y] = 0

	board[move.x][move.y] = piece
	board[selected_piece.x][selected_piece.y] = 0

	var in_check = is_in_check(white)

	# Desfaz a simulação
	board[selected_piece.x][selected_piece.y] = piece
	board[move.x][move.y] = captured
	if en_passant_capture:
		board[selected_piece.x][move.y] = en_passant_piece

	return in_check


# Verifica se o jogador da vez tem pelo menos um movimento legal
func has_any_legal_move():
	var original_selected = selected_piece

	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			if (white and board[i][j] > 0) or (not white and board[i][j] < 0):
				selected_piece = Vector2(i, j)
				if not get_moves().is_empty():
					selected_piece = original_selected
					return true

	selected_piece = original_selected
	return false


# Chamada após cada lance, já com o turno trocado
func check_game_state():
	if not has_any_legal_move():
		game_over = true
		if is_in_check(white):
			print("Xeque-mate! Pretas vencem" if white else "Xeque-mate! Brancas vencem")
		else:
			print("Afogamento! Empate")
		return

	# Verificações de Empate (50 lances, material insuficiente ou repetição tríplice)
	if fifty_move_rule == 50 or insuficient_material() or threefold_position(board):
		game_over = true
		print("Empate!")
		return

	if is_in_check(white):
		print("Xeque!")
		
# ==========================================
# INTELIGÊNCIA ARTIFICIAL (ADVERSÁRIO)
# ==========================================

func trigger_ai_turn():
	ai_thinking = true
	# Pequeno delay (0.4s) para o jogador conseguir ver o próprio lance antes da resposta
	await get_tree().create_timer(0.4).timeout
	
	if game_over:
		ai_thinking = false
		return

	var all_moves = get_all_legal_moves_for_current_turn()
	
	if not all_moves.is_empty():
		var chosen = choose_best_move(all_moves)
		execute_ai_move(chosen["from"], chosen["to"])
		
	ai_thinking = false


# Retorna um Array de Dicionários: [{ "from": Vector2, "to": Vector2 }, ...]
func get_all_legal_moves_for_current_turn() -> Array:
	var all_moves: Array = []
	var original_selected = selected_piece

	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			if (white and board[i][j] > 0) or (not white and board[i][j] < 0):
				selected_piece = Vector2(i, j)
				var piece_moves = get_moves()
				for target in piece_moves:
					all_moves.append({
						"from": Vector2(i, j),
						"to": target
					})

	selected_piece = original_selected
	return all_moves


# PONTO DE EXTENSÃO: Escolhe o melhor lance usando Minimax com Poda Alpha-Beta
func choose_best_move(all_moves: Array, depth: int = ai_search_depth) -> Dictionary:
	var best_move: Dictionary = {}
	var alpha: float = -INF
	var beta: float = INF
	
	# Embaralha os lances para evitar partidas idênticas quando houver empate de pontuação
	all_moves.shuffle()
	
	if white:
		var max_eval: float = -INF
		for move in all_moves:
			var state_backup = make_simulated_move(move["from"], move["to"])
			var eval = minimax(depth - 1, alpha, beta, false)
			undo_simulated_move(state_backup)
			
			if eval > max_eval:
				max_eval = eval
				best_move = move
			alpha = max(alpha, eval)
	else:
		var min_eval: float = INF
		for move in all_moves:
			var state_backup = make_simulated_move(move["from"], move["to"])
			var eval = minimax(depth - 1, alpha, beta, true)
			undo_simulated_move(state_backup)
			
			if eval < min_eval:
				min_eval = eval
				best_move = move
			beta = min(beta, eval)
			
	return best_move


func minimax(depth: int, alpha: float, beta: float, is_maximizing: bool) -> float:
	if depth == 0:
		return evaluate_board()
		
	var legal_moves = get_all_legal_moves_for_current_turn()
	
	# Fim de jogo na simulação (Xeque-mate ou Afogamento)
	if legal_moves.is_empty():
		if is_in_check(white):
			# Adiciona 'depth' para a IA preferir mates mais rápidos e adiar derrotas
			return (-100000.0 - depth) if is_maximizing else (100000.0 + depth)
		return 0.0 # Empate por afogamento

	if is_maximizing:
		var max_eval: float = -INF
		for move in legal_moves:
			var state_backup = make_simulated_move(move["from"], move["to"])
			var eval = minimax(depth - 1, alpha, beta, false)
			undo_simulated_move(state_backup)
			
			max_eval = max(max_eval, eval)
			alpha = max(alpha, eval)
			if beta <= alpha:
				break # Poda Beta
		return max_eval
	else:
		var min_eval: float = INF
		for move in legal_moves:
			var state_backup = make_simulated_move(move["from"], move["to"])
			var eval = minimax(depth - 1, alpha, beta, true)
			undo_simulated_move(state_backup)
			
			min_eval = min(min_eval, eval)
			beta = min(beta, eval)
			if beta <= alpha:
				break # Poda Alpha
		return min_eval


# ==========================================
# AVALIAÇÃO E SIMULAÇÃO DE TABULEIRO
# ==========================================

# Retorna positivo se as Brancas estiverem em vantagem, negativo se as Pretas estiverem
func evaluate_board() -> float:
	var score: float = 0.0
	
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var piece = board[i][j]
			if piece == 0:
				continue
				
			var value: float = 0.0
			match abs(piece):
				1: value = 100.0
				2: value = 320.0
				3: value = 330.0
				4: value = 500.0
				5: value = 900.0
				6: value = 20000.0
				
			# Pequeno bônus posicional para incentivar o controle do centro do tabuleiro
			var center_bonus = (3.5 - abs(3.5 - i)) + (3.5 - abs(3.5 - j))
			value += center_bonus * 2.0
			
			if piece > 0:
				score += value
			else:
				score -= value
				
	return score


# Executa um lance silenciosamente no tabuleiro e retorna um backup completo do estado
func make_simulated_move(from: Vector2, to: Vector2) -> Dictionary:
	var piece = board[from.x][from.y]
	var captured = board[to.x][to.y]
	
	var backup = {
		"from": from,
		"to": to,
		"piece": piece,
		"captured": captured,
		"white": white,
		"en_passant": en_passant,
		"w_king_moved": w_king_moved,
		"b_king_moved": b_king_moved,
		"w_rook_left_moved": w_rook_left_moved,
		"w_rook_right_moved": w_rook_right_moved,
		"b_rook_left_moved": b_rook_left_moved,
		"b_rook_right_moved": b_rook_right_moved,
		"en_passant_captured_pos": Vector2(-1, -1),
		"en_passant_captured_piece": 0,
		"rook_from": Vector2(-1, -1),
		"rook_to": Vector2(-1, -1)
	}
	
	# 1. Simula captura En Passant
	if abs(piece) == 1 and to.y != from.y and captured == 0:
		var ep_pos = Vector2(from.x, to.y)
		backup["en_passant_captured_pos"] = ep_pos
		backup["en_passant_captured_piece"] = board[ep_pos.x][ep_pos.y]
		board[ep_pos.x][ep_pos.y] = 0
		
	# 2. Atualiza estado do En Passant para o próximo turno
	if white and piece == 1 and from.x == 6 and to.x == 4:
		en_passant = from
	elif not white and piece == -1 and from.x == 1 and to.x == 3:
		en_passant = from
	else:
		en_passant = Vector2(-1, -1)
		
	# 3. Move a peça (e simula promoção automática para Rainha na busca)
	if piece == 1 and to.x == 0:
		board[to.x][to.y] = 5
	elif piece == -1 and to.x == 7:
		board[to.x][to.y] = -5
	else:
		board[to.x][to.y] = piece
		
	board[from.x][from.y] = 0
	
	# 4. Simula Roque (move a torre correspondente)
	if abs(piece) == 6 and abs(to.y - from.y) == 2:
		if to.y == 6: # Roque pequeno
			backup["rook_from"] = Vector2(from.x, 7)
			backup["rook_to"] = Vector2(from.x, 5)
		elif to.y == 2: # Roque grande
			backup["rook_from"] = Vector2(from.x, 0)
			backup["rook_to"] = Vector2(from.x, 3)
			
		var r_from = backup["rook_from"]
		var r_to = backup["rook_to"]
		board[r_to.x][r_to.y] = board[r_from.x][r_from.y]
		board[r_from.x][r_from.y] = 0
		
	# 5. Atualiza flags de movimentação de Rei e Torres
	if piece == 6: w_king_moved = true
	if piece == -6: b_king_moved = true
	if board[7][0] != 4: w_rook_left_moved = true
	if board[7][7] != 4: w_rook_right_moved = true
	if board[0][0] != -4: b_rook_left_moved = true
	if board[0][7] != -4: b_rook_right_moved = true
	
	# Passa a vez na simulação
	white = not white
	
	return backup


# Restaura o tabuleiro exatamente ao estado anterior à simulação
func undo_simulated_move(backup: Dictionary):
	var from = backup["from"]
	var to = backup["to"]
	
	board[from.x][from.y] = backup["piece"]
	board[to.x][to.y] = backup["captured"]
	
	# Restaura peão capturado por En Passant
	var ep_pos = backup["en_passant_captured_pos"]
	if ep_pos != Vector2(-1, -1):
		board[ep_pos.x][ep_pos.y] = backup["en_passant_captured_piece"]
		
	# Restaura torre movida no Roque
	var r_from = backup["rook_from"]
	if r_from != Vector2(-1, -1):
		var r_to = backup["rook_to"]
		board[r_from.x][r_from.y] = board[r_to.x][r_to.y]
		board[r_to.x][r_to.y] = 0
		
	# Restaura flags globais
	white = backup["white"]
	en_passant = backup["en_passant"]
	w_king_moved = backup["w_king_moved"]
	b_king_moved = backup["b_king_moved"]
	w_rook_left_moved = backup["w_rook_left_moved"]
	w_rook_right_moved = backup["w_rook_right_moved"]
	b_rook_left_moved = backup["b_rook_left_moved"]
	b_rook_right_moved = backup["b_rook_right_moved"]


# PONTO DE EXTENSÃO: Escolha de peça na promoção (5 = Rainha, 4 = Torre, 3 = Bispo, 2 = Cavalo)
func choose_ai_promotion() -> int:
	return 5


func execute_ai_move(from: Vector2, to: Vector2):
	selected_piece = from
	moves = get_moves() # Popula 'moves' para a validação interna de set_move()
	set_move(int(to.x), int(to.y))
