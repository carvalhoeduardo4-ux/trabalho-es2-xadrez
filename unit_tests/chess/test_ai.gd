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
	chess.white = true
	chess.ai_search_depth = 1


func test_evaluate_board_is_zero_for_empty_board():
	assert_eq(chess.evaluate_board(), 0.0)


func test_evaluate_board_gives_white_positive_score():
	chess.board[7][4] = 6
	chess.board[7][3] = 5
	var score = chess.evaluate_board()
	assert_true(score > 0)


func test_evaluate_board_gives_black_negative_score():
	chess.board[0][4] = -6
	chess.board[0][3] = -5
	assert_true(chess.evaluate_board() < 0)


func test_ai_promotion_always_chooses_queen():
	assert_eq(chess.choose_ai_promotion(), 5)


func test_get_all_legal_moves_finds_two_white_pawn_moves():
	chess.board[6][4] = 1
	var moves = chess.get_all_legal_moves_for_current_turn()
	assert_true(moves.has({"from": Vector2(6, 4), "to": Vector2(5, 4)}))
	assert_true(moves.has({"from": Vector2(6, 4), "to": Vector2(4, 4)}))
	assert_eq(moves.size(), 2)


func test_make_and_undo_simulated_move_restore_board():
	chess.board[6][4] = 1
	var backup = chess.make_simulated_move(Vector2(6, 4), Vector2(4, 4))
	assert_eq(chess.board[6][4], 0)
	assert_eq(chess.board[4][4], 1)
	assert_false(chess.white)
	chess.undo_simulated_move(backup)
	assert_eq(chess.board[6][4], 1)
	assert_eq(chess.board[4][4], 0)
	assert_true(chess.white)


func test_make_simulated_move_promotes_white_pawn_to_queen():
	chess.board[1][4] = 1
	var backup = chess.make_simulated_move(Vector2(1, 4), Vector2(0, 4))
	assert_eq(chess.board[0][4], 5)
	chess.undo_simulated_move(backup)
	assert_eq(chess.board[1][4], 1)


func test_make_simulated_move_promotes_black_pawn_to_queen():
	chess.white = false
	chess.board[6][4] = -1
	var backup = chess.make_simulated_move(Vector2(6, 4), Vector2(7, 4))
	assert_eq(chess.board[7][4], -5)
	chess.undo_simulated_move(backup)
	assert_eq(chess.board[6][4], -1)
