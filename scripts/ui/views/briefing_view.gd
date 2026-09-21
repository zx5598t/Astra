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
    # Story framing: tell the player where the chapter stands before asking
    # them to parse timestamps, clues or suspects. This is deliberately short:
    # one concrete situation and one question, not a lore dump.
    var chapter_story := AstraVoyageContent.chapter(s.case_id)
    var framing := AstraUI.reading_panel(AstraUI.VIOLET)
    _body.add_child(framing)
    var framing_box := AstraUI.vbox(6)
    framing.add_child(framing_box)
    framing_box.add_child(AstraUI.label("현재 상황", AstraUI.T_META, AstraUI.VIOLET))
    framing_box.add_child(AstraUI.prose(str(chapter_story.get("situation", s.case_data.get("story_intro", ""))), AstraUI.T_BODY, AstraUI.TEXT))
    framing_box.add_child(AstraUI.label("이번에 확인할 것", AstraUI.T_META, AstraUI.GOLD))
    framing_box.add_child(AstraUI.prose(str(chapter_story.get("goal", s.case_data.get("objective", ""))), AstraUI.T_BODY, AstraUI.TEXT))

    var awakened := _newly_awakened(s)
    if awakened != "":
        var member := s.npc(awakened)
        var arrival := AstraUI.reading_panel(AstraUI.VIOLET)
        _body.add_child(arrival)
        var arrival_box := AstraUI.vbox(6)
        arrival.add_child(arrival_box)
        arrival_box.add_child(AstraUI.label("새로 깨어난 승무원", AstraUI.T_META, AstraUI.VIOLET))
        arrival_box.add_child(AstraUI.crew_tag(awakened, AstraUI.T_BODY, true, 30))
        if member != null:
            arrival_box.add_child(AstraUI.prose("%s · %s. 이번 장부터 함께 움직입니다." % [member.display_name, member.job], AstraUI.T_META, AstraUI.TEXT))

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
    reason_box.add_child(AstraUI.label("기억에 없는 조작", AstraUI.T_META, AstraUI.RED))
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
    var phase_names := {
        "INVESTIGATION":"현장 조사", "INTERROGATION":"진술 확인",
        "MEETING":"짧은 공개 확인", "VOTE":"장기수면 격리 투표", "NIGHT":"밤 행동"
    }
    var visible_steps: Array = []
    for phase_id in AstraCaseCatalog.phase_flow(s.case_id):
        if phase_names.has(phase_id):
            visible_steps.append(str(phase_names[phase_id]))
    for i in range(visible_steps.size()):
        if i > 0:
            steps.add_child(AstraUI.label("→", AstraUI.T_META, AstraUI.MUTED))
        steps.add_child(AstraUI.label(str(visible_steps[i]), AstraUI.T_META, AstraUI.CYAN))

    # Who is in the room, with a face and a job against each name.
    var roster_panel := AstraUI.reading_panel(AstraUI.MUTED, 0.9)
    _body.add_child(roster_panel)
    var roster_box := AstraUI.vbox(6)
    roster_panel.add_child(roster_box)
    roster_box.add_child(AstraUI.label("지금 깨어 있는 동료", AstraUI.T_META, AstraUI.MUTED))
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
    var chapter_story := AstraVoyageContent.chapter(s.case_id)
    box.add_child(AstraUI.label("계속 확인할 것", AstraUI.T_META, AstraUI.GOLD))
    box.add_child(AstraUI.prose(str(chapter_story.get("goal", s.case_data.get("objective", ""))), AstraUI.T_BODY, AstraUI.TEXT))
    _add_previous_day_feedback(s)
    var status := AstraUI.hbox(10)
    _body.add_child(status)
    var counts := s.status_counts()
    status.add_child(AstraUI.chip("활동 중 %d" % int(counts["active"]), AstraUI.CYAN, AstraUI.T_UI))
    if int(counts["isolated"]) > 0:
        status.add_child(AstraUI.chip("장기수면 격리 %d" % int(counts["isolated"]), AstraUI.GOLD, AstraUI.T_UI))
    if int(counts["offline"]) > 0:
        status.add_child(AstraUI.chip("생체 신호 두절 %d" % int(counts["offline"]), AstraUI.RED, AstraUI.T_UI))
    var left := s.max_days - s.day
    status.add_child(AstraUI.chip("판단할 날 %d일 남음" % (left + 1), AstraUI.GOLD if left <= 1 else AstraUI.MUTED, AstraUI.T_UI))
    if s.day == s.max_days:
        _body.add_child(AstraUI.prose("오늘이 마지막 판단 기회입니다. 저녁 투표가 끝나면 이번 기록을 마무리합니다.", AstraUI.T_BODY, AstraUI.GOLD))


func _add_previous_day_feedback(s: AstraGameSession) -> void:
    var summary := s.briefing_social_summary(s.day - 1)
    var relationships: Array = summary.get("relationship_changes",[])
    var opinions: Array = summary.get("opinion_changes",[])
    if relationships.is_empty() and opinions.is_empty():
        return
    var panel := AstraUI.panel(Color(AstraUI.CYAN,0.025),Color(AstraUI.CYAN,0.20),9,11)
    _body.add_child(panel)
    var box := AstraUI.vbox(5)
    panel.add_child(box)
    box.add_child(AstraUI.label("지난 날의 여파",AstraUI.T_META,AstraUI.CYAN))
    for entry in relationships.slice(0,mini(2,relationships.size())):
        box.add_child(AstraUI.label(str(entry.get("pair","")),AstraUI.T_UI,AstraUI.TEXT))
        box.add_child(AstraUI.prose(str(entry.get("text","")),AstraUI.T_META,AstraUI.MUTED))
    if not opinions.is_empty():
        box.add_child(AstraUI.prose("· " + str(opinions[0].get("text","")),AstraUI.T_META,AstraUI.MUTED))

# Why the case needs a culprit rather than a repair crew, derived from the case
# rather than written per case, so every incident explains itself the same way.
func _why_a_person(s: AstraGameSession, ops: Array) -> String:
    if ops.is_empty(): return ""
    return "%s의 콘솔에서 직접 실행한 명령입니다. 실행자 칸은 비어 있습니다. 누가 왜 움직였는지는 아직 알 수 없습니다." % s.room_name(str(ops[0].get("room","")))

func _mission_text(s: AstraGameSession) -> String:
    var base := "확인할 실행자는 %d명입니다. 조작이 일어난 곳을 살피고, 동료가 기억하는 동선과 비교하세요. 거짓말에도 다른 사정이 있을 수 있습니다." % s.null_count
    if AstraCaseCatalog.has_phase(s.case_id, "VOTE"):
        return base + " 충분한 근거가 모이면 장기수면 격리 투표로 행동을 멈출 수 있습니다."
    if AstraCaseCatalog.has_phase(s.case_id, "MEETING"):
        return base + " 이번 장은 짧은 공개 확인까지 진행하고 기록을 정리합니다."
    return base + " 이번 장은 조사와 대화까지만 익히고 기록을 정리합니다."

func _newly_awakened(s: AstraGameSession) -> String:
    var index := AstraCaseCatalog.CAMPAIGN.find(s.case_id)
    if index <= 0 or index > AstraCrewCatalog.AWAKENING_ORDER.size():
        return ""
    return str(AstraCrewCatalog.AWAKENING_ORDER[index - 1])
