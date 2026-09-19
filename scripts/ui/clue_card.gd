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
    var picture := AstraUI.thumb(AstraArt.clue(clue),Vector2(64,64) if compact else Vector2(110,110))
    picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    head.add_child(picture)
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

    var body := AstraUI.prose(str(clue.get("text", "")), AstraUI.T_META if compact else AstraUI.T_BODY, Color("d6e3f5"))
    box.add_child(body)

    var members: Array = clue.get("members", [])
    if not members.is_empty() and kind != "access_log":
        var chips := HFlowContainer.new()
        chips.add_theme_constant_override("h_separation", 6)
        chips.add_theme_constant_override("v_separation", 4)
        chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
        box.add_child(chips)
        chips.add_child(AstraUI.label("후보", AstraUI.T_META, AstraUI.DIM))
        for member_id in members:
            var pill := AstraUI.hbox(4)
            pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
            pill.add_child(AstraUI.crew_dot(str(member_id), 22))
            pill.add_child(AstraUI.label(session.name_of(str(member_id)), AstraUI.T_META, AstraCrewCatalog.accent(str(member_id))))
            chips.add_child(pill)

    # "이게 무슨 뜻이죠?" — the record itself says what happened; this says what
    # it lets you conclude and what to do with it. Without it, a first-time
    # player reads "서명 칸은 비어 있다" as set dressing rather than as the
    # single most important sentence in the case.
    _add_explainer(session, clue, box, accent, compact)

func _add_explainer(session: AstraGameSession, clue: Dictionary, box: VBoxContainer, accent: Color, compact: bool) -> void:
    var meaning := AstraClueHelp.meaning(clue)
    if meaning == "":
        return
    var panel := AstraUI.panel(Color(accent, 0.07), Color(accent, 0.3), 8, 10)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var inner := AstraUI.vbox(5)
    inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_child(inner)
    inner.add_child(AstraUI.label("이게 무슨 뜻이죠?", AstraUI.T_META, accent))
    var lead := AstraUI.rich_prose(AstraUI.T_META)
    lead.text = meaning
    inner.add_child(lead)
    var specific := AstraClueHelp.specific(clue, session)
    if specific != "":
        var detail := AstraUI.rich_prose(AstraUI.T_META)
        detail.text = specific
        inner.add_child(detail)
    var todo := AstraClueHelp.action(clue)
    if todo != "":
        inner.add_child(AstraUI.prose("→ " + todo, AstraUI.T_META, AstraUI.GOLD))
    for term in AstraClueHelp.terms(clue):
        inner.add_child(AstraUI.prose("· %s — %s" % [str(term["term"]), str(term["note"])], AstraUI.T_META, AstraUI.DIM))

    if compact:
        # In a picker the explainer is collapsed so the list stays scannable.
        panel.visible = false
        var toggle := AstraUI.button("이게 무슨 뜻이죠?", accent, AstraUI.T_META, 32)
        toggle.pressed.connect(func(): panel.visible = not panel.visible)
        box.add_child(toggle)
    box.add_child(panel)

func _gui_input(event: InputEvent) -> void:
    if clickable and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        pressed.emit(clue_id)
        accept_event()
