## Serializes/deserializes a RunState to user://saves/<slot>.json
## (ARCHITECTURE.md §10). The only class allowed to touch user:// — nothing
## else in the codebase should call FileAccess/DirAccess against the save
## directory directly.
##
## Stateless utility (static methods only), same pattern as
## AStarPathfinder/MapGenerator. FileAccess/DirAccess are plain RefCounted
## utility classes, not Node/SceneTree — using them here doesn't violate
## ADR-0002's core/ purity rule.
class_name SaveManager
extends RefCounted

const SAVE_DIR := "user://saves"

## v1 has no save-slot picker UI (single slot) — RZ-090's mission-end
## autosave and MainMenuController's Continue button both save/load this
## same slot, so the constant lives here rather than being duplicated (or
## owned by one and reached into by the other, which would wire `scripts/ui/`
## and `scripts/mission/` together for no reason).
const DEFAULT_SLOT := 0

static func _slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]

static func _ensure_save_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir != null and not dir.dir_exists("saves"):
		dir.make_dir("saves")

static func save(run_state: RunState, slot: int) -> void:
	_ensure_save_dir()
	var file := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	assert(file != null, "SaveManager.save: could not open %s for writing" % _slot_path(slot))
	file.store_string(JSON.stringify(run_state.to_save_dict(), "\t"))
	file.close()

## Returns null if no save exists at that slot.
static func load(slot: int) -> RunState:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	assert(file != null, "SaveManager.load: could not open %s for reading" % path)
	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	assert(parsed is Dictionary, "SaveManager.load: %s did not parse to a JSON object" % path)
	return RunState.from_save_dict(parsed)

static func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))

static func delete_save(slot: int) -> void:
	var path := _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
