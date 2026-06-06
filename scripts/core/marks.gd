class_name Marks
extends RefCounted
## Cell values for the board. Integer values match refrence/board.js (1 = X, 2 = O)
## so generated reference data and our port line up exactly.

enum { EMPTY = 0, X = 1, O = 2 }

## Returns the opposing mark. EMPTY maps to EMPTY.
static func other(mark: int) -> int:
	match mark:
		X: return O
		O: return X
		_: return EMPTY

## Single-character glyph, handy for debug printing.
static func glyph(mark: int) -> String:
	match mark:
		X: return "X"
		O: return "O"
		_: return "."
