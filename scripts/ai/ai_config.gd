class_name AIConfig
extends RefCounted
## Tunable AI parameters with Easy / Medium / Hard presets.
## `scale` makes the exact run-score dominate the heuristic potential so the AI never
## trades a real point for a speculative one.

enum Difficulty { EASY, MEDIUM, HARD }

var difficulty: int = Difficulty.HARD
var max_depth: int = 8           ## iterative-deepening cap (also bounded by empties)
var time_budget_ms: int = 1800   ## per-move wall-clock budget
var candidate_radius: int = 2    ## consider empties within this Chebyshev distance of a mark
var max_candidates: int = 16     ## branching cap per node (beam over ordered moves)
var blunder_chance: float = 0.0  ## Easy: chance to play a random legal candidate
var rng_seed: int = 0            ## 0 => randomize
var scale: int = 1000            ## weight on exact run-score (dominates potential)
var w_live2: int = 50            ## potential: open-ended pair (could become a 3-run)
var w_ext: int = 15              ## potential: extendable run of >= 3 (could grow)


static func easy(seed: int = 0) -> AIConfig:
	var c := AIConfig.new()
	c.difficulty = Difficulty.EASY
	c.max_depth = 2
	c.time_budget_ms = 400
	c.candidate_radius = 1
	c.max_candidates = 10
	c.blunder_chance = 0.35
	c.rng_seed = seed
	return c


static func medium(seed: int = 0) -> AIConfig:
	var c := AIConfig.new()
	c.difficulty = Difficulty.MEDIUM
	c.max_depth = 4
	c.time_budget_ms = 900
	c.candidate_radius = 1
	c.max_candidates = 12
	c.blunder_chance = 0.0
	c.rng_seed = seed
	return c


static func hard(seed: int = 0) -> AIConfig:
	var c := AIConfig.new()
	c.difficulty = Difficulty.HARD
	c.max_depth = 8
	c.time_budget_ms = 1800
	c.candidate_radius = 2
	c.max_candidates = 16
	c.blunder_chance = 0.0
	c.rng_seed = seed
	return c
