extends Control

# Night, only when there is a real choice to make: GUARDIAN with an Aegis
# charge left. The corridor goes dark; the explorer picks one door to shield
# (their own included) or keeps the charge. The result is told the next
# morning by the people who find it (§34, §35). Part I nights never open this.

var screen
var _grid: GridContainer
var _title: Label
var _charges: Label
var _done: bool = false

func setup(game_screen) -> void:
    screen = game_screen
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var bg := AstraUI.thumb(AstraArt.background("breach"), Vector2.ZERO)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.modulate = Color(0.28, 0.3, 0.45)
    add_child(bg)
    var dim := ColorRect.new()
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dim.color = Color(0.0, 0.0, 0.04, 0.55)
    dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(dim)
    var center := AstraUI.vbox(12)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.offset_left = 40
    center.offset_right = -40
    center.offset_top = 24
    center.offset_bottom = -20
    add_child(center)
    _title = AstraUI.label("밤. 복도 조명이 절반으로 줄어든다.", AstraUI.T_TITLE, AstraUI.NIGHT)
    center.add_child(_title)
    center.add_child(AstraUI.prose("누군가는 오늘 밤 움직인다. Aegis 차폐막으로 한 사람의 선실 문을 지킬 수 있다. 막아 내면, 누가 노려졌는지만 알게 된다.", AstraUI.T_BODY, AstraUI.TEXT))
    _charges = AstraUI.label("", AstraUI.T_UI, AstraUI.GOLD)
    center.add_child(_charges)
    _grid = GridContainer.new()
    _grid.columns = 5
    _grid.add_theme_constant_override("h_separation", 10)
    _grid.add_theme_constant_override("v_separation", 10)
    var scroll := AstraUI.scroll(_grid)
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    center.add_child(scroll)
    var keep := AstraUI.button("오늘 밤은 차폐막을 아낀다", AstraUI.MUTED, AstraUI.T_UI, 44)
    keep.pressed.connect(_choose.bind("skip", ""))
    center.add_child(keep)
    screen.fx.play("night")
    refresh()

func refresh() -> void:
    var s: AstraGameSession = screen.session
    if s.phase != "NIGHT" or _done:
        return
    _charges.text = "Aegis 남은 횟수 %d · 같은 문을 이틀 연속 지킬 수는 없다" % s.guardian_charges()
    AstraUI.clear(_grid)
    for id in s.night_options().get("protect", []):
        _grid.add_child(_door(str(id)))

func _door(id: String) -> Button:
    var s: AstraGameSession = screen.session
    var card := Button.new()
    card.custom_minimum_size = Vector2(150, 200)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    var accent: Color = AstraUI.GOLD if id == "player" else AstraCrewCatalog.accent(id)
    card.add_theme_stylebox_override("normal", AstraUI.style(Color(0.02, 0.03, 0.08, 0.92), Color(accent, 0.4), 12, 1, 6))
    card.add_theme_stylebox_override("hover", AstraUI.style(Color(accent, 0.16), accent, 12, 2, 6))
    card.add_theme_stylebox_override("pressed", AstraUI.style(Color(accent, 0.3), accent, 12, 2, 6))
    var col := AstraUI.vbox(2)
    col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    col.offset_left = 6
    col.offset_right = -6
    col.offset_top = 6
    col.offset_bottom = -6
    col.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(col)
    if id == "player":
        var me := AstraUI.player_face(s, Vector2(130, 130))
        me.size_flags_vertical = Control.SIZE_EXPAND_FILL
        col.add_child(me)
        var cap := AstraUI.label("내 선실 · %s" % AstraUI.player_name(s), AstraUI.T_UI, AstraUI.GOLD)
        cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        col.add_child(cap)
    else:
        var face := AstraUI.thumb(AstraCrewCatalog.portrait_path(id, "tired"), Vector2(130, 150))
        face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        face.modulate = Color(0.75, 0.78, 0.95)
        face.size_flags_vertical = Control.SIZE_EXPAND_FILL
        col.add_child(face)
        var name := AstraUI.label(s.name_of(id), AstraUI.T_UI, accent)
        name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        col.add_child(name)
    card.pressed.connect(_choose.bind("protect", id))
    return card

func _choose(kind: String, target: String) -> void:
    if _done:
        return
    var s: AstraGameSession = screen.session
    var result := s.choose_night_action(kind, target)
    if not bool(result.get("ok", false)):
        screen.fx.toast("그 문은 오늘 지킬 수 없습니다.", AstraUI.GOLD)
        return
    _done = true
    screen.fx.play("phase")
    # The night resolves at once; the morning tells what happened.
    screen.call_deferred("advance_phase")
