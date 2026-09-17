class_name AstraClueCard
extends PanelContainer

# Readable card for one clue: what kind of record it is, where and when it
# came from, the full text, and the candidate names as colored chips.

const KIND_LABELS := {
    "context": ["사건 기록", AstraUI.CYAN],
    "op_record": ["조작 기록", AstraUI.RED],
    "access_log": ["출입 기록", AstraUI.GREEN],
    "trace": ["흔적", AstraUI.GOLD],
    "sighting": ["목격 증언", AstraUI.PINK],
    "slip": ["실언", AstraUI.RED],
    "night": ["밤 기록", AstraUI.NIGHT],
    "planted": ["제보", AstraUI.VIOLET]
}

signal pressed(clue_id: String)

var clue_id: String = ""
var clickable: bool = false

func setup(session: AstraGameSession, clue: Dictionary, compact: bool = false, is_clickable: bool = false) -> void:
    clue_id = str(clue.get("id", ""))
    clickable = is_clickable
    var kind := str(clue.get("kind", ""))
    var kind_info: Array = KIND_LABELS.get(kind, ["기록", AstraUI.MUTED])
    var accent: Color = kind_info[1]
    add_theme_stylebox_override("panel", AstraUI.style(Color(AstraUI.PANEL_2, 0.96), Color(accent, 0.45), 10, 1, 10 if compact else 14))
    if clickable:
        mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
        mouse_filter = Control.MOUSE_FILTER_STOP
    var box := AstraUI.vbox(5)
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(box)

    var head := AstraUI.hbox(6)
    head.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_child(head)
    head.add_child(AstraUI.chip(str(kind_info[0]), accent, 11))
    var title := AstraUI.label(str(clue.get("title", "")), 15 if compact else 18, AstraUI.TEXT)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    head.add_child(title)
    if bool(clue.get("public", false)):
        head.add_child(AstraUI.chip("공개됨", AstraUI.CYAN, 11))

    var meta: Array = []
    var room_id := str(clue.get("room", ""))
    if room_id != "":
        meta.append(session.room_name(room_id))
    if str(clue.get("time", "")) != "":
        meta.append(str(clue.get("time", "")))
    var op_id := str(clue.get("op", ""))
    if op_id != "":
        meta.append("관련 조작: " + session.op_name(op_id))
    if str(clue.get("source", "")) != "":
        meta.append("출처: " + session.name_of(str(clue.get("source", ""))))
    var meta_label := AstraUI.label(" · ".join(PackedStringArray(meta)), 12, AstraUI.MUTED)
    meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    box.add_child(meta_label)

    var body := AstraUI.label(str(clue.get("text", "")), 13 if compact else 15, Color("d6e3f5"), true)
    box.add_child(body)

    var members: Array = clue.get("members", [])
    if not members.is_empty() and kind != "access_log":
        var chips := HFlowContainer.new()
        chips.add_theme_constant_override("h_separation", 6)
        chips.add_theme_constant_override("v_separation", 4)
        chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
        box.add_child(chips)
        chips.add_child(AstraUI.label("후보", 11, AstraUI.DIM))
        for member_id in members:
            chips.add_child(AstraUI.chip(session.name_of(str(member_id)), AstraCrewCatalog.accent(str(member_id)), 12))

func _gui_input(event: InputEvent) -> void:
    if clickable and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        pressed.emit(clue_id)
        accept_event()
