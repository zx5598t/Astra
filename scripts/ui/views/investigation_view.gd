extends VBoxContainer

# Four room cards (what is left, what was destroyed) and a large card for the
# clue that was just found.

var screen
var _header: RichTextLabel
var _grid: GridContainer
var _latest: VBoxContainer
var _last_clue_id: String = ""

func setup(game_screen) -> void:
    screen = game_screen
    add_theme_constant_override("separation", 12)
    size_flags_vertical = Control.SIZE_EXPAND_FILL
    _header = AstraUI.rich(18)
    add_child(_header)
    _grid = GridContainer.new()
    _grid.columns = 2
    _grid.add_theme_constant_override("h_separation", 10)
    _grid.add_theme_constant_override("v_separation", 10)
    add_child(_grid)
    add_child(AstraUI.section("방금 확보한 단서", AstraUI.GOLD))
    _latest = AstraUI.vbox(8)
    add_child(AstraUI.scroll(_latest))
    refresh()

func refresh() -> void:
    var session: AstraGameSession = screen.session
    _header.text = "[b]현장 조사[/b]   [color=#%s]행동력[/color] %s" % [AstraUI.hex(AstraUI.MUTED), AstraUI.pips(session.investigation_ap, session.investigation_ap_max(), AstraUI.GOLD)]
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
