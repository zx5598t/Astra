class_name AstraNotebookPanel
extends PanelContainer

# Right-hand notebook: 단서 (clue cards), 추리 노트 (alibi table + per-operation
# trace grid + contradictions) and 기록 (case log).

var session: AstraGameSession
var tabs: TabContainer
var _clue_list: VBoxContainer
var _notes: VBoxContainer
var _log: RichTextLabel
var _objectives: VBoxContainer
var _last_clue_count: int = -1

func setup(game_session: AstraGameSession) -> void:
    session = game_session
    add_theme_stylebox_override("panel", AstraUI.style(AstraUI.PANEL, AstraUI.BORDER, 12, 1, 8))
    tabs = TabContainer.new()
    tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
    tabs.add_theme_font_size_override("font_size", 14)
    tabs.add_theme_color_override("font_selected_color", AstraUI.CYAN)
    tabs.add_theme_color_override("font_unselected_color", AstraUI.MUTED)
    tabs.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
    var layout := AstraUI.vbox(10)
    add_child(layout)
    _objectives = AstraUI.vbox(5)
    layout.add_child(_objectives)
    layout.add_child(tabs)

    _clue_list = AstraUI.vbox(8)
    var clue_scroll := AstraUI.scroll(_clue_list)
    clue_scroll.name = "단서"
    tabs.add_child(clue_scroll)

    _notes = AstraUI.vbox(12)
    var note_scroll := AstraUI.scroll(_notes, true)
    note_scroll.name = "추리 노트"
    tabs.add_child(note_scroll)

    _log = AstraUI.rich(13, false)
    _log.scroll_following = true
    _log.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _log.name = "기록"
    tabs.add_child(_log)
    refresh()

func refresh() -> void:
    if session == null:
        return
    AstraUI.clear(_objectives)
    _objectives.add_child(AstraUI.section("조사 목표"))
    for objective in session.objectives():
        var complete := bool(objective.get("complete", false))
        var row := AstraUI.hbox(6)
        row.add_child(AstraUI.label("✓" if complete else "○", 13, AstraUI.GREEN if complete else AstraUI.DIM))
        row.add_child(AstraUI.label(str(objective.get("label", "")), 12, AstraUI.MUTED, true))
        row.add_child(AstraUI.label("%d/%d" % [int(objective.get("current", 0)), int(objective.get("target", 1))], 12, AstraUI.GREEN if complete else AstraUI.GOLD))
        _objectives.add_child(row)
    var found := session.found_clues()
    tabs.set_tab_title(0, "단서 %d" % found.size())
    tabs.set_tab_title(1, "추리 노트%s" % (" ⚠%d" % session.contradictions.size() if not session.contradictions.is_empty() else ""))
    tabs.set_tab_title(2, "기록")
    _refresh_clues(found)
    _refresh_notes()
    _refresh_log()

func focus_tab(index: int) -> void:
    if tabs != null:
        tabs.current_tab = clampi(index, 0, tabs.get_tab_count() - 1)

func cycle_tab() -> void:
    if tabs != null:
        tabs.current_tab = (tabs.current_tab + 1) % tabs.get_tab_count()

func _refresh_clues(found: Array) -> void:
    AstraUI.clear(_clue_list)
    if found.is_empty():
        _clue_list.add_child(AstraUI.label("아직 확보한 단서가 없습니다.\n현장 조사에서 구역을 골라 흔적을 찾으세요.", 14, AstraUI.MUTED, true))
        return
    var destroyed := 0
    for clue in session.clues:
        if bool(clue.get("destroyed", false)) and not bool(clue.get("found", false)):
            destroyed += 1
    if destroyed > 0:
        _clue_list.add_child(AstraUI.label("밤사이 지워진 흔적 %d개" % destroyed, 12, AstraUI.RED))
    for index in range(found.size() - 1, -1, -1):
        var card := AstraClueCard.new()
        card.setup(session, found[index], true)
        _clue_list.add_child(card)
    if found.size() != _last_clue_count:
        _last_clue_count = found.size()

func _refresh_notes() -> void:
    AstraUI.clear(_notes)
    _notes.add_child(AstraUI.label("사건 시간대 %s" % session.window_text(), 13, AstraUI.GOLD))
    _build_alibi_table()
    for op in session.case_data.get("ops", []):
        _build_trace_grid(op)
    _build_contradictions()

func _build_alibi_table() -> void:
    _notes.add_child(AstraUI.section("알리바이 대조"))
    var grid := GridContainer.new()
    grid.columns = 3
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 4)
    _notes.add_child(grid)
    for header in ["이름", "진술", "판정"]:
        grid.add_child(AstraUI.label(header, 11, AstraUI.DIM))
    for npc_id in AstraCrewCatalog.ORDER:
        var member := session.npc(npc_id)
        grid.add_child(AstraUI.label(member.display_name, 13, member.accent if member.is_alive() else AstraUI.DIM))
        var claim: Dictionary = session.known_claims.get(npc_id, {})
        if claim.is_empty():
            grid.add_child(AstraUI.label("미확보", 12, AstraUI.DIM))
        else:
            var mates: Array = claim.get("companions", [])
            var text := session.room_name(str(claim.get("position", "")))
            text += " · " + ("혼자" if mates.is_empty() else session.names_of(mates))
            var claim_label := AstraUI.label(text, 12, AstraUI.TEXT)
            claim_label.custom_minimum_size = Vector2(170, 0)
            claim_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            grid.add_child(claim_label)
        grid.add_child(_verdict(npc_id))

func _verdict(npc_id: String) -> Label:
    var member := session.npc(npc_id)
    if member.secret_revealed:
        return AstraUI.label("사정 해명", 12, AstraUI.GOLD)
    var issues := session.contradictions_on(npc_id).size()
    if issues > 0:
        return AstraUI.label("⚠ 모순 %d" % issues, 12, AstraUI.RED)
    var claim: Dictionary = session.known_claims.get(npc_id, {})
    if not claim.is_empty():
        for clue in session.found_clues():
            if str(clue.get("kind", "")) == "access_log" and npc_id in clue.get("log_people", []) and str(clue.get("log_room", "")) == str(claim.get("position", "")):
                return AstraUI.label("✓ 기록 일치", 12, AstraUI.GREEN)
    return AstraUI.label("—", 12, AstraUI.DIM)

func _build_trace_grid(op: Dictionary) -> void:
    var op_id := str(op.get("id", ""))
    var columns: Array = []
    for clue in session.found_clues():
        if str(clue.get("op", "")) != op_id:
            continue
        if str(clue.get("kind", "")) in ["trace", "sighting", "night", "slip", "planted"]:
            columns.append(clue)
    var title := "%s 흔적 교차 · %s %s" % [str(op.get("name", "")), session.room_name(str(op.get("room", ""))), AstraCaseCatalog.format_time(int(op.get("minute", 0)), int(op.get("second", 0)))]
    _notes.add_child(AstraUI.label(title, 13, AstraUI.GOLD, true))
    if columns.is_empty():
        _notes.add_child(AstraUI.label("이 조작과 연결된 흔적이 아직 없습니다.", 12, AstraUI.DIM))
        return
    var grid := GridContainer.new()
    grid.columns = columns.size() + 2
    grid.add_theme_constant_override("h_separation", 6)
    grid.add_theme_constant_override("v_separation", 3)
    _notes.add_child(grid)
    grid.add_child(AstraUI.label("", 11, AstraUI.DIM))
    for clue in columns:
        var head := AstraUI.label(_column_title(clue), 10, AstraUI.MUTED)
        head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        head.custom_minimum_size = Vector2(48, 0)
        head.tooltip_text = str(clue.get("text", ""))
        head.mouse_filter = Control.MOUSE_FILTER_PASS
        grid.add_child(head)
    grid.add_child(AstraUI.label("합", 10, AstraUI.MUTED))
    for npc_id in AstraCrewCatalog.ORDER:
        var member := session.npc(npc_id)
        var hits := 0
        for clue in columns:
            if npc_id in clue.get("members", []):
                hits += 1
        var full := hits == columns.size() and columns.size() >= 2
        grid.add_child(AstraUI.label(member.display_name, 12, AstraUI.GOLD if full else (member.accent if member.is_alive() else AstraUI.DIM)))
        for clue in columns:
            var inside: bool = npc_id in clue.get("members", [])
            var cell := AstraUI.label("●" if inside else "·", 13, (AstraUI.GOLD if full else member.accent) if inside else AstraUI.DIM)
            cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            grid.add_child(cell)
        grid.add_child(AstraUI.label(str(hits), 12, AstraUI.GOLD if full else AstraUI.MUTED))

func _column_title(clue: Dictionary) -> String:
    var kind := str(clue.get("kind", ""))
    var head := ""
    match kind:
        "trace": head = AstraCrewCatalog.category_label(str(clue.get("category", "")))
        "sighting": head = "목격"
        "night": head = "밤"
        "slip": head = "실언"
        "planted": head = "제보"
    var time_text := str(clue.get("time", ""))
    if kind == "trace" and time_text != "":
        return "%s\n%s" % [head, time_text]
    return head

func _build_contradictions() -> void:
    _notes.add_child(AstraUI.section("발견한 모순", AstraUI.RED))
    if session.contradictions.is_empty():
        _notes.add_child(AstraUI.label("아직 없습니다. 알리바이를 모으고 출입 기록과 대조해 보세요.", 12, AstraUI.DIM, true))
        return
    for item in session.contradictions:
        var row := AstraUI.hbox(6)
        _notes.add_child(row)
        if bool(item.get("public", false)):
            row.add_child(AstraUI.chip("공개", AstraUI.CYAN, 10))
        row.add_child(AstraUI.label(str(item.get("detail", "")), 12, AstraUI.TEXT, true))

func _refresh_log() -> void:
    var lines: Array = []
    var last_day := -1
    for entry in session.journal:
        var entry_day := int(entry.get("day", 1))
        if entry_day != last_day:
            last_day = entry_day
            lines.append("[color=#%s][b]DAY %d[/b][/color]" % [AstraUI.hex(AstraUI.CYAN), entry_day])
        lines.append("[color=#%s]·[/color] %s" % [AstraUI.hex(AstraUI.DIM), AstraUI.escape(str(entry.get("text", "")))])
    _log.text = "\n".join(PackedStringArray(lines))
