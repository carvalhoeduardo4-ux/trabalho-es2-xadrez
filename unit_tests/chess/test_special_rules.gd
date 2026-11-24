extends GutTest

const MAIN_SCENE = preload("res://Scenes/main.tscn")

var game
var chess


func before_each():
	game = MAIN_SCENE.instantiate()
	add_child(game)
	chess = game.get_node("Camera2D/board")
	chess.vs_ai = false


func after_each():
	game.free()


func _clear_board():
	chess.board.clear()
	for _row in range(8):
		chess.board.append([0, 0, 0, 0, 0, 0, 0, 0])


func test_white_pawn_promotes_and_turn_switches_after_piece_selection():
	_clear_board()
	chess.board[1][0] = 1
	chess.white = true
	chess.selected_piece = Vector2(1, 0)
	chess.moves = [Vector2(0, 0)]
	chess.state = true

	chess.set_move(0, 0)

	assert_eq(chess.board[1][0], 0)
	assert_eq(chess.promotion_square, Vector2(0, 0))
	assert_true(chess.white_pieces.visible)
	assert_false(chess.black_pieces.visible)
	assert_true(chess.white)
	assert_false(chess.state)

	var queen_button = game.get_node("CanvasLayer/white_pieces/5")
	chess._on_button_pressed(queen_button)

	assert_eq(chess.board[0][0], 5)
	assert_true(chess.promotion_square == null)
	assert_false(chess.white_pieces.visible)
	assert_false(chess.black_pieces.visible)
	assert_false(chess.white)


func test_black_pawn_promotes_to_signed_piece_and_turn_switches():
	_clear_board()
	chess.board[6][7] = -1
	chess.white = false
	chess.selected_piece = Vector2(6, 7)
	chess.moves = [Vector2(7, 7)]
	chess.state = true

	chess.set_move(7, 7)

	assert_eq(chess.board[6][7], 0)
	assert_eq(chess.promotion_square, Vector2(7, 7))
	assert_false(chess.white_pieces.visible)
	assert_true(chess.black_pieces.visible)
	assert_false(chess.white)

	var knight_button = game.get_node("CanvasLayer/black_pieces/2")
	chess._on_button_pressed(knight_button)

	assert_eq(chess.board[7][7], -2)
	assert_true(chess.promotion_square == null)
	assert_false(chess.white_pieces.visible)
	assert_false(chess.black_pieces.visible)
	assert_true(chess.white)


func test_white_pawn_can_promote_to_knight():
	_clear_board()
	chess.board[1][1] = 1
	chess.white = true
	chess.selected_piece = Vector2(1, 1)
	chess.moves = [Vector2(0, 1)]
	chess.set_move(0, 1)
	var knight_button = game.get_node("CanvasLayer/white_pieces/2")
	chess._on_button_pressed(knight_button)
	assert_eq(chess.board[0][1], 2)


func test_white_pawn_can_promote_to_bishop():
	_clear_board()
	chess.board[1][2] = 1
	chess.white = true
	chess.selected_piece = Vector2(1, 2)
	chess.moves = [Vector2(0, 2)]
	chess.set_move(0, 2)
	var bishop_button = game.get_node("CanvasLayer/white_pieces/3")
	chess._on_button_pressed(bishop_button)
	assert_eq(chess.board[0][2], 3)


func test_white_pawn_can_promote_to_rook():
	_clear_board()
	chess.board[1][3] = 1
	chess.white = true
	chess.selected_piece = Vector2(1, 3)
	chess.moves = [Vector2(0, 3)]
	chess.set_move(0, 3)
	var rook_button = game.get_node("CanvasLayer/white_pieces/4")
	chess._on_button_pressed(rook_button)
	assert_eq(chess.board[0][3], 4)


func test_black_pawn_can_promote_to_bishop():
	_clear_board()
	chess.board[6][2] = -1
	chess.white = false
	chess.selected_piece = Vector2(6, 2)
	chess.moves = [Vector2(7, 2)]
	chess.set_move(7, 2)
	var bishop_button = game.get_node("CanvasLayer/black_pieces/3")
	chess._on_button_pressed(bishop_button)
	assert_eq(chess.board[7][2], -3)


func test_black_pawn_can_promote_to_rook():
	_clear_board()
	chess.board[6][3] = -1
	chess.white = false
	chess.selected_piece = Vector2(6, 3)
	chess.moves = [Vector2(7, 3)]
	chess.set_move(7, 3)
	var rook_button = game.get_node("CanvasLayer/black_pieces/4")
	chess._on_button_pressed(rook_button)
	assert_eq(chess.board[7][3], -4)


func test_black_pawn_can_promote_to_queen():
	_clear_board()
	chess.board[6][4] = -1
	chess.white = false
	chess.selected_piece = Vector2(6, 4)
	chess.moves = [Vector2(7, 4)]
	chess.set_move(7, 4)
	var queen_button = game.get_node("CanvasLayer/black_pieces/5")
	chess._on_button_pressed(queen_button)
	assert_eq(chess.board[7][4], -5)