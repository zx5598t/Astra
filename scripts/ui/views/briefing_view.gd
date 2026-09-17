extends VBoxContainer

# Day 1: incident dossier and a three-step "how to crack it" guide.
# Later days: the morning report of what happened overnight.

var screen
var _body: VBoxContainer

func setup(game_screen) -> void:
    screen = game_screen
    add_theme_constant_override("separation", 12)
    size_flags_vertical = Control.SIZE_EXPAND_FILL
    add_child(_banner())
    _body = AstraUI.vbox(12)
    add_child(AstraUI.scroll(_body))
    refresh()

func refresh() -> void:
    var session: AstraGameSession = screen.session
    AstraUI.clear(_body)
    var dispatch := session.story_dispatch()
    if dispatch != "":
        var transmission := AstraUI.panel(Color(AstraUI.CYAN, 0.05), Color(AstraUI.CYAN, 0.25), 10, 12)
        var lines := AstraUI.vbox(5)
        transmission.add_child(lines)
        lines.add_child(AstraUI.section("항해 기록 / 수신된 메시지"))
        lines.add_child(AstraUI.label(dispatch, 16, AstraUI.TEXT, true))
        _body.add_child(transmission)
    if session.day == 1:
        _day_one(session)
    else:
        _morning(session)

func _banner() -> Control:
    var session: AstraGameSession = screen.session
    var data := session.case_data
    var accent := Color(str(data.get("accent", "55d6ff")))
    var frame := PanelContainer.new()
    frame.custom_minimum_size = Vector2(0, 176)
    frame.clip_contents = true
    frame.add_theme_stylebox_override("panel", AstraUI.style(AstraUI.PANEL_2, Color(accent, 0.6), 12, 1, 0))
    var art := AstraUI.thumb(str(data.get("environment", "")), Vector2(0, 176))
    art.modulate = Color(1, 1, 1, 0.75)
    frame.add_child(art)
    var shade := ColorRect.new()
    shade.color = Color(0.01, 0.02, 0.05, 0.45)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    frame.add_child(shade)
    var text := AstraUI.vbox(2)
    text.alignment = BoxContainer.ALIGNMENT_END
    text.mouse_filter = Control.MOUSE_FILTER_IGNORE
    frame.add_child(AstraUI.margin(text, 22, 16, 22, 18))
    text.add_child(AstraUI.label("%s · DAY %d / %d" % [str(data.get("code", "")), session.day, AstraGameSession.MAX_DAYS], 13, accent))
    text.add_child(AstraUI.label(str(data.get("title", "")), 38, AstraUI.TEXT))
    text.add_child(AstraUI.label("%s · %s" % [str(data.get("title_ko", "")), str(data.get("theme", ""))], 15, AstraUI.MUTED))
    return frame

func _day_one(session: AstraGameSession) -> void:
    var data := session.case_data
    _body.add_child(AstraUI.label(str(data.get("story_intro", data.get("hook", ""))), 17, AstraUI.TEXT, true))

    var facts := GridContainer.new()
    facts.columns = 2
    facts.add_theme_constant_override("h_separation", 16)
    facts.add_theme_constant_override("v_separation", 6)
    _body.add_child(facts)
    _fact(facts, "피해자", "%s %s" % [str(data.get("victim_role", "")), session.victim_name()])
    _fact(facts, "사건 시간대", session.window_text())
    var index := 1
    for op in data.get("ops", []):
        _fact(facts, "조작 %d" % index, "%s · %s · %s" % [str(op.get("name", "")), session.room_name(str(op.get("room", ""))), AstraCaseCatalog.format_time(int(op.get("minute", 0)), int(op.get("second", 0)))])
        index += 1
    _fact(facts, "조사 방식", "%s — %s" % [session.protocol_name(), str(AstraGameSession.PROTOCOLS[session.protocol]["summary"])])

    var objective := AstraUI.panel(Color(AstraUI.GOLD, 0.08), Color(AstraUI.GOLD, 0.5), 10, 12)
    objective.add_child(AstraUI.label("목표 · " + str(data.get("objective", "")), 16, AstraUI.GOLD, true))
    _body.add_child(objective)

    _body.add_child(AstraUI.section("이렇게 추리하세요"))
    var steps := [
        ["1  현장 조사", "구역마다 흔적이 숨어 있습니다. 흔적은 범인을 직접 지목하지 않고 ‘후보 명단’을 줍니다. 같은 조작에서 나온 흔적 두 개의 명단이 겹치는 사람이 그 조작의 실행자입니다. 기록 시각이 사건 시간대 밖이면 무관한 흔적입니다."],
        ["2  개인 심문", "알리바이를 모아 출입 기록과 대조하세요. 모순이 생긴 사람을 추궁하면 숨긴 사정을 털어놓거나, Null이라면 실언을 할 수 있습니다. 모든 거짓말쟁이가 Null은 아닙니다."],
        ["3  회의 · 투표 · 밤", "회의에서 단서를 공개하고 지목·변호로 여론을 움직이세요. 조사관의 표는 2표입니다. 밤에는 Null이 한 명을 노리니 누군가를 보호하거나 구역을 감시하세요."]
    ]
    for step in steps:
        var card := AstraUI.panel(AstraUI.PANEL_2, AstraUI.BORDER, 10, 12)
        var box := AstraUI.vbox(4)
        card.add_child(box)
        box.add_child(AstraUI.label(str(step[0]), 16, AstraUI.CYAN))
        box.add_child(AstraUI.label(str(step[1]), 14, AstraUI.MUTED, true))
        _body.add_child(card)

func _morning(session: AstraGameSession) -> void:
    _body.add_child(AstraUI.section("밤사이 보고", AstraUI.NIGHT))
    var report := AstraUI.panel(Color(AstraUI.NIGHT, 0.07), Color(AstraUI.NIGHT, 0.45), 10, 14)
    var lines := AstraUI.vbox(6)
    report.add_child(lines)
    if session.morning_report.is_empty():
        lines.add_child(AstraUI.label("조용한 밤이었다.", 16, AstraUI.TEXT))
    for line in session.morning_report:
        lines.add_child(AstraUI.label("▸ " + str(line), 16, AstraUI.TEXT, true))
    _body.add_child(report)

    _body.add_child(AstraUI.section("현재 상황"))
    var status := AstraUI.vbox(4)
    _body.add_child(status)
    status.add_child(AstraUI.label("활동 중인 승무원 %d명 · 오늘은 DAY %d / %d" % [session.living_ids().size(), session.day, AstraGameSession.MAX_DAYS], 15, AstraUI.TEXT))
    for item in session.isolations:
        var member := session.npc(str(item.get("id", "")))
        var audit_note := ""
        if member.audited:
            audit_note = " — 감사 결과: %s" % ("Null" if member.is_null() else "무고한 승무원")
        status.add_child(AstraUI.label("DAY %d 격리 · %s (%d표)%s" % [int(item.get("day", 0)), member.display_name, int(item.get("votes", 0)), audit_note], 14, AstraUI.GOLD))
    for item in session.casualties:
        status.add_child(AstraUI.label("DAY %d 밤 · %s 신호 끊김 (Null은 동료를 노리지 않는다 — 확실한 승무원)" % [int(item.get("day", 0)), session.name_of(str(item.get("id", "")))], 14, AstraUI.RED, true))
    var remaining := 0
    for room_id in session.room_ids():
        remaining += int(session.room_status(room_id).get("remaining", 0))
    status.add_child(AstraUI.label("아직 찾지 못한 현장 흔적 %d개" % remaining, 14, AstraUI.MUTED))
    if session.day == AstraGameSession.MAX_DAYS:
        var warn := AstraUI.panel(Color(AstraUI.RED, 0.08), Color(AstraUI.RED, 0.5), 10, 12)
        warn.add_child(AstraUI.label("마지막 날입니다. 오늘 투표가 끝나면 사건이 종료됩니다.", 15, AstraUI.RED, true))
        _body.add_child(warn)

func _fact(grid: GridContainer, title: String, value: String) -> void:
    grid.add_child(AstraUI.label(title, 14, AstraUI.DIM))
    grid.add_child(AstraUI.label(value, 15, AstraUI.TEXT, true))
