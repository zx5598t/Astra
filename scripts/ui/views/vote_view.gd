extends VBoxContainer

var screen
var _body: VBoxContainer
var _confidence := 60

func setup(game_screen) -> void:
    screen = game_screen
    size_flags_vertical = Control.SIZE_EXPAND_FILL
    _body = AstraUI.vbox(12)
    add_child(AstraUI.scroll(_body))
    refresh()

func refresh() -> void:
    AstraUI.clear(_body)
    var s: AstraGameSession = screen.session
    if s.vote_cast:
        _result(s)
        return
    if not s.flags.get("ballot_error_058",[]).is_empty():
        _body.add_child(AstraUI.prose("입력 오류 · 명부와 투표 기록이 맞지 않아 확정하지 않았습니다. 기권으로 처리되지 않습니다.",17,AstraUI.RED))
    _body.add_child(AstraUI.prose("공개된 근거로 위험을 판단해 격리 여부를 정합니다. 동료 %d명은 각 1표, 탐사요원 1명은 %d표입니다. 탐사요원은 격리 대상이 아닙니다." % [s.eligible_voters().size(),s.PLAYER_VOTE_WEIGHT],18,AstraUI.TEXT))
    _body.add_child(AstraUI.prose("단독 최다 득표자는 사건 종료까지 행동·회의·투표에서 제외됩니다. 최소 득표수 조건은 없어 1표로도 격리될 수 있습니다. 동률이나 전원 기권이면 격리하지 않습니다.",16,AstraUI.MUTED))
    var choice := s.ballot_choice()
    var grid := GridContainer.new()
    grid.columns = 3
    grid.add_theme_constant_override("h_separation",8)
    grid.add_theme_constant_override("v_separation",6)
    _body.add_child(grid)
    for id in s.eligible_vote_targets():
        var who := str(id)
        var button := AstraUI.button(s.name_of(who)+" · 대상 선택",AstraUI.RED,16,44,str(choice.get("target","")) == who)
        button.pressed.connect(func(): s.select_ballot("target",who))
        grid.add_child(button)
    var abstain := AstraUI.button("○ 기권 선택",AstraUI.MUTED,16,44,str(choice.get("state","")) == "abstain")
    abstain.pressed.connect(func(): s.select_ballot("abstain"))
    grid.add_child(abstain)
    var picked := str(choice.get("state","unselected"))
    var caption := "미선택 · 대상을 고르거나 기권을 선택하세요"
    if picked == "target": caption = s.name_of(str(choice["target"]))+" · 격리 대상에 투표"
    elif picked == "abstain": caption = "○ 기권 · 참여하지만 누구도 지목하지 않음"
    _body.add_child(AstraUI.prose("내 선택: "+caption,20,AstraUI.GOLD))
    _body.add_child(_theory_panel(s))
    var confirm := AstraUI.button("선택 검토 후 투표 확정",AstraUI.RED,18,48,true)
    confirm.disabled = picked == "unselected"
    confirm.pressed.connect(_confirm)
    _body.add_child(confirm)

func _theory_panel(s: AstraGameSession) -> Control:
    var panel := AstraUI.panel(AstraUI.PANEL_2,AstraUI.BORDER,10,12)
    var box := AstraUI.vbox(6)
    panel.add_child(box)
    var submitted := s.theories.any(func(report): return int(report.get("day",0)) == s.day)
    box.add_child(AstraUI.prose("추리 보고서 (선택) · "+("제출 완료. 메모를 바꿔도 제출본은 유지됩니다." if submitted else "사건 종료 후 채점합니다. 투표와 별도로 제출하세요."),16,AstraUI.GOLD))
    var suspects := s.marked_suspects()
    box.add_child(AstraUI.prose("현재 개인 메모의 의심 대상: "+(s.names_of(suspects) if not suspects.is_empty() else "없음"),15,AstraUI.MUTED))
    if not submitted:
        var confidence_row := AstraUI.hbox(6)
        box.add_child(confidence_row)
        confidence_row.add_child(AstraUI.label("보고서 확신도",15,AstraUI.MUTED))
        for value in [30,60,90]:
            var button := AstraUI.button("%d%%" % value,AstraUI.GOLD,14,32,_confidence == value)
            button.pressed.connect(func(): _confidence = value; refresh())
            confidence_row.add_child(button)
    var submit := AstraUI.button("현재 의심 메모로 보고서 제출",AstraUI.GOLD,15,38)
    submit.disabled = submitted or suspects.size() != s.null_count
    submit.tooltip_text = "의심 대상 %d명을 개인 메모에 표시하면 제출할 수 있습니다. 투표나 공개 발언은 발생하지 않습니다." % s.null_count
    submit.pressed.connect(func(): s.submit_theory(s.marked_suspects(),_confidence))
    box.add_child(submit)
    return panel

func _confirm() -> void:
    var s: AstraGameSession = screen.session
    var choice := s.ballot_choice()
    if str(choice.get("state","")) == "unselected": return
    var picked := "기권" if str(choice.get("state","")) == "abstain" else s.name_of(str(choice["target"]))+"에게 투표"
    screen.confirm("투표를 확정할까요?",picked+"합니다. 확정 후에는 바꿀 수 없습니다. 개인 메모는 자동 제출되지 않습니다.","이 선택으로 확정",func():
        if s.confirm_ballot().get("ok",false): screen.fx.play("vote")
    )

func consume_advance() -> bool:
    # Dialogue advance keys never choose or submit a ballot.
    return not screen.session.vote_cast

func _result(s: AstraGameSession) -> void:
    var vote := s.last_vote
    var isolated := str(vote.get("isolated",""))
    _body.add_child(AstraUI.label("격리 없음" if isolated == "" else s.name_of(isolated)+" · 장기수면 격리",24,AstraUI.GOLD))
    _body.add_child(AstraUI.prose(s.vote_result_text(),17,AstraUI.TEXT))
    var counts := s.vote_counts()
    _body.add_child(AstraUI.prose("참여 가능 %d명 = 제출 %d명 + 미투표 %d명 · 대상 투표 %d명 / 기권 %d명 · 유효표 %d표" % [counts.eligible,counts.submitted,counts.missing,counts.targets,counts.abstained,counts.valid_weight],16,AstraUI.MUTED))
    for ballot in s.vote_ballots():
        var row := AstraUI.hbox(8)
        _body.add_child(row)
        var voter := str(ballot["voter"])
        if voter != "player": row.add_child(AstraUI.crew_dot(voter,28))
        row.add_child(AstraUI.label("탐사요원" if voter == "player" else s.name_of(voter),17,AstraUI.TEXT))
        row.add_child(AstraUI.label("→",17,AstraUI.DIM))
        var state := str(ballot.get("state","error"))
        var target := str(ballot.get("target",""))
        if state == "target" and target in s.roster:
            row.add_child(AstraUI.crew_dot(target,28))
            row.add_child(AstraUI.label(s.name_of(target),17,AstraUI.TEXT))
        else:
            row.add_child(AstraUI.label({"abstain":"○ 기권","unselected":"미투표"}.get(state,"입력 오류 · 기록 확인 필요"),17,AstraUI.MUTED))
        var reason := str(ballot.get("reason",vote.get("vote_reasons",{}).get(voter,"")))
        if reason != "": _body.add_child(AstraUI.prose("이유 · "+reason,14,AstraUI.MUTED))
    for id in vote.get("tally",{}):
        _body.add_child(AstraUI.label(s.name_of(str(id))+" · %d표" % int(vote["tally"][id]),17,AstraUI.GOLD))
