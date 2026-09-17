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
    var rank_box := AstraUI.vbox(0)
    rank_box.alignment = BoxContainer.ALIGNMENT_CENTER
    hero_row.add_child(rank_box)
    var rank_label := AstraUI.label(str(report.get("rank", "D")), 64, _rank_color(str(report.get("rank", "D"))))
    rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    rank_box.add_child(rank_label)
    var total_label := AstraUI.label("%d점" % int(report.get("total", 0)), 16, AstraUI.TEXT)
    total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    rank_box.add_child(total_label)

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
            status_text = "격리"
        elif status == AstraCrewMember.STATUS_OFFLINE:
            status_text = "습격당함"
        grid.add_child(AstraUI.label(status_text, 13, AstraUI.MUTED))

    var columns := AstraUI.hbox(18)
    _body.add_child(columns)
    var right := AstraUI.vbox(6)
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    columns.add_child(right)
    var side := AstraUI.vbox(6)
    side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    columns.add_child(side)
    right.add_child(AstraUI.section("점수", AstraUI.GOLD))
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
        side.add_child(AstraUI.label("제출하지 않았습니다. 다음에는 투표 전에 두 명을 ‘N’으로 표시해 보세요.", 13, AstraUI.MUTED, true))
    else:
        side.add_child(AstraUI.label("%s · %d점" % [str(theory.get("label", "")), int(theory.get("grade", 0))], 16, AstraUI.TEXT))
        side.add_child(AstraUI.label("DAY %d 제출 · %s · 적중 %d/2 · 확신도 %d%%" % [int(theory.get("day", 1)), session.names_of(suspects), int(theory.get("matched", 0)), int(theory.get("confidence", 0))], 13, AstraUI.MUTED, true))

    var change: Dictionary = screen.archive_change
    if not change.is_empty():
        side.add_child(AstraUI.section("아카이브", AstraUI.CYAN))
        side.add_child(AstraUI.label("통찰 +%d · %s" % [int(change.get("insight_gain", 0)), screen.app.meta.archive_rank()], 14, AstraUI.TEXT))
        if bool(change.get("new_best", false)):
            side.add_child(AstraUI.chip("이 사건 최고 기록 갱신", AstraUI.GOLD, 13))
        for case_id in change.get("unlocked", []):
            side.add_child(AstraUI.chip("새 사건 해금 · " + screen.app.meta.case_display_name(str(case_id)), AstraUI.GREEN, 13))

    var buttons := AstraUI.hbox(10)
    _body.add_child(buttons)
    var archive := AstraUI.button("아카이브로", AstraUI.MUTED, 16, 50)
    archive.pressed.connect(screen.exit_to_title)
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
    var fate := "격리됨" if member.status == AstraCrewMember.STATUS_ISOLATED else "끝까지 숨어 있었음"
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
