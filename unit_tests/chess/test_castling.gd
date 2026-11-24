extends GutTest

const MAIN_SCENE = preload("res://Scenes/main.tscn")

var game
var chess


func before_each():
	game = MAIN_SCENE.instantiate()
	add_child(game)
	chess = game.get_node("Camera2D/board")
	chess.vs_ai = false
	_clear_board()


func after_each():
	game.free()


func _clear_board():
	chess.board.clear()
	for _row in range(8):
		chess.board.append([0, 0, 0, 0, 0, 0, 0, 0])
	chess.w_king_moved = false
	chess.b_king_moved = false
	chess.w_rook_left_moved = false
	chess.w_rook_right_moved = false
	chess.b_rook_left_moved = false
	chess.b_rook_right_moved = false
	chess.white = true


func test_white_king_kingside_castling_is_available():
	chess.board[7][4] = 6
	chess.board[7][7] = 4
	chess.selected_piece = Vector2(7, 4)
	var moves = chess.get_king_moves()
	assert_true(moves.has(Vector2(7, 6)))


func test_white_king_queenside_castling_is_available():
	chess.board[7][4] = 6
	chess.board[7][0] = 4
	chess.selected_piece = Vector2(7, 4)
	var moves = chess.get_king_moves()
	assert_true(moves.has(Vector2(7, 2)))


func test_black_king_kingside_castling_is_available():
	chess.white = false
	chess.board[0][4] = -6
	chess.board[0][7] = -4
	chess.selected_piece = Vector2(0, 4)
	var moves = chess.get_king_moves()
	assert_true(moves.has(Vector2(0, 6)))


func test_black_king_queenside_castling_is_available():
	chess.white = false
	chess.board[0][4] = -6
	chess.board[0][0] = -4
	chess.selected_piece = Vector2(0, 4)
	var moves = chess.get_king_moves()
	assert_true(moves.has(Vector2(0, 2)))


func test_castling_is_blocked_by_piece_in_passage():
	chess.board[7][4] = 6
	chess.board[7][7] = 4
	chess.board[7][5] = 2
	chess.selected_piece = Vector2(7, 4)
	assert_false(chess.get_king_moves().has(Vector2(7, 6)))


func test_castling_is_blocked_when_king_has_moved():
	chess.w_king_moved = true
	chess.board[7][4] = 6
	chess.board[7][7] = 4
	chess.selected_piece = Vector2(7, 4)
	assert_false(chess.get_king_moves().has(Vector2(7, 6)))


func test_castling_moves_white_rook_to_kingside_passage():
	chess.board[7][6] = 6
	chess.board[7][7] = 4
	chess.roque(7, 6)
	assert_eq(chess.board[7][5], 4)
	assert_eq(chess.board[7][7], 0)


func test_castling_moves_white_rook_to_queenside_passage():
	chess.board[7][2] = 6
	chess.board[7][0] = 4
	chess.roque(7, 2)
	assert_eq(chess.board[7][3], 4)
	assert_eq(chess.board[7][0], 0)
