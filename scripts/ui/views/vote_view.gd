extends VBoxContainer

# Isolation vote: live tally preview, the selected target, an optional case
# theory built from the player's "Null 의심" marks, and a confirmed vote.

var screen
var _body: VBoxContainer
var _confidence: int = 60

func setup(game_screen) -> void:
    screen = game_screen
    add_theme_constant_override("separation", 10)
    size_flags_vertical = Control.SIZE_EXPAND_FILL
    _body = AstraUI.vbox(12)
    add_child(AstraUI.scroll(_body))
    refresh()

func refresh() -> void:
    var session: AstraGameSession = screen.session
    AstraUI.clear(_body)
    var head := AstraUI.rich(18)
    head.text = "[b]긴급 장기수면 격리 · DAY %d[/b]   [color=#%s]활동 중인 승무원 %d명이 각 1표, 탐사요원이 %d표입니다.[/color]" % [session.day, AstraUI.hex(AstraUI.MUTED), session.eligible_voters().size(), AstraGameSession.PLAYER_VOTE_WEIGHT]
    _body.add_child(head)
    if session.vote_cast:
        _result(session)
    else:
        _ballot(session)

func _ballot(session: AstraGameSession) -> void:
    var selected: String = screen.selected_id()
    var selected_alive := selected in session.eligible_vote_targets()
    var choice := session.ballot_choice()

    var explain := AstraUI.panel(Color(AstraUI.GOLD,0.05),Color(AstraUI.GOLD,0.34),10,12)
    explain.add_child(AstraUI.prose("미선택은 기권이 아닙니다. 먼저 ‘특정 인물’ 또는 ‘기권’을 선택한 뒤 별도로 확정합니다. 단독 최다 득표면 1표라도 격리될 수 있고, 동률이면 아무도 격리하지 않습니다.", AstraUI.T_META, AstraUI.TEXT))
    _body.add_child(explain)

    var statements := session.final_statements()
    if not statements.is_empty():
        var last_panel := AstraUI.panel(Color(0.04, 0.03, 0.06, 0.92), Color(AstraUI.RED, 0.32), 12, 14)
        _body.add_child(last_panel)
        var last_box := AstraUI.vbox(10)
        last_panel.add_child(last_box)
        last_box.add_child(AstraUI.label("마지막 진술", AstraUI.T_META, AstraUI.RED))
        for statement in statements:
            var row := AstraUI.hbox(12)
            last_box.add_child(row)
            row.add_child(AstraUI.thumb(AstraCrewCatalog.portrait_path(str(statement["id"]), "tense"), Vector2(52, 52)))
            var text_box := AstraUI.vbox(2)
            text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            row.add_child(text_box)
            text_box.add_child(AstraUI.label(str(statement["name"]), AstraUI.T_META, AstraCrewCatalog.accent(str(statement["id"]))))
            text_box.add_child(AstraUI.prose("“" + str(statement["text"]) + "”", AstraUI.T_BODY, AstraUI.TEXT))

    var picked_state := str(choice.get("state","unselected"))
    var picked_text := "미선택 · 대상을 고르거나 기권을 선택하세요"
    if picked_state == "target":
        picked_text = session.name_of(str(choice.get("target",""))) + " · 격리 대상에 투표"
    elif picked_state == "abstain":
        picked_text = "○ 기권 · 투표에는 참여하지만 누구도 지목하지 않음"
    _body.add_child(AstraUI.section("내 투표 · " + picked_text, AstraUI.GOLD))

    var buttons := AstraUI.hbox(10)
    _body.add_child(buttons)
    var pick_target := AstraUI.button("%s 선택" % (session.name_of(selected) if selected_alive else "대상 선택 필요"), AstraUI.RED, 15, 48, picked_state == "target" and str(choice.get("target","")) == selected)
    pick_target.disabled = not selected_alive
    pick_target.pressed.connect(func():
        session.select_ballot("target",selected)
        refresh()
    )
    buttons.add_child(pick_target)
    var abstain := AstraUI.button("○ 기권 선택", AstraUI.MUTED, 15, 48, picked_state == "abstain")
    abstain.pressed.connect(func():
        session.select_ballot("abstain")
        refresh()
    )
    buttons.add_child(abstain)

    _body.add_child(_theory_panel(session))
    var confirm := AstraUI.primary_button("선택 검토 후 투표 확정", AstraUI.RED)
    confirm.disabled = picked_state == "unselected"
    confirm.pressed.connect(_confirm)
    _body.add_child(confirm)

func _theory_panel(session: AstraGameSession) -> Control:
    var suspects := session.marked_suspects()
    var panel := AstraUI.panel(Color(AstraUI.GOLD, 0.05), Color(AstraUI.GOLD, 0.35), 12, 12)
    var box := AstraUI.vbox(8)
    panel.add_child(box)
    var submitted := session.theories.any(func(report): return int(report.get("day",0)) == session.day)
    box.add_child(AstraUI.label("나의 결론 (선택) · 투표와 별도 제출", 14, AstraUI.GOLD))
    if submitted:
        box.add_child(AstraUI.label("오늘의 추리 보고서는 제출 완료되었습니다. 이후 메모 변경은 제출본을 바꾸지 않습니다.",13,AstraUI.MUTED,true))
    elif suspects.size() == session.null_count:
        box.add_child(AstraUI.label("현재 의심: " + session.names_of(suspects),13,AstraUI.TEXT,true))
        var choices := AstraUI.hbox(10)
        box.add_child(choices)
        for option in [["판단을 유보한다",30],["가능성이 높다",60],["거의 확신한다",90]]:
            var button := AstraUI.button(str(option[0]),AstraUI.GOLD,14,38,_confidence == int(option[1]))
            button.pressed.connect(func():
                _confidence = int(option[1])
                refresh()
            )
            choices.add_child(button)
        var submit := AstraUI.button("현재 의심 메모로 보고서 제출",AstraUI.GOLD,14,38)
        submit.pressed.connect(func():
            session.submit_theory(session.marked_suspects(),_confidence)
            refresh()
        )
        box.add_child(submit)
    else:
        box.add_child(AstraUI.label("개인 메모에서 Null 의심 대상을 %d명 표시하면 제출할 수 있습니다. 투표 선택은 자동 제출되지 않습니다." % session.null_count, 13, AstraUI.MUTED, true))
    return panel

func _tally_bars(session: AstraGameSession, tally: Dictionary, highlight: String) -> Control:
    var box := AstraUI.vbox(5)
    var ids: Array = tally.keys()
    ids.sort_custom(func(a, b): return int(tally[a]) > int(tally[b]))
    var top := 1
    for npc_id in ids:
        top = maxi(top, int(tally[npc_id]))
    if ids.is_empty():
        box.add_child(AstraUI.label("아직 뚜렷한 의향이 없습니다.", 13, AstraUI.DIM))
    for npc_id in ids:
        var row := AstraUI.hbox(8)
        var name_label := AstraUI.label(session.name_of(str(npc_id)), 14, AstraCrewCatalog.accent(str(npc_id)))
        name_label.custom_minimum_size = Vector2(70, 0)
        row.add_child(name_label)
        var bar := AstraUI.meter(float(tally[npc_id]) / float(maxi(top, 4)), AstraUI.RED if str(npc_id) == highlight else AstraUI.GOLD, 12)
        row.add_child(bar)
        row.add_child(AstraUI.label("%d표" % int(tally[npc_id]), 14, AstraUI.TEXT))
        box.add_child(row)
    return box

func _confirm() -> void:
    var session: AstraGameSession = screen.session
    var choice := session.ballot_choice()
    var state := str(choice.get("state","unselected"))
    if state == "unselected":
        return
    var picked := "기권" if state == "abstain" else session.name_of(str(choice.get("target",""))) + "에게 투표"
    screen.confirm("투표를 확정할까요?", picked + "합니다. 확정 후에는 바꿀 수 없습니다. 추리 보고서는 투표와 별개입니다.", "이 선택으로 확정", func():
        var result := session.confirm_ballot()
        if not bool(result.get("ok",false)):
            refresh()
            return
        var vote: Dictionary = result.get("result",{})
        screen.fx.play("vote")
        screen.fx.flash(AstraUI.RED,0.14)
        var isolated := str(vote.get("isolated",""))
        if isolated != "":
            screen.fx.banner("장기수면 격리 · " + session.name_of(isolated), "%d표로 포드 이동이 결정됐다." % int(vote.get("top",0)), AstraUI.RED, 1.2)
        else:
            screen.fx.banner("장기수면 격리 없음", session.vote_result_text(), AstraUI.GOLD, 1.2)
        refresh()
    )

# Ballots are opened one at a time. The tally was already decided when the vote
# was cast — nothing here changes the outcome — but reading "Noa → Jun" six
# times in a row is the part that hurts, and 0.3.1 printed it as a single line
# of comma-separated text (§19).
func _count_panel(session: AstraGameSession, vote: Dictionary) -> Control:
    var intentions: Dictionary = vote.get("intentions", {})
    var reasons: Dictionary = vote.get("vote_reasons", {})
    var voters: Array = []
    for voter in session.active_roster():
        if intentions.has(voter):
            voters.append(voter)
    var player_target := str(vote.get("player_target", ""))
    var panel := AstraUI.panel(AstraUI.PANEL_2, Color(AstraUI.GOLD, 0.35), 12, 14)
    var box := AstraUI.vbox(8)
    panel.add_child(box)
    var head := AstraUI.hbox(8)
    box.add_child(head)
    head.add_child(AstraUI.label("개표", AstraUI.T_META, AstraUI.GOLD))
    # Spell the arithmetic out. The investigator's ballot counts double, and in
    # 0.3.1 that was stated once on the ballot screen and then never again — so
    # a five-person crew producing a seven-vote tally looked like a bug.
    var total := voters.size() + (AstraGameSession.PLAYER_VOTE_WEIGHT if player_target != "" else 0)
    head.add_child(AstraUI.label(
        "승무원 %d표 + 탐사요원 %d표 = 총 %d표" % [voters.size(), AstraGameSession.PLAYER_VOTE_WEIGHT if player_target != "" else 0, total],
        AstraUI.T_META, AstraUI.MUTED))
    var rows := AstraUI.vbox(4)
    box.add_child(rows)
    var next := AstraUI.button("한 표 열기  ▸", AstraUI.GOLD, AstraUI.T_UI, 42, true)
    box.add_child(next)

    var ballots: Array = session.vote_ballots()

    var index := [0]
    var reveal := func() -> void:
        if index[0] >= ballots.size():
            return
        var ballot: Dictionary = ballots[index[0]]
        index[0] += 1
        var voter := str(ballot["voter"])
        var picked := str(ballot["target"])
        var row := AstraUI.hbox(8)
        if voter == "player":
            row.add_child(AstraUI.label("탐사요원", AstraUI.T_BODY, AstraUI.CYAN))
        else:
            row.add_child(AstraUI.crew_dot(voter, 26))
            var who := AstraUI.label(session.name_of(voter), AstraUI.T_BODY, AstraCrewCatalog.accent(voter))
            who.custom_minimum_size.x = 72
            row.add_child(who)
        row.add_child(AstraUI.label("→", AstraUI.T_BODY, AstraUI.DIM))
        if picked == "":
            row.add_child(AstraUI.label("기권", AstraUI.T_BODY, AstraUI.MUTED))
        else:
            row.add_child(AstraUI.crew_dot(picked, 26))
            row.add_child(AstraUI.label(session.name_of(picked), AstraUI.T_BODY, AstraCrewCatalog.accent(picked)))
        if int(ballot["weight"]) > 1:
            row.add_child(AstraUI.chip("%d표" % int(ballot["weight"]), AstraUI.CYAN, AstraUI.T_META - 2))
        rows.add_child(row)
        if voter != "player" and reasons.has(voter):
            var reason := AstraUI.label("이유 · " + str(reasons[voter]), AstraUI.T_META - 1, AstraUI.DIM, true)
            rows.add_child(reason)
            for raw_change in vote.get("vote_changes",[]):
                var change: Dictionary = raw_change
                if str(change.get("voter","")) != voter:
                    continue
                var before := str(change.get("before",""))
                var after := str(change.get("after",""))
                var before_text := "기권" if before == "" else session.name_of(before)
                var after_text := "기권" if after == "" else session.name_of(after)
                rows.add_child(AstraUI.label(
                    "지난 투표와 달라짐 · %s → %s · %s" % [before_text,after_text,str(change.get("reason","새 근거를 반영함"))],
                    AstraUI.T_META - 2,AstraUI.MUTED,true
                ))
                break
        AstraUI.fade_in(row, 0.14)
        screen.fx.play("vote")
        if index[0] >= ballots.size():
            next.text = "개표 완료"
            next.disabled = true
    next.pressed.connect(reveal)
    if ballots.is_empty():
        next.visible = false
        box.add_child(AstraUI.label("표가 기록되지 않았습니다.", AstraUI.T_META, AstraUI.DIM))
    return panel

func _result(session: AstraGameSession) -> void:
    var vote := session.last_vote
    var isolated := str(vote.get("isolated", ""))
    var panel := AstraUI.panel(AstraUI.PANEL_2, AstraUI.RED if isolated != "" else AstraUI.GOLD, 12, 16)
    _body.add_child(panel)
    var box := AstraUI.vbox(8)
    panel.add_child(box)
    if isolated != "":
        var member := session.npc(isolated)
        var row := AstraUI.hbox(14)
        box.add_child(row)
        row.add_child(AstraUI.thumb(str(member.info.get("portrait", "")), Vector2(84, 105)))
        var info := AstraUI.vbox(4)
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(info)
        info.add_child(AstraUI.label("장기수면 격리 결정", 13, AstraUI.DIM))
        info.add_child(AstraUI.label("%s · %d표" % [member.display_name, int(vote.get("top", 0))], 26, member.accent))
        info.add_child(AstraUI.label(str(vote.get("isolation_text", "보안 절차에 따라 장기수면 포드로 이동합니다.")), 15, AstraUI.TEXT, true))
        info.add_child(AstraUI.label("“%s”" % str(vote.get("last_words", "")), 16, AstraUI.TEXT, true))
        box.add_child(AstraUI.label("정체는 공개되지 않습니다.%s" % (" 감사관이 오늘 밤 생체 기록을 감사합니다." if session.protocol == "AUDITOR" else ""), 13, AstraUI.MUTED))
    else:
        box.add_child(AstraUI.label("장기수면 격리 없음", 26, AstraUI.GOLD))
        box.add_child(AstraUI.label("동률이거나 충분한 근거가 없어 아무도 포드로 이동하지 않았습니다.", 15, AstraUI.TEXT))
    var counts := session.vote_counts()
    _body.add_child(AstraUI.prose("참여 가능 %d명 · 제출 %d명 · 대상 투표 %d명 · 기권 %d명 · 미투표 %d명" % [counts.eligible,counts.submitted,counts.targets,counts.abstained,counts.missing], AstraUI.T_META, AstraUI.MUTED))
    _body.add_child(_count_panel(session, vote))
    if not vote.get("aftermath",[]).is_empty():
        _body.add_child(AstraUI.section("격리 이후", AstraUI.VIOLET))
        for beat in vote.get("aftermath",[]):
            var speaker := str(beat.get("speaker",""))
            var prefix := (session.name_of(speaker) + " · ") if speaker != "" and speaker in session.roster else ""
            _body.add_child(AstraUI.prose(prefix + str(beat.get("text","")), AstraUI.T_BODY, AstraUI.TEXT))
    _body.add_child(AstraUI.section("최종 득표 (탐사요원 표 포함)", AstraUI.GOLD))
    _body.add_child(_tally_bars(session, vote.get("tally", {}), str(vote.get("player_target", ""))))
    if session.outcome != "":
        _body.add_child(AstraUI.label("사건의 결말이 정해졌습니다. 아래 버튼으로 결과를 확인하세요.", 16, AstraUI.GOLD, true))
    else:
        _body.add_child(AstraUI.label("밤이 오면 Null이 움직입니다. 아래 버튼으로 밤으로 넘어가세요.", 15, AstraUI.NIGHT, true))
