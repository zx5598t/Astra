extends VBoxContainer

# Four room cards (what is left, what was destroyed) and a large card for the
# clue that was just found.

var screen
var _header: RichTextLabel
var _grid: GridContainer
var _mission: VBoxContainer
var _latest: VBoxContainer
var _last_clue_id: String = ""

func setup(game_screen) -> void:
    screen = game_screen
    add_theme_constant_override("separation", 12)
    size_flags_vertical = Control.SIZE_EXPAND_FILL
    _header = AstraUI.rich(18)
    add_child(_header)
    var content := AstraUI.vbox(12)
    add_child(AstraUI.scroll(content))
    _mission = AstraUI.vbox(6)
    content.add_child(_mission)
    _grid = GridContainer.new()
    _grid.columns = 2
    _grid.add_theme_constant_override("h_separation", 10)
    _grid.add_theme_constant_override("v_separation", 10)
    content.add_child(_grid)
    content.add_child(AstraUI.section("방금 확보한 단서", AstraUI.GOLD))
    _latest = AstraUI.vbox(8)
    content.add_child(_latest)
    refresh()

func refresh() -> void:
    var session: AstraGameSession = screen.session
    _header.text = "[b]현장 조사[/b]   [color=#%s]행동력[/color] %s" % [AstraUI.hex(AstraUI.MUTED), AstraUI.pips(session.investigation_ap, session.investigation_ap_max(), AstraUI.GOLD)]
    _refresh_mission(session)
    AstraUI.clear(_grid)
    var op_rooms := {}
    for op in session.case_data.get("ops", []):
        op_rooms[str(op.get("room", ""))] = str(op.get("name", ""))
    for room in session.case_data.get("rooms", []):
        _grid.add_child(_room_card(session, room, str(op_rooms.get(str(room.get("id", "")), ""))))
    AstraUI.clear(_latest)
    var clue := session.clue_by_id(_last_clue_id)
    if clue.is_empty():
        _latest.add_child(AstraUI.label("구역을 골라 조사하세요. 조작 현장에는 실행자의 흔적이, 다른 구역에는 달아난 동선과 출입 기록이 남아 있습니다.", 14, AstraUI.MUTED, true))
    else:
        var card := AstraClueCard.new()
        card.setup(session, clue, false)
        _latest.add_child(card)

func _room_card(session: AstraGameSession, room: Dictionary, op_name: String) -> Control:
    var room_id := str(room.get("id", ""))
    var status := session.room_status(room_id)
    var remaining := int(status.get("remaining", 0))
    var accent := AstraUI.RED if op_name != "" else AstraUI.CYAN
    var card := AstraUI.panel(AstraUI.PANEL_2, Color(accent, 0.45), 12, 12)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var box := AstraUI.vbox(6)
    card.add_child(box)
    var head := AstraUI.hbox(8)
    box.add_child(head)
    head.add_child(AstraUI.label(str(room.get("name", room_id)), 20, AstraUI.TEXT))
    if op_name != "":
        head.add_child(AstraUI.chip("조작 현장 · " + op_name, AstraUI.RED, 11))
    box.add_child(AstraUI.label(str(room.get("desc", "")), 13, AstraUI.MUTED, true))
    var chips := AstraUI.hbox(6)
    box.add_child(chips)
    chips.add_child(AstraUI.chip("남은 흔적 %d" % remaining, AstraUI.GOLD if remaining > 0 else AstraUI.DIM, 12))
    if int(status.get("found", 0)) > 0:
        chips.add_child(AstraUI.chip("확보 %d" % int(status.get("found", 0)), AstraUI.GREEN, 12))
    if int(status.get("destroyed", 0)) > 0:
        chips.add_child(AstraUI.chip("훼손 %d" % int(status.get("destroyed", 0)), AstraUI.RED, 12))
    var can_search := session.investigation_ap > 0 and remaining > 0
    var label := "조사하기 · 행동력 1"
    if remaining <= 0:
        label = "더 찾을 흔적 없음"
    elif session.investigation_ap <= 0:
        label = "행동력 없음"
    var button := AstraUI.button(label, accent, 15, 42, can_search)
    button.disabled = not can_search
    button.pressed.connect(_search.bind(room_id))
    box.add_child(button)
    return card

func _search(room_id: String) -> void:
    var session: AstraGameSession = screen.session
    var clue := session.search_room(room_id)
    if clue.is_empty():
        return
    _last_clue_id = str(clue.get("id", ""))
    screen.fx.play("clue")
    screen.fx.toast("단서 확보 · " + str(clue.get("title", "")), AstraUI.GOLD)
    refresh()

func _refresh_mission(session: AstraGameSession) -> void:
    AstraUI.clear(_mission)
    var mission := session.mission_status()
    if mission.is_empty():
        return
    var complete := bool(mission.get("complete", false))
    var panel := AstraUI.panel(Color(AstraUI.CYAN, 0.07), Color(AstraUI.CYAN, 0.35), 10, 12)
    _mission.add_child(panel)
    var row := AstraUI.hbox(14)
    panel.add_child(row)
    var text := AstraUI.vbox(4)
    text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(text)
    text.add_child(AstraUI.label(("✓ 완료  /  " if complete else "선택 임무  /  ") + str(mission.get("title", "")), 16, AstraUI.GREEN if complete else AstraUI.CYAN))
    text.add_child(AstraUI.label(str(mission.get("result", "")) if complete else str(mission.get("description", "")), 13, AstraUI.MUTED, true))
    if not complete:
        text.add_child(AstraUI.label("보상 · " + str(mission.get("reward", "")), 12, AstraUI.GOLD, true))
    var button := AstraUI.button(str(mission.get("action_label", "")), AstraUI.CYAN, 14, 42)
    button.disabled = not bool(mission.get("available", false))
    button.pressed.connect(_perform_mission)
    row.add_child(button)

func _perform_mission() -> void:
    var result: Dictionary = screen.session.perform_mission()
    if bool(result.get("ok", false)):
        screen.fx.play("clue")
        screen.fx.toast(str(result.get("text", "")), AstraUI.GREEN, 4.0)
