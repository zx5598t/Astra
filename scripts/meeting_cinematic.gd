class_name AstraMeetingCinematic
extends CanvasLayer

var _root: Control
var _panel: PanelContainer
var _speaker: Label
var _tag: Label
var _line: Label
var _progress: Label
var _timer: Timer
var _events: Array[Dictionary] = []
var _npcs: Dictionary = {}
var _index: int = 0

func _ready() -> void:
    layer = 75
    _root = Control.new()
    _root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_root)

    _panel = PanelContainer.new()
    _panel.anchor_left = 0.5
    _panel.anchor_right = 0.5
    _panel.offset_left = -430.0
    _panel.offset_right = 430.0
    _panel.offset_top = 28.0
    _panel.offset_bottom = 150.0
    _panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _panel.visible = false
    _root.add_child(_panel)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 3)
    _panel.add_child(box)

    var header := HBoxContainer.new()
    box.add_child(header)
    _tag = Label.new()
    _tag.add_theme_font_size_override("font_size", 12)
    _tag.add_theme_color_override("font_color", Color("8ea5c5"))
    _tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(_tag)
    _progress = Label.new()
    _progress.add_theme_font_size_override("font_size", 11)
    _progress.add_theme_color_override("font_color", Color("8ea5c5"))
    header.add_child(_progress)

    _speaker = Label.new()
    _speaker.add_theme_font_size_override("font_size", 22)
    box.add_child(_speaker)

    _line = Label.new()
    _line.add_theme_font_size_override("font_size", 15)
    _line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _line.add_theme_color_override("font_color", Color("eef5ff"))
    box.add_child(_line)

    _timer = Timer.new()
    _timer.wait_time = 1.35
    _timer.one_shot = false
    _timer.timeout.connect(_advance)
    add_child(_timer)

func play(events: Array, npcs: Dictionary, max_events: int = 4) -> void:
    _events.clear()
    _npcs = npcs
    var count := mini(max_events, events.size())
    for i in range(count):
        var event = events[i]
        if event is Dictionary:
            _events.append((event as Dictionary).duplicate(true))
    if _events.is_empty():
        return
    _index = 0
    _panel.visible = true
    _show_current()
    _timer.start()

func stop() -> void:
    if _timer != null:
        _timer.stop()
    if _panel != null:
        _panel.visible = false

func _advance() -> void:
    _index += 1
    if _index >= _events.size():
        _timer.stop()
        _fade_out()
        return
    _show_current()

func _show_current() -> void:
    if _index < 0 or _index >= _events.size():
        return
    var event: Dictionary = _events[_index]
    var speaker_id := str(event.get("speaker", ""))
    var speaker_name := speaker_id
    var accent := Color("55d6ff")
    if speaker_id in _npcs:
        var npc = _npcs[speaker_id]
        speaker_name = str(npc.display_name)
        accent = npc.accent

    var kind := str(event.get("kind", "claim"))
    var tag := "PUBLIC CLAIM"
    if kind == "challenge":
        tag = "CHALLENGE"
    elif kind == "defend":
        tag = "INTERJECTION"

    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.025, 0.055, 0.10, 0.96)
    style.border_color = Color(accent.r, accent.g, accent.b, 0.78)
    style.set_border_width_all(1)
    style.set_corner_radius_all(9)
    style.content_margin_left = 18
    style.content_margin_right = 18
    style.content_margin_top = 12
    style.content_margin_bottom = 12
    _panel.add_theme_stylebox_override("panel", style)

    _tag.text = "MEETING · " + tag
    _speaker.text = speaker_name
    _speaker.add_theme_color_override("font_color", accent)
    _line.text = str(event.get("text", ""))
    _progress.text = "%d / %d" % [_index + 1, _events.size()]

    _panel.modulate.a = 0.0
    _panel.position.x = 18.0
    var tween := _panel.create_tween()
    tween.set_parallel(true)
    tween.tween_property(_panel, "modulate:a", 1.0, 0.10)
    tween.tween_property(_panel, "position:x", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _fade_out() -> void:
    if _panel == null:
        return
    var tween := _panel.create_tween()
    tween.tween_property(_panel, "modulate:a", 0.0, 0.22)
    tween.tween_callback(func(): _panel.visible = false)
