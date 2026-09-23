## Thin scripts/ adapter (ARCHITECTURE.md layering): renders a core/
## TacticalGrid + its safehouses/entry points as 2.5D primitive placeholder
## visuals (ADR-0008, docs/ASSET_PIPELINE.md v1 policy). Pure presentation —
## never mutates the grid it's given.
class_name GridRenderer
extends Node2D

const TILE_SIZE := 32
const ELEVATION_OFFSET := 8

const TILE_COLORS := {
	"open": Color("8A8D91"),
	"road": Color("3C3F42"),
	"rubble": Color("6E645A"),
	"water": Color("4C6B6B"),
	"wall": Color("2A2C2E"),
	"stairs": Color("A9ADB2"),
	"door": Color("5C7A99"),
	"roof": Color("6F7276"),
	"sewer": Color("353A3D"),
}

const SAFEHOUSE_COLORS := {
	0: Color("D9D2C4"), # INTACT
	1: Color("8C8478"), # DAMAGED
	2: Color("E2712B"), # BURNING
	3: Color("231F1D"), # COLLAPSED
}

var grid: TacticalGrid
var safehouses: Array = []
var _safehouse_nodes: Dictionary = {}

func render(p_grid: TacticalGrid, p_safehouses: Array, entry_points: Array) -> void:
	grid = p_grid
	safehouses = p_safehouses
	for child in get_children():
		child.queue_free()
	_safehouse_nodes.clear()

	for pos in grid.all_positions():
		var tile := grid.get_tile(pos)
		var rect := ColorRect.new()
		rect.size = Vector2(TILE_SIZE - 1, TILE_SIZE - 1)
		rect.position = tile_to_screen(pos, tile.get("elevation", 0))
		rect.color = TILE_COLORS.get(tile.get("type", "open"), TILE_COLORS["open"])
		add_child(rect)

	for safehouse in safehouses:
		var marker := ColorRect.new()
		marker.size = Vector2(TILE_SIZE * 0.6, TILE_SIZE * 0.6)
		marker.position = tile_to_screen(safehouse.position, grid.elevation_at(safehouse.position)) + Vector2(TILE_SIZE * 0.2, TILE_SIZE * 0.2)
		marker.color = SAFEHOUSE_COLORS[safehouse.state]
		add_child(marker)
		_safehouse_nodes[safehouse.id] = marker

	for entry_point in entry_points:
		var marker := ColorRect.new()
		marker.size = Vector2(TILE_SIZE * 0.4, TILE_SIZE * 0.4)
		marker.position = tile_to_screen(entry_point.position, grid.elevation_at(entry_point.position)) + Vector2(TILE_SIZE * 0.3, TILE_SIZE * 0.3)
		marker.color = Color("C23B3B")
		add_child(marker)

func refresh_safehouses() -> void:
	for safehouse in safehouses:
		if _safehouse_nodes.has(safehouse.id):
			_safehouse_nodes[safehouse.id].color = SAFEHOUSE_COLORS[safehouse.state]

static func tile_to_screen(pos: Vector2i, elevation: int) -> Vector2:
	return Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE - elevation * ELEVATION_OFFSET)
