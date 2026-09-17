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
    head.text = "[b]격리 투표 · DAY %d[/b]   [color=#%s]조사관의 표는 %d표로 계산됩니다[/color]" % [session.day, AstraUI.hex(AstraUI.MUTED), AstraGameSession.PLAYER_VOTE_WEIGHT]
    _body.add_child(head)
    if session.vote_cast:
        _result(session)
    else:
        _ballot(session)

func _ballot(session: AstraGameSession) -> void:
    var target: String = screen.selected_id()
    var target_alive := session.is_alive(target)
    _body.add_child(AstraUI.section("현재 투표 의향 (조사관 표 제외)", AstraUI.GOLD))
    _body.add_child(_tally_bars(session, session.vote_tally(""), target if target_alive else ""))

    var target_panel := AstraUI.panel(AstraUI.PANEL_2, AstraUI.RED if target_alive else AstraUI.BORDER, 12, 14)
    _body.add_child(target_panel)
    var row := AstraUI.hbox(14)
    target_panel.add_child(row)
    if target_alive:
        var member := session.npc(target)
        row.add_child(AstraUI.thumb(str(member.info.get("portrait", "")), Vector2(72, 90)))
        var info := AstraUI.vbox(4)
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(info)
        info.add_child(AstraUI.label("격리 대상", 13, AstraUI.DIM))
        info.add_child(AstraUI.label("%s · %s" % [member.display_name, member.job], 22, member.accent))
        var preview := session.vote_tally(target)
        info.add_child(AstraUI.label("내 표를 더하면 %d표 · 여론 의심도 %d%%" % [int(preview.get(target, 0)), int(session.crowd_suspicion(target) * 100.0)], 14, AstraUI.MUTED))
    else:
        row.add_child(AstraUI.label("위쪽 승무원 명단에서 격리할 사람을 선택하세요. (숫자키 1~8)", 16, AstraUI.MUTED, true))

    _body.add_child(_theory_panel(session))

    var buttons := AstraUI.hbox(10)
    _body.add_child(buttons)
    var abstain := AstraUI.button("기권 (승무원 표로만 결정)", AstraUI.MUTED, 15, 50)
    abstain.pressed.connect(_confirm.bind(""))
    buttons.add_child(abstain)
    buttons.add_child(AstraUI.spacer())
    var vote := AstraUI.button("%s 격리 투표" % (session.name_of(target) if target_alive else "대상 선택 필요"), AstraUI.RED, 17, 50, true)
    vote.custom_minimum_size = Vector2(300, 50)
    vote.disabled = not target_alive
    vote.pressed.connect(_confirm.bind(target))
    buttons.add_child(vote)

func _theory_panel(session: AstraGameSession) -> Control:
    var suspects := session.marked_suspects()
    var panel := AstraUI.panel(Color(AstraUI.GOLD, 0.05), Color(AstraUI.GOLD, 0.35), 12, 12)
    var box := AstraUI.vbox(8)
    panel.add_child(box)
    box.add_child(AstraUI.label("추리 보고서 (선택) · 사건이 끝나면 채점되어 점수에 반영됩니다", 14, AstraUI.GOLD))
    if suspects.size() == 2:
        var chips := AstraUI.hbox(6)
        box.add_child(chips)
        chips.add_child(AstraUI.label("Null로 지목:", 14, AstraUI.MUTED))
        for npc_id in suspects:
            chips.add_child(AstraUI.chip(session.name_of(str(npc_id)), AstraCrewCatalog.accent(str(npc_id)), 14))
        var slider_row := AstraUI.hbox(10)
        box.add_child(slider_row)
        slider_row.add_child(AstraUI.label("확신도", 14, AstraUI.MUTED))
        var slider := HSlider.new()
        slider.min_value = 0
        slider.max_value = 100
        slider.step = 10
        slider.value = _confidence
        slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        slider_row.add_child(slider)
        var value_label := AstraUI.label("%d%%" % _confidence, 14, AstraUI.TEXT)
        slider_row.add_child(value_label)
        slider.value_changed.connect(func(value: float):
            _confidence = int(value)
            value_label.text = "%d%%" % _confidence
        )
        box.add_child(AstraUI.label("두 명 모두 맞히고 확신도가 높으면 가산점, 둘 다 틀렸는데 확신도가 높으면 감점됩니다. 투표할 때 함께 제출됩니다.", 12, AstraUI.DIM, true))
    else:
        box.add_child(AstraUI.label("명단 오른쪽의 표시 버튼으로 정확히 두 명을 ‘N (Null 의심)’으로 표시하면 투표와 함께 보고서가 제출됩니다. 현재 %d명 표시됨." % suspects.size(), 13, AstraUI.MUTED, true))
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

func _confirm(target: String) -> void:
    var session: AstraGameSession = screen.session
    var body := ""
    if target == "":
        body = "기권하면 승무원들의 표만으로 격리가 결정됩니다. 동률이면 아무도 격리되지 않습니다."
    else:
        body = AstraJosa.eul(session.name_of(target)) + " 격리합니다. 되돌릴 수 없습니다. 격리된 사람의 정체는 사건이 끝날 때까지 공개되지 않습니다."
    screen.confirm("투표를 확정할까요?", body, "확정", func():
        _cast(target)
    )

func _cast(target: String) -> void:
    var session: AstraGameSession = screen.session
    var suspects := session.marked_suspects()
    var result := session.cast_vote(target, suspects if suspects.size() == 2 else [], _confidence)
    if not bool(result.get("ok", false)):
        return
    var vote: Dictionary = result.get("result", {})
    screen.fx.play("vote")
    screen.fx.flash(AstraUI.RED, 0.14)
    screen.fx.shake(screen, 6.0)
    var isolated := str(vote.get("isolated", ""))
    if isolated != "":
        screen.fx.banner("격리 · " + session.name_of(isolated), "%d표로 격리가 결정됐다." % int(vote.get("top", 0)), AstraUI.RED, 1.2)
    else:
        screen.fx.banner("격리 무산", "표가 갈려 아무도 격리되지 않았다.", AstraUI.GOLD, 1.2)

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
        info.add_child(AstraUI.label("격리 결정", 13, AstraUI.DIM))
        info.add_child(AstraUI.label("%s · %d표" % [member.display_name, int(vote.get("top", 0))], 26, member.accent))
        info.add_child(AstraUI.label("“%s”" % str(vote.get("last_words", "")), 16, AstraUI.TEXT, true))
        box.add_child(AstraUI.label("정체는 공개되지 않습니다.%s" % (" 감사관이 오늘 밤 생체 기록을 감사합니다." if session.protocol == "AUDITOR" else ""), 13, AstraUI.MUTED))
    else:
        box.add_child(AstraUI.label("격리 무산", 26, AstraUI.GOLD))
        box.add_child(AstraUI.label("표가 동률로 갈려 아무도 격리되지 않았습니다.", 15, AstraUI.TEXT))
    _body.add_child(AstraUI.section("최종 득표 (조사관 표 포함)", AstraUI.GOLD))
    _body.add_child(_tally_bars(session, vote.get("tally", {}), str(vote.get("player_target", ""))))
    var intentions: Dictionary = vote.get("intentions", {})
    var lines: Array = []
    for voter in AstraCrewCatalog.ORDER:
        if intentions.has(voter):
            lines.append("%s → %s" % [session.name_of(voter), session.name_of(str(intentions[voter]))])
    _body.add_child(AstraUI.label("누가 누구에게: " + " · ".join(PackedStringArray(lines)), 13, AstraUI.MUTED, true))
    if session.outcome != "":
        _body.add_child(AstraUI.label("사건의 결말이 정해졌습니다. 아래 버튼으로 결과를 확인하세요.", 16, AstraUI.GOLD, true))
    else:
        _body.add_child(AstraUI.label("밤이 오면 Null이 움직입니다. 아래 버튼으로 밤으로 넘어가세요.", 15, AstraUI.NIGHT, true))
