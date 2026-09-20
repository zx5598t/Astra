extends VBoxContainer

# Case closed: outcome, the full truth (who the Nulls were, who lied and why),
# score breakdown, case theory review and archive progress.

var screen
var _body: VBoxContainer

func setup(game_screen) -> void:
    screen = game_screen
    add_theme_constant_override("separation", 10)
    size_flags_vertical = Control.SIZE_EXPAND_FILL
    _body = AstraUI.vbox(14)
    add_child(AstraUI.scroll(_body))
    refresh()

func refresh() -> void:
    var session: AstraGameSession = screen.session
    var report := session.final_report
    AstraUI.clear(_body)
    if report.is_empty():
        return
    var outcome := str(report.get("outcome", ""))
    var color := AstraUI.GREEN if outcome == "WIN" else (AstraUI.GOLD if outcome == "TIMEOUT" else AstraUI.RED)

    var hero := AstraUI.panel(Color(color, 0.08), Color(color, 0.6), 14, 18)
    _body.add_child(hero)
    var hero_row := AstraUI.hbox(18)
    hero.add_child(hero_row)
    var hero_text := AstraUI.vbox(4)
    hero_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hero_row.add_child(hero_text)
    hero_text.add_child(AstraUI.label("사건 종료 · DAY %d" % int(report.get("day", 1)), 13, AstraUI.MUTED))
    hero_text.add_child(AstraUI.label(str(report.get("title", "")), 36, color))
    hero_text.add_child(AstraUI.label(str(report.get("subtitle", "")), 16, AstraUI.TEXT, true))

    # What was different about *this* run, before any score appears. A player
    # who just lost needs the story of the run, not a receipt (§29, §92).
    var summary: Dictionary = report.get("loop_summary", {})
    var summary_lines: Array = summary.get("lines", [])
    if not summary_lines.is_empty():
        var recap := AstraUI.panel(AstraUI.PANEL_2, Color(AstraUI.CYAN, 0.3), 12, 14)
        _body.add_child(recap)
        var recap_box := AstraUI.vbox(6)
        recap.add_child(recap_box)
        recap_box.add_child(AstraUI.label("이번 조사에서", AstraUI.T_META, AstraUI.CYAN))
        for line in summary_lines:
            recap_box.add_child(AstraUI.prose("· " + str(line), AstraUI.T_BODY, AstraUI.TEXT))

    if outcome != "WIN":
        var post: Dictionary = report.get("post_mortem", {})
        var lesson := AstraUI.panel(Color(AstraUI.GOLD, 0.06), Color(AstraUI.GOLD, 0.38), 12, 14)
        _body.add_child(lesson)
        var lesson_box := AstraUI.vbox(6)
        lesson.add_child(lesson_box)
        lesson_box.add_child(AstraUI.label("놓친 것", AstraUI.T_META, AstraUI.GOLD))
        if str(post.get("innocent_lie", "")) != "":
            lesson_box.add_child(AstraUI.prose("· " + str(post["innocent_lie"]), AstraUI.T_BODY, AstraUI.TEXT))
        if str(post.get("decisive_vote", "")) != "":
            lesson_box.add_child(AstraUI.prose("· " + str(post["decisive_vote"]), AstraUI.T_BODY, AstraUI.TEXT))
        for missed_clue in post.get("missed_clues", []):
            lesson_box.add_child(AstraUI.prose("· 끝내 찾지 못한 기록 — %s (%s)" % [str(missed_clue.get("title", "")), str(missed_clue.get("room", ""))], AstraUI.T_META, AstraUI.MUTED))
        # After a couple of losses the game offers the gentler speed itself
        # rather than waiting for the player to find the settings menu.
        if screen.app.meta.should_offer_assist():
            var assist := AstraUI.button("조사 지원 켜기 (스토리 속도)", AstraUI.GREEN, AstraUI.T_UI, 42)
            assist.pressed.connect(func():
                screen.app.meta.difficulty_mode = "STORY"
                screen.app.meta.save_data()
                assist.text = "조사 지원이 켜졌습니다"
                assist.disabled = true
            )
            lesson_box.add_child(assist)

    var story := str(report.get("story", ""))
    if story != "":
        _body.add_child(AstraUI.prose(story, AstraUI.T_BODY, AstraUI.TEXT))
    if bool(report.get("mission_complete", false)):
        _body.add_child(AstraUI.chip("함선 복구 임무 완료 · 항해 기록에 저장됨", AstraUI.GREEN, 13))
    if outcome == "WIN":
        var fragment: Array = AstraStory.MEMENTOS.get(session.case_id,[])
        if not fragment.is_empty():
            var memory := AstraUI.hbox(16)
            memory.add_child(AstraArt.icon(AstraArt.item(str(fragment[1])),Vector2(110,110)))
            var text := AstraUI.vbox(8)
            text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            text.add_child(AstraUI.section("복구된 기억 · " + str(fragment[0])))
            text.add_child(AstraUI.label(str(fragment[2]),16,AstraUI.TEXT,true))
            memory.add_child(text)
            _body.add_child(memory)
    _body.add_child(AstraUI.section("그날의 기록 대조"))
    for op in session.case_data.get("ops",[]):
        var executor := ""
        for id in session.truth["null_ops"]:
            if str(session.truth["null_ops"][id]) == str(op["id"]):
                executor = session.name_of(str(id))
        _body.add_child(AstraUI.label("%s · %s\n%s %s 명령을 실행했다." % [AstraCaseCatalog.format_time(int(op.get("minute",0)),int(op.get("second",0))),session.room_name(str(op["room"])),AstraJosa.i(executor),str(op["name"])],16,AstraUI.TEXT,true))
    var missed: Array[String] = []
    for clue in session.clues:
        if not bool(clue.get("found",false)) and str(clue.get("kind","")) in ["access_log","op_record","trace"]:
            missed.append(str(clue.get("title","")) + " · " + session.room_name(str(clue.get("room",""))) + " · " + str(clue.get("time","")))
    if not missed.is_empty():
        var reveal := AstraUI.button("놓친 기록 살펴보기",AstraUI.MUTED,14,40)
        var detail := AstraUI.label("\n".join(missed),14,AstraUI.MUTED,true)
        detail.visible = false
        reveal.pressed.connect(func(): detail.visible = not detail.visible)
        _body.add_child(reveal)
        _body.add_child(detail)
    var left := _body

    left.add_child(AstraUI.section("Null의 정체", AstraUI.RED))
    var null_row := AstraUI.hbox(10)
    left.add_child(null_row)
    for null_id in report.get("nulls", []):
        null_row.add_child(_null_card(session, str(null_id)))

    var herring_id := str(report.get("herring", ""))
    if herring_id != "":
        var member := session.npc(herring_id)
        left.add_child(AstraUI.section("거짓말했지만 Null이 아니었던 사람", AstraUI.GOLD))
        var herring := AstraUI.panel(AstraUI.PANEL_2, Color(AstraUI.GOLD, 0.4), 10, 12)
        var herring_box := AstraUI.vbox(4)
        herring.add_child(herring_box)
        herring_box.add_child(AstraUI.label("%s%s" % [member.display_name, " · 조사 중 사정을 밝혀냄" if member.secret_revealed else " · 끝내 숨긴 사정"], 16, member.accent))
        herring_box.add_child(AstraUI.label("“%s”" % str(member.info.get("secret", "")), 14, AstraUI.TEXT, true))
        left.add_child(herring)

    left.add_child(AstraUI.section("진실 대조표"))
    var grid := GridContainer.new()
    grid.columns = 5
    grid.add_theme_constant_override("h_separation", 12)
    grid.add_theme_constant_override("v_separation", 4)
    left.add_child(grid)
    for header in ["이름", "정체", "실제 위치", "진술", "결말"]:
        grid.add_child(AstraUI.label(header, 12, AstraUI.DIM))
    for row in report.get("truth", []):
        var npc_id := str(row.get("id", ""))
        grid.add_child(AstraUI.label(session.name_of(npc_id), 14, AstraCrewCatalog.accent(npc_id)))
        var is_null := str(row.get("role", "")) == "NULL"
        grid.add_child(AstraUI.label("Null · " + str(row.get("op", "")) if is_null else "Crew", 13, AstraUI.RED if is_null else AstraUI.GREEN))
        grid.add_child(AstraUI.label(str(row.get("true_position", "")), 13, AstraUI.TEXT))
        grid.add_child(AstraUI.label(str(row.get("claim_position", "")) + (" (거짓)" if bool(row.get("lie", false)) else ""), 13, AstraUI.GOLD if bool(row.get("lie", false)) else AstraUI.MUTED))
        var status := str(row.get("status", ""))
        var status_text := "생존"
        if status == AstraCrewMember.STATUS_ISOLATED:
            status_text = "장기수면 격리"
        elif status == AstraCrewMember.STATUS_OFFLINE:
            status_text = "생체 신호 두절"
        grid.add_child(AstraUI.label(status_text, 13, AstraUI.MUTED))

    var columns := AstraUI.hbox(18)
    _body.add_child(columns)
    var right := AstraUI.vbox(6)
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    columns.add_child(right)
    var side := AstraUI.vbox(6)
    side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    columns.add_child(side)
    right.add_child(AstraUI.section("평가 · %s / %d점" % [str(report.get("rank","")),int(report.get("total",0))], AstraUI.MUTED))
    var score_grid := GridContainer.new()
    score_grid.columns = 2
    score_grid.add_theme_constant_override("h_separation", 12)
    right.add_child(score_grid)
    for row in report.get("rows", []):
        score_grid.add_child(AstraUI.label(str(row[0]), 13, AstraUI.MUTED))
        var value := int(row[1])
        var value_label := AstraUI.label(("+%d" % value) if value > 0 else str(value), 13, AstraUI.GREEN if value > 0 else (AstraUI.RED if value < 0 else AstraUI.DIM))
        value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        score_grid.add_child(value_label)

    var theory: Dictionary = report.get("theory", {})
    side.add_child(AstraUI.section("추리 보고서", AstraUI.GOLD))
    var suspects: Array = theory.get("suspects", [])
    if suspects.is_empty():
        side.add_child(AstraUI.label("제출하지 않았습니다. 다음에는 투표 전에 실행자로 판단한 사람을 ‘N’으로 표시해 보세요.", 13, AstraUI.MUTED, true))
    else:
        side.add_child(AstraUI.label("%s · %d점" % [str(theory.get("label", "")), int(theory.get("grade", 0))], 16, AstraUI.TEXT))
        side.add_child(AstraUI.label("%d일째 제출 · %s · 적중 %d/2" % [int(theory.get("day", 1)), session.names_of(suspects), int(theory.get("matched", 0))], 13, AstraUI.MUTED, true))

    var change: Dictionary = screen.archive_change
    if not change.is_empty():
        side.add_child(AstraUI.section("아카이브", AstraUI.CYAN))
        side.add_child(AstraUI.label("항해 기록에 이번 조사을 보관했습니다.", 14, AstraUI.TEXT))
        if bool(change.get("new_best", false)):
            side.add_child(AstraUI.chip("이 사건 최고 기록 갱신", AstraUI.GOLD, 13))
        for case_id in change.get("unlocked", []):
            side.add_child(AstraUI.chip("새 사건 해금 · " + screen.app.meta.case_display_name(str(case_id)), AstraUI.GREEN, 13))
        for feature in change.get("new_features", []):
            side.add_child(AstraUI.chip("새 기능 · " + AstraUnlocks.title_of(str(feature)), AstraUI.GOLD, 13))

    var buttons := AstraUI.hbox(10)
    _body.add_child(buttons)
    var archive := AstraUI.button("아카이브로", AstraUI.MUTED, 16, 50)
    archive.pressed.connect(screen.app.show_archive)
    buttons.add_child(archive)
    var retry := AstraUI.button("같은 사건 다시 (새 배치)", AstraUI.CYAN, 16, 50)
    retry.pressed.connect(screen.restart_case)
    buttons.add_child(retry)
    buttons.add_child(AstraUI.spacer())
    var next_id := _next_case(session.case_id)
    if next_id != "":
        var next := AstraUI.button("다음 사건 · %s →" % str(AstraCaseCatalog.get_case(next_id).get("title", "")), AstraUI.GREEN, 16, 50, true)
        next.pressed.connect(screen.start_other_case.bind(next_id))
        buttons.add_child(next)

func _null_card(session: AstraGameSession, npc_id: String) -> Control:
    var member := session.npc(npc_id)
    var card := AstraUI.panel(Color(AstraUI.RED, 0.07), Color(AstraUI.RED, 0.5), 10, 10)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var row := AstraUI.hbox(10)
    card.add_child(row)
    row.add_child(AstraUI.thumb(str(member.info.get("portrait", "")), Vector2(64, 80)))
    var box := AstraUI.vbox(3)
    row.add_child(box)
    box.add_child(AstraUI.label(member.display_name, 20, member.accent))
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_child(AstraUI.label("담당 조작 · " + session.op_name(str(session.truth["null_ops"].get(npc_id, ""))), 13, AstraUI.TEXT, true))
    var claim: Dictionary = session.truth["claims"].get(npc_id, {})
    box.add_child(AstraUI.label("거짓 진술 · " + session.room_name(str(claim.get("position", ""))), 12, AstraUI.MUTED, true))
    var fate := "장기수면 격리됨" if member.status == AstraCrewMember.STATUS_ISOLATED else "끝까지 숨어 있었음"
    box.add_child(AstraUI.label(fate, 13, AstraUI.GREEN if member.status == AstraCrewMember.STATUS_ISOLATED else AstraUI.RED))
    return card

func _next_case(current: String) -> String:
    var meta: AstraMetaProgress = screen.app.meta
    var index := AstraCaseCatalog.CAMPAIGN.find(current)
    for offset in range(1, AstraCaseCatalog.CAMPAIGN.size()):
        var candidate := str(AstraCaseCatalog.CAMPAIGN[(index + offset) % AstraCaseCatalog.CAMPAIGN.size()])
        if meta.is_case_unlocked(candidate) and candidate != current:
            return candidate
    return ""

func _rank_color(rank: String) -> Color:
    match rank:
        "S": return AstraUI.GOLD
        "A": return AstraUI.GREEN
        "B": return AstraUI.CYAN
        "C": return AstraUI.MUTED
    return AstraUI.RED
