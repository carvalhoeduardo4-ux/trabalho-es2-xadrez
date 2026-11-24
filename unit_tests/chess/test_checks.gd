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
	chess.game_over = false
	chess.white = true


func test_white_pawn_attacks_diagonal_squares():
	chess.board[5][3] = 1
	assert_true(chess.is_square_attacked(Vector2(4, 2), true))
	assert_true(chess.is_square_attacked(Vector2(4, 4), true))
	assert_false(chess.is_square_attacked(Vector2(4, 3), true))


func test_black_pawn_attacks_diagonal_squares():
	chess.board[3][3] = -1
	assert_true(chess.is_square_attacked(Vector2(4, 2), false))
	assert_true(chess.is_square_attacked(Vector2(4, 4), false))
	assert_false(chess.is_square_attacked(Vector2(4, 3), false))


func test_knight_attack_is_detected_in_l_shape():
	chess.board[2][2] = 2
	assert_true(chess.is_square_attacked(Vector2(4, 3), true))
	assert_false(chess.is_square_attacked(Vector2(4, 2), true))


func test_rook_attacks_along_rank_and_stops_at_piece():
	chess.board[4][4] = 4
	assert_true(chess.is_square_attacked(Vector2(4, 7), true))
	chess.board[4][6] = 1
	assert_false(chess.is_square_attacked(Vector2(4, 7), true))


func test_bishop_attacks_diagonally():
	chess.board[4][4] = 3
	assert_true(chess.is_square_attacked(Vector2(6, 6), true))
	assert_false(chess.is_square_attacked(Vector2(6, 5), true))


func test_queen_attacks_orthogonally_and_diagonally():
	chess.board[4][4] = 5
	assert_true(chess.is_square_attacked(Vector2(4, 7), true))
	assert_true(chess.is_square_attacked(Vector2(7, 7), true))


func test_king_attacks_adjacent_square():
	chess.board[4][4] = 6
	assert_true(chess.is_square_attacked(Vector2(5, 5), true))
	assert_false(chess.is_square_attacked(Vector2(6, 6), true))


func test_is_in_check_detects_attacked_king():
	chess.board[7][4] = 6
	chess.board[7][0] = -4
	assert_true(chess.is_in_check(true))


func test_is_in_check_returns_false_without_attack():
	chess.board[7][4] = 6
	chess.board[0][0] = -4
	assert_false(chess.is_in_check(true))


func test_pinned_piece_movement_leaves_king_in_check():
	chess.board[7][4] = 6
	chess.board[7][3] = 4
	chess.board[7][0] = -4
	chess.selected_piece = Vector2(7, 3)
	assert_true(chess.leaves_king_in_check(Vector2(6, 3)))
	assert_false(chess.leaves_king_in_check(Vector2(7, 2)))
