class_name AstraCrewCard
extends PanelContainer

# One row of the crew roster: portrait, name, trust/stress, status, the
# player's own mark (Null 의심 / 신뢰 / 보류) and live vote intention.

signal selected(npc_id: String)
signal mark_pressed(npc_id: String)

var npc_id: String = ""
var _thumb: TextureRect
var _name: Label
var _sub: Label
var _trust: ProgressBar
var _stress: ProgressBar
var _meters: VBoxContainer
var _mark: Button
var _intent: Label
var _hotkey: Label

func setup(id: String, hotkey: int) -> void:
    npc_id = id
    mouse_filter = Control.MOUSE_FILTER_STOP
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    custom_minimum_size = Vector2(0, 74)
    var row := AstraUI.hbox(10)
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(row)
    _thumb = AstraUI.thumb(str(AstraCrewCatalog.info(id).get("portrait", "")), Vector2(50, 60))
    row.add_child(_thumb)
    var info := AstraUI.vbox(3)
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(info)
    var title := AstraUI.hbox(6)
    title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    info.add_child(title)
    _hotkey = AstraUI.label(str(hotkey), 11, AstraUI.DIM)
    title.add_child(_hotkey)
    _name = AstraUI.label(AstraCrewCatalog.display_name(id), 17, AstraCrewCatalog.accent(id))
    title.add_child(_name)
    _sub = AstraUI.label(str(AstraCrewCatalog.info(id).get("job", "")), 12, AstraUI.MUTED)
    _sub.clip_text = true
    _sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_child(_sub)
    _meters = AstraUI.vbox(3)
    _meters.mouse_filter = Control.MOUSE_FILTER_IGNORE
    info.add_child(_meters)
    var trust_row := AstraUI.hbox(6)
    trust_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    trust_row.add_child(AstraUI.label("신뢰", 11, AstraUI.DIM))
    _trust = AstraUI.meter(0.5, AstraUI.GREEN, 5)
    trust_row.add_child(_trust)
    _meters.add_child(trust_row)
    var stress_row := AstraUI.hbox(6)
    stress_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stress_row.add_child(AstraUI.label("긴장", 11, AstraUI.DIM))
    _stress = AstraUI.meter(0.2, AstraUI.RED, 5)
    stress_row.add_child(_stress)
    _meters.add_child(stress_row)
    _intent = AstraUI.label("", 12, AstraUI.GOLD)
    _intent.visible = false
    info.add_child(_intent)
    _mark = AstraUI.button("", AstraUI.DIM, 15, 32)
    _mark.custom_minimum_size = Vector2(38, 34)
    _mark.tooltip_text = "내 판단 표시: 클릭할 때마다 Null 의심 → 신뢰 → 보류 → 해제"
    _mark.pressed.connect(func(): mark_pressed.emit(npc_id))
    var mark_box := AstraUI.vbox(0)
    mark_box.alignment = BoxContainer.ALIGNMENT_CENTER
    mark_box.add_child(_mark)
    row.add_child(mark_box)

func refresh(session: AstraGameSession, is_selected: bool, intention: String) -> void:
    var member := session.npc(npc_id)
    if member == null:
        return
    var accent := member.accent
    var bg := Color(accent, 0.13) if is_selected else AstraUI.PANEL_2
    var border := accent if is_selected else AstraUI.BORDER
    var box := AstraUI.style(bg, border, 10, 2 if is_selected else 1, 8)
    add_theme_stylebox_override("panel", box)
    _trust.value = member.trust
    _stress.value = member.stress
    var alive := member.is_alive()
    _thumb.modulate = Color.WHITE if alive else Color(0.45, 0.47, 0.52)
    _name.add_theme_color_override("font_color", accent if alive else AstraUI.DIM)
    if alive:
        _sub.text = member.job
        _sub.add_theme_color_override("font_color", AstraUI.MUTED)
    elif member.status == AstraCrewMember.STATUS_ISOLATED:
        var audit_note := ""
        if member.audited:
            audit_note = " · 감사: Null" if member.is_null() else " · 감사: Crew"
        _sub.text = "격리됨" + audit_note
        _sub.add_theme_color_override("font_color", AstraUI.GOLD)
    else:
        _sub.text = "신호 끊김 · Crew"
        _sub.add_theme_color_override("font_color", AstraUI.RED)
    _meters.visible = alive
    var mark := str(session.marks.get(npc_id, ""))
    var mark_color: Color = AstraUI.MARK_COLORS.get(mark, AstraUI.DIM)
    _mark.text = str(AstraUI.MARK_TEXT.get(mark, "·"))
    _mark.add_theme_stylebox_override("normal", AstraUI.style(Color(mark_color, 0.2 if mark != "" else 0.06), Color(mark_color, 0.8), 8, 1, 4))
    _mark.add_theme_color_override("font_color", mark_color if mark != "" else AstraUI.DIM)
    _intent.visible = intention != "" and alive
    if intention != "":
        _intent.text = "투표 의향 → %s" % AstraCrewCatalog.display_name(intention)

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        selected.emit(npc_id)
        accept_event()
