extends HBoxContainer

# The morning briefing.
#
# 0.3.1 printed the hook, the two operation timestamps and a line of flavour,
# and left the player to work out what any of it had to do with them. On the
# first case this is where "what am I doing and why" has to be answered, so the
# briefing now states, in order:
#
#   무슨 일이 있었나  — the incident, in one sentence
#   왜 사람 문제인가  — why it cannot have been an accident
#   내가 할 일        — find the person who did it, before the vote
#
# Everything sits on dark plates rather than on the chapter art, because the
# art is bright and the text was disappearing into it.

var screen
var _body: VBoxContainer

func setup(game_screen) -> void:
    screen = game_screen
    add_theme_constant_override("separation", 24)
    var art := AstraUI.thumb(AstraArt.chapter(screen.session.case_id), Vector2(400, 0))
    art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_child(art)
    _body = AstraUI.vbox(12)
    var scroll := AstraUI.scroll(_body)
    scroll.size_flags_stretch_ratio = 1.25
    add_child(scroll)
    refresh()

func refresh() -> void:
    var s: AstraGameSession = screen.session
    AstraUI.clear(_body)
    var chapter := str(s.case_data.get("chapter", ""))
    _body.add_child(AstraUI.section(chapter if chapter != "" else str(s.case_data.get("code", ""))))
    _body.add_child(AstraUI.label(str(s.case_data.get("title_ko", "")) if s.day == 1 else "밤이 지나간 자리", AstraUI.T_DISPLAY, AstraUI.TEXT))

    if s.day == 1:
        _first_day(s)
    else:
        _later_day(s)

func _first_day(s: AstraGameSession) -> void:
    # 1. What happened.
    var incident := AstraUI.reading_panel(AstraUI.CYAN)
    _body.add_child(incident)
    var incident_box := AstraUI.vbox(8)
    incident.add_child(incident_box)
    incident_box.add_child(AstraUI.label("무슨 일이 있었나", AstraUI.T_META, AstraUI.CYAN))
    incident_box.add_child(AstraUI.prose(str(s.case_data.get("hook", "")), AstraUI.T_BODY, AstraUI.TEXT))
    var when_row := AstraUI.hbox(10)
    incident_box.add_child(when_row)
    when_row.add_child(AstraUI.chip("사건 시각   " + s.window_text(), AstraUI.GOLD, AstraUI.T_UI))
    when_row.add_child(AstraUI.label("이 시간대 밖의 기록은 사건과 무관합니다.", AstraUI.T_META, AstraUI.MUTED))

    # 2. Why a person did it. This is the step 0.3.1 never spelled out, and it
    #    is the whole reason the game is a social deduction game rather than a
    #    repair job.
    var ops: Array = s.case_data.get("ops", [])
    var reason := AstraUI.reading_panel(AstraUI.RED)
    _body.add_child(reason)
    var reason_box := AstraUI.vbox(8)
    reason.add_child(reason_box)
    reason_box.add_child(AstraUI.label("사고가 아닌 이유", AstraUI.T_META, AstraUI.RED))
    for op in ops:
        var line := AstraUI.hbox(10)
        reason_box.add_child(line)
        line.add_child(AstraUI.label(AstraCaseCatalog.format_time(int(op["minute"]), int(op["second"])), AstraUI.T_BODY, AstraUI.GOLD))
        line.add_child(AstraUI.prose("%s  ·  %s" % [str(op["name"]), s.room_name(str(op["room"]))], AstraUI.T_BODY, AstraUI.TEXT))
    reason_box.add_child(AstraUI.prose(_why_a_person(s, ops), AstraUI.T_BODY, AstraUI.TEXT))

    # 3. What the player does about it.
    var task := AstraUI.reading_panel(AstraUI.GOLD)
    _body.add_child(task)
    var task_box := AstraUI.vbox(8)
    task.add_child(task_box)
    task_box.add_child(AstraUI.label("당신이 할 일", AstraUI.T_META, AstraUI.GOLD))
    var mission_text := AstraUI.rich_prose(AstraUI.T_BODY)
    mission_text.text = _mission_text(s)
    task_box.add_child(mission_text)
    var steps := AstraUI.hbox(8)
    task_box.add_child(steps)
    for step in ["현장 조사", "→", "진술 확인", "→", "회의", "→", "투표"]:
        steps.add_child(AstraUI.label(step, AstraUI.T_META, AstraUI.MUTED if step == "→" else AstraUI.CYAN))

    # Who is in the room, with a face and a job against each name.
    var roster_panel := AstraUI.reading_panel(AstraUI.MUTED, 0.9)
    _body.add_child(roster_panel)
    var roster_box := AstraUI.vbox(6)
    roster_panel.add_child(roster_box)
    roster_box.add_child(AstraUI.label("이 재구성에 남은 사람", AstraUI.T_META, AstraUI.MUTED))
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 18)
    grid.add_theme_constant_override("v_separation", 6)
    roster_box.add_child(grid)
    for npc_id in s.active_roster():
        grid.add_child(AstraUI.crew_tag(str(npc_id), AstraUI.T_BODY, true, 32))

func _later_day(s: AstraGameSession) -> void:
    var report := AstraUI.reading_panel(AstraUI.NIGHT)
    _body.add_child(report)
    var box := AstraUI.vbox(8)
    report.add_child(box)
    box.add_child(AstraUI.label("밤사이 보고", AstraUI.T_META, AstraUI.NIGHT))
    if s.morning_report.is_empty():
        box.add_child(AstraUI.prose("특별한 보고는 없습니다.", AstraUI.T_BODY, AstraUI.MUTED))
    for line in s.morning_report:
        box.add_child(AstraUI.prose(str(line), AstraUI.T_BODY, AstraUI.TEXT))
    box.add_child(AstraUI.prose(s.story_dispatch(), AstraUI.T_META, AstraUI.MUTED))
    var status := AstraUI.hbox(10)
    _body.add_child(status)
    status.add_child(AstraUI.chip("남은 승무원 %d명" % s.living_ids().size(), AstraUI.CYAN, AstraUI.T_UI))
    var left := s.max_days - s.day
    status.add_child(AstraUI.chip("판단할 날 %d일 남음" % (left + 1), AstraUI.GOLD if left <= 1 else AstraUI.MUTED, AstraUI.T_UI))
    if s.day == s.max_days:
        _body.add_child(AstraUI.prose("오늘이 마지막 판단 기회입니다. 저녁 투표가 끝나면 재구성이 종료됩니다.", AstraUI.T_BODY, AstraUI.GOLD))

# Why the case needs a culprit rather than a repair crew, derived from the case
# rather than written per case, so every incident explains itself the same way.
func _why_a_person(s: AstraGameSession, ops: Array) -> String:
    if ops.size() >= 2:
        return "두 조작은 서로 다른 장소에서, 1분도 안 되는 간격으로 실행됐습니다. 한 사람이 두 곳을 오갈 수 있는 시간이 아닙니다. 적어도 두 사람이 따로 움직였다는 뜻입니다.\n\n기록에는 실행자 이름이 남아야 하지만, 그 칸은 지워져 있습니다. 시스템이 지운 것이 아니라, 실행한 사람이 지웠습니다."
    if ops.is_empty():
        return ""
    var where := s.room_name(str(ops[0].get("room", "")))
    return "이 조작은 원격으로 할 수 없습니다. 그 시각 %s에 사람이 직접 있었다는 뜻입니다.\n\n기록에는 실행자 이름이 남아야 하지만, 그 칸은 지워져 있습니다. 시스템이 지운 것이 아니라, 실행한 사람이 지웠습니다." % where

func _mission_text(s: AstraGameSession) -> String:
    var count := s.null_total()
    var days := s.max_days
    var who := "이 중 %d명은 배를 망가뜨리라는 명령을 따르고 있습니다. 기록은 그들을 [color=#ff6f7f][b]Null[/b][/color]이라고 부릅니다. 겉으로는 나머지와 구별되지 않습니다." % count
    if AstraCaseCatalog.is_calibration(s.case_id):
        who = "네 사람 중 한 명이 통신을 끊었습니다. 본인은 그렇게 말하지 않을 겁니다."
    var deadline := "오늘 저녁 투표에서 격리할 사람을 정해야 합니다." if days <= 1 else "%d일 안에 %d명을 모두 격리하면 이깁니다. 남은 승무원 수가 Null과 같아지면 집니다." % [days, count]
    return "%s\n\n%s\n\n조사해서 기록을 모으고, 사람들의 말과 맞춰 보세요. 말이 기록과 어긋나는 사람이 나옵니다. 다만 [b]거짓말한다고 전부 실행자는 아닙니다[/b] — 숨길 것이 있는 사람은 결백해도 거짓말을 합니다." % [who, deadline]
