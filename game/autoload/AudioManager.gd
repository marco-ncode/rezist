## Autoload singleton. Maps gameplay event ids to sound cues using the data
## table DataLoader loaded from data/audio_events.json — never a hardcoded
## match statement (ARCHITECTURE.md §13 invariant). v1 has no real audio
## assets yet (docs/ASSET_PIPELINE.md placeholder policy); play_event()
## still fires so the event pipeline is provably wired end-to-end (see
## docs/BACKLOG.md RZ-072) even before real SFX land.
extends Node

signal event_played(event_id: String, at_position: Vector2)

var _music_intensity: float = 0.0
var _buses: Dictionary = {} # bus name -> AudioStreamPlayer pool (created lazily)

func play_event(event_id: String, at_position: Vector2 = Vector2.ZERO) -> void:
	if not DataLoader.audio_events.has(event_id):
		push_warning("AudioManager.play_event: unknown event_id '%s' (not in data/audio_events.json)" % event_id)
		return
	# Placeholder v1: no audio streams are shipped yet, so this only emits a
	# signal for UI/FX layers and test hooks to observe. Real playback wires
	# in here once assets land (RZ-120).
	event_played.emit(event_id, at_position)

func set_music_intensity(level: float) -> void:
	_music_intensity = clampf(level, 0.0, 1.0)

func get_music_intensity() -> float:
	return _music_intensity
