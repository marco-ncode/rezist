## A* pathfinding over a TacticalGrid, elevation- and mover-type-aware.
## Stateless: every call is independent, safe to invoke for many squads in
## the same simulation tick (ARCHITECTURE.md §2 invariant).
class_name AStarPathfinder
extends RefCounted

## Returns an array of Vector2i tiles from start to goal (inclusive of both),
## or an empty array if no path exists. Consecutive tiles are always
## orthogonally adjacent (TacticalGrid.neighbors contract).
static func find_path(grid: TacticalGrid, start: Vector2i, goal: Vector2i, mover_type: String = "ground") -> Array:
	if start == goal:
		return [start]
	if not grid.is_walkable(goal, mover_type):
		return []

	var open_set: Dictionary = {start: true}
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start: 0.0}
	var f_score: Dictionary = {start: _heuristic(start, goal)}

	while not open_set.is_empty():
		var current: Vector2i = _lowest_f_score(open_set, f_score)
		if current == goal:
			return _reconstruct_path(came_from, current)

		open_set.erase(current)

		for neighbor in grid.neighbors(current):
			var cost: float = grid.movement_cost(current, neighbor, mover_type)
			if cost == TacticalGrid.IMPASSABLE:
				continue
			var tentative_g: float = g_score.get(current, INF) + cost
			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _heuristic(neighbor, goal)
				open_set[neighbor] = true

	return []

## Used when the exact goal tile is occupied (formation spreading): finds the
## reachable tile nearest to `goal`, breaking ties by distance to `start`.
static func find_nearest_reachable(grid: TacticalGrid, start: Vector2i, goal: Vector2i, mover_type: String = "ground") -> Vector2i:
	if grid.is_walkable(goal, mover_type):
		var direct := find_path(grid, start, goal, mover_type)
		if not direct.is_empty():
			return goal

	var candidates: Array = []
	for pos in grid.all_positions():
		if grid.is_walkable(pos, mover_type):
			candidates.append(pos)

	candidates.sort_custom(func(a, b):
		var da: float = _heuristic(a, goal) + _heuristic(a, start) * 0.01
		var db: float = _heuristic(b, goal) + _heuristic(b, start) * 0.01
		return da < db
	)

	for candidate in candidates:
		if not find_path(grid, start, candidate, mover_type).is_empty():
			return candidate

	return start

static func _heuristic(a: Vector2i, b: Vector2i) -> float:
	return absf(a.x - b.x) + absf(a.y - b.y)

static func _lowest_f_score(open_set: Dictionary, f_score: Dictionary) -> Vector2i:
	var best: Vector2i = open_set.keys()[0]
	var best_score: float = f_score.get(best, INF)
	for pos in open_set.keys():
		var score: float = f_score.get(pos, INF)
		if score < best_score:
			best_score = score
			best = pos
	return best

static func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array:
	var path: Array = [current]
	var node := current
	while came_from.has(node):
		node = came_from[node]
		path.push_front(node)
	return path
