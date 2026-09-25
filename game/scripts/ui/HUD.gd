## Minimal mission HUD (UX_UI.md §4): squad selector bar (dot-per-unit, never
## a number — ADR-0005), ability button, wave indicator. Built entirely in
## code for v1 (no hand-authored .tscn UI tree) to keep the vertical slice
## robust; a full UX pass (RZ-124) can replace this with themed scenes
## without touching MissionController's contract with it.
class_name HUD
extends CanvasLayer

signal squad_button_pressed(index: int)
signal ability_button_pressed()

var _squad_buttons: Array = []
var _wave_label: Label
var _ability_button: Button
var _resolution_panel: PanelContainer
var _toast_label: Label
var _toast_tween: Tween

func build(squad_count: int) -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_wave_label = Label.new()
	_wave_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_wave_label.position = Vector2(-100, 16)
	_wave_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(_wave_label)

	var bottom_bar := HBoxContainer.new()
	bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bar.position = Vector2(16, -64)
	bottom_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(bottom_bar)

	for i in squad_count:
		var button := Button.new()
		button.text = "Sq.%d" % (i + 1)
		button.custom_minimum_size = Vector2(96, 48)
		button.pressed.connect(func(): squad_button_pressed.emit(i))
		bottom_bar.add_child(button)
		_squad_buttons.append(button)

	_ability_button = Button.new()
	_ability_button.text = "Ability"
	_ability_button.custom_minimum_size = Vector2(96, 48)
	_ability_button.disabled = true
	_ability_button.pressed.connect(func(): ability_button_pressed.emit())
	bottom_bar.add_child(_ability_button)

func update_squad_button(index: int, unit_count: int, is_selected: bool, is_wiped: bool, commander_name: String = "") -> void:
	if index < 0 or index >= _squad_buttons.size():
		return
	var label := commander_name if commander_name != "" else "Sq.%d" % (index + 1)
	var button: Button = _squad_buttons[index]
	if is_wiped:
		button.text = "%s ✕" % label
		button.disabled = true
		return
	button.text = "%s %s" % [label, "●".repeat(unit_count)]
	button.button_pressed = is_selected

func update_wave_label(text: String) -> void:
	_wave_label.text = text

func update_ability_button(enabled: bool, label: String = "Ability") -> void:
	_ability_button.disabled = not enabled
	_ability_button.text = label

## RZ-088: a transient, attention-grabbing line for a permadeath "moment" —
## a commander exposed or fallen mid-mission — distinct from the squad
## button's persistent "✕" state (update_squad_button), which reflects the
## outcome afterward but doesn't call attention to the instant it happened.
## Fades out on its own; a second call while one is still showing replaces
## it immediately rather than stacking.
func show_toast(text: String, duration: float = 2.5) -> void:
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	if _toast_label != null and is_instance_valid(_toast_label):
		_toast_label.queue_free()

	_toast_label = Label.new()
	_toast_label.text = text
	_toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast_label.position = Vector2(-160, 48)
	_toast_label.custom_minimum_size = Vector2(320, 0)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.add_theme_color_override("font_color", Color.WHITE)
	_toast_label.add_theme_font_size_override("font_size", 20)
	add_child(_toast_label)

	_toast_tween = create_tween()
	_toast_tween.tween_interval(duration)
	_toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.6)
	_toast_tween.tween_callback(_toast_label.queue_free)

func show_resolution(won: bool, safehouses_saved: int, total_safehouses: int, gold_earned: int) -> void:
	if _resolution_panel != null:
		_resolution_panel.queue_free()

	_resolution_panel = PanelContainer.new()
	_resolution_panel.set_anchors_preset(Control.PRESET_CENTER)
	add_child(_resolution_panel)

	var vbox := VBoxContainer.new()
	_resolution_panel.add_child(vbox)

	var headline := Label.new()
	headline.text = "MISSION COMPLETE" if won else "MISSION LOST"
	vbox.add_child(headline)

	var detail := Label.new()
	detail.text = "Safehouses saved: %d/%d\nGold earned: +%d" % [safehouses_saved, total_safehouses, gold_earned]
	vbox.add_child(detail)
