class_name AstraPlayerSetup
extends Control

# 탐사요원 등록: the explorer's name and look, once per new campaign. Light on
# purpose — the crew still call you 탐사요원, and the conversation screens
# stay first-person. The look is used for the walking scenes and small icons;
# the name for labels, records and a few key moments.
# One confirm starts the campaign; "기본값으로 시작" skips the choices.

signal confirmed(profile: Dictionary)
signal cancelled

const PRESETS := ["p1", "p2", "p3", "p4", "p5", "p6"]

var _name_edit: LineEdit
var _selected: String = "p1"
var _cards: Dictionary = {}
var _preview: AstraPixelActor
var _preview_holder: Control
var _preview_time: float = 0.0

func setup(initial: Dictionary = {}) -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    _selected = str(initial.get("preset", "p1"))
    var art := AstraUI.thumb(AstraArt.background("medical"), Vector2.ZERO)
    art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(art)
    add_child(AstraArt.shade(true))
    var panel := AstraUI.reading_panel(AstraUI.CYAN, 0.95)
    panel.anchor_left = 0.5
    panel.anchor_right = 0.5
    panel.anchor_top = 0.5
    panel.anchor_bottom = 0.5
    panel.offset_left = -560
    panel.offset_right = 560
    panel.offset_top = -330
    panel.offset_bottom = 330
    add_child(panel)
    var box := AstraUI.vbox(12)
    panel.add_child(box)
    box.add_child(AstraUI.label("탐사요원 등록", AstraUI.T_TITLE, AstraUI.CYAN))
    box.add_child(AstraUI.prose("재구성을 넘어 기억하는 사람은 당신뿐입니다. 이름과 모습을 정하세요. 승무원들은 당신을 ‘탐사요원’이라고 부릅니다.", AstraUI.T_UI, AstraUI.MUTED))

    var row := AstraUI.hbox(24)
    row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(row)
    var left := AstraUI.vbox(10)
    left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(left)
    left.add_child(AstraUI.label("이름", AstraUI.T_HEAD, AstraUI.TEXT))
    _name_edit = LineEdit.new()
    _name_edit.max_length = 10
    _name_edit.placeholder_text = "탐사요원"
    _name_edit.text = str(initial.get("name", ""))
    _name_edit.custom_minimum_size = Vector2(320, 48)
    _name_edit.add_theme_font_size_override("font_size", AstraUI.font_size(AstraUI.T_BODY))
    _name_edit.text_submitted.connect(func(_t: String): _confirm())
    left.add_child(_name_edit)
    left.add_child(AstraUI.label("비워 두면 ‘탐사요원’으로 표시됩니다. 최대 10자.", AstraUI.T_META, AstraUI.DIM))
    left.add_child(AstraUI.label("모습", AstraUI.T_HEAD, AstraUI.TEXT))
    var grid := GridContainer.new()
    grid.columns = 3
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 10)
    left.add_child(grid)
    for preset in PRESETS:
        var card := _preset_card(preset)
        grid.add_child(card)
        _cards[preset] = card
    left.add_child(AstraUI.label("임시 모습입니다. 이후 버전에서 교체될 수 있습니다.", AstraUI.T_META, AstraUI.DIM))

    var right := AstraUI.vbox(8)
    right.custom_minimum_size = Vector2(300, 0)
    row.add_child(right)
    right.add_child(AstraUI.label("미리 보기", AstraUI.T_META, AstraUI.MUTED))
    _preview_holder = Control.new()
    _preview_holder.custom_minimum_size = Vector2(300, 330)
    _preview_holder.clip_contents = true
    right.add_child(_preview_holder)
    var floor := ColorRect.new()
    floor.color = Color("15202f")
    floor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _preview_holder.add_child(floor)

    var buttons := AstraUI.hbox(10)
    box.add_child(buttons)
    var back := AstraUI.button("뒤로", AstraUI.MUTED, AstraUI.T_UI, 46)
    back.pressed.connect(func(): cancelled.emit())
    buttons.add_child(back)
    buttons.add_child(AstraUI.spacer())
    var quick := AstraUI.button("기본값으로 시작", AstraUI.MUTED, AstraUI.T_UI, 46)
    quick.pressed.connect(func():
        confirmed.emit({"name": "", "preset": "p1"})
    )
    buttons.add_child(quick)
    var go := AstraUI.primary_button("이대로 시작   →", AstraUI.GREEN)
    go.custom_minimum_size = Vector2(240, 50)
    go.pressed.connect(_confirm)
    buttons.add_child(go)
    _select(_selected)
    _name_edit.grab_focus.call_deferred()

func _preset_card(preset: String) -> Button:
    var card := Button.new()
    card.custom_minimum_size = Vector2(128, 120)
    card.toggle_mode = true
    card.focus_mode = Control.FOCUS_ALL
    card.pressed.connect(func(): _select(preset))
    var face := TextureRect.new()
    face.texture = AstraUI.texture("res://assets/pixel080/player/%s_face.png" % preset)
    face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    face.offset_left = 8
    face.offset_top = 8
    face.offset_right = -8
    face.offset_bottom = -8
    face.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(face)
    return card

func _select(preset: String) -> void:
    if preset not in PRESETS:
        preset = "p1"
    _selected = preset
    for key in _cards:
        var card: Button = _cards[key]
        card.button_pressed = key == preset
        card.add_theme_stylebox_override("normal", AstraUI.style(Color(AstraUI.GOLD, 0.16) if key == preset else AstraUI.PANEL, AstraUI.GOLD if key == preset else AstraUI.BORDER, 10, 2 if key == preset else 1, 6))
        card.add_theme_stylebox_override("pressed", AstraUI.style(Color(AstraUI.GOLD, 0.16), AstraUI.GOLD, 10, 2, 6))
        card.add_theme_stylebox_override("hover", AstraUI.style(Color(AstraUI.CYAN, 0.12), AstraUI.CYAN, 10, 2, 6))
    if _preview != null and is_instance_valid(_preview):
        _preview.queue_free()
    _preview = AstraPixelActor.new()
    _preview.setup(AstraPixelActor.player_sheet(preset), "player", "", AstraUI.GOLD)
    _preview.scale = Vector2(2.0, 2.0)
    _preview.position = Vector2(150, 300)
    _preview_holder.add_child(_preview)
    _preview_time = 0.0
    # the chosen look greets you
    _preview.emote("♪", 1.4, true)
    _preview.gesture("hop", true)

func _process(delta: float) -> void:
    if _preview == null or not is_instance_valid(_preview):
        return
    # Stand for a moment (breathing, a nod), then walk through the four
    # directions so the whole look is shown.
    _preview_time += delta
    var cycle := fmod(_preview_time, 8.0)
    if cycle < 1.6:
        _preview.set_moving(false)
        if _preview.facing != "down":
            _preview.face("down")
        if _preview_time > 2.0 and cycle >= 0.5 and cycle - delta < 0.5:
            _preview.gesture("nod")
    else:
        _preview.set_moving(true)
        var dir: String = AstraPixelActor.DIRECTIONS[int((cycle - 1.6) / 1.6) % 4]
        if dir != _preview.facing:
            _preview.face(dir)

func _confirm() -> void:
    confirmed.emit({"name": _name_edit.text.strip_edges().left(10), "preset": _selected})
