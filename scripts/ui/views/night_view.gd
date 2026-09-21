extends VBoxContainer

# Night: protect one person or put a drone on one room. Afterwards the view
# shows what the night brought.

var screen
var _body: VBoxContainer

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
    var head := AstraUI.rich(20)
    head.text = "[b][color=#%s]밤 · DAY %d[/color][/b]" % [AstraUI.hex(AstraUI.NIGHT), session.day]
    _body.add_child(head)
    if session.night_done:
        _report(session)
        return
    var first_night := session.case_id == "ECHO_WARD" and session.day <= 1
    if first_night:
        var help := AstraUI.panel(Color(AstraUI.NIGHT, 0.08), Color(AstraUI.CYAN, 0.45), 10, 12)
        var help_box := AstraUI.vbox(5)
        help.add_child(help_box)
        help_box.add_child(AstraUI.label("처음 맞는 밤", 17, AstraUI.CYAN))
        help_box.add_child(AstraUI.label("밤에는 Null이 움직일 수 있습니다. 탐사요원은 오늘 한 가지 행동만 고릅니다.", 14, AstraUI.TEXT, true))
        help_box.add_child(AstraUI.label("사람 보호 · 습격을 막습니다.    기록 백업 · 원본이 지워져도 사본을 남깁니다.", 13, AstraUI.MUTED, true))
        _body.add_child(help)
    else:
        _body.add_child(AstraUI.label("밤에는 한 가지 행동만 고를 수 있습니다. 보호·감시·기록 보존 중 현재 필요한 행동을 선택하세요.", 16, AstraUI.TEXT, true))
    var row := AstraUI.hbox(12)
    row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _body.add_child(row)
    row.add_child(_protect_card(session))
    if not session.night_options().get("secure", []).is_empty():
        row.add_child(_secure_card(session))
    var options := AstraUI.hbox(10)
    _body.add_child(options)
    var backup := AstraUI.button("기록 백업하기…",AstraUI.CYAN,16,48,true)
    backup.tooltip_text = "오늘 밤 원본이 지워져도 사본이 남습니다."
    backup.pressed.connect(_backup)
    options.add_child(backup)
    if not session.night_options().get("rest", []).is_empty():
        var rest := AstraUI.button("휴식한다",AstraUI.MUTED,16,48)
        rest.tooltip_text = "밖을 지키지 못하지만 내일 대화를 조금 더 이어 갈 수 있다."
        rest.pressed.connect(_choose.bind("rest","self"))
        options.add_child(rest)
    if session.protocol == "AUDITOR":
        _body.add_child(AstraUI.label("감사관 · 오늘 격리된 사람이 있다면 밤사이 생체 기록을 자동으로 감사합니다.", 13, AstraUI.GOLD, true))
    if session.flags.has("patrol"):
        _body.add_child(AstraUI.label(AstraJosa.i(session.name_of(str(session.flags["patrol"]))) + " 오늘 밤 따로 순찰을 돕니다.", 13, AstraUI.MUTED, true))

func _protect_card(session: AstraGameSession) -> Control:
    var card := AstraUI.panel(Color(AstraUI.GREEN, 0.06), Color(AstraUI.GREEN, 0.45), 12, 14)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var box := AstraUI.vbox(8)
    card.add_child(box)
    box.add_child(AstraUI.label("사람 보호", 22, AstraUI.GREEN))
    box.add_child(AstraUI.label("오늘 밤 한 사람의 선실 근처를 지킵니다. 그 사람이 습격 대상이면 공격을 막습니다.", 14, AstraUI.MUTED, true))
    var target: String = screen.selected_id()
    var ok := session.is_alive(target)
    if ok:
        var member := session.npc(target)
        var who := AstraUI.hbox(10)
        who.add_child(AstraUI.thumb(str(member.info.get("portrait", "")), Vector2(56, 70)))
        var info := AstraUI.vbox(2)
        info.add_child(AstraUI.label(member.display_name, 18, member.accent))
        info.add_child(AstraUI.label(member.mood_label(),13,AstraUI.MUTED))
        who.add_child(info)
        box.add_child(who)
    else:
        box.add_child(AstraUI.label("위쪽 승무원 명단에서 보호할 사람을 선택하세요.", 14, AstraUI.GOLD, true))
    box.add_child(AstraUI.spacer(false))
    var button := AstraUI.button("%s 보호하기" % (session.name_of(target) if ok else "대상 선택 필요"), AstraUI.GREEN, 16, 48, true)
    button.disabled = not ok
    button.pressed.connect(_choose.bind("protect", target))
    box.add_child(button)
    box.add_child(AstraUI.label("팁: Null은 자기를 강하게 의심하는 사람이나 탐사요원이 신뢰하는 사람을 노리는 경향이 있습니다.", 12, AstraUI.DIM, true))
    return card

func _secure_card(session: AstraGameSession) -> Control:
    var card := AstraUI.panel(Color(AstraUI.NIGHT, 0.06), Color(AstraUI.NIGHT, 0.45), 12, 14)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var box := AstraUI.vbox(8)
    card.add_child(box)
    box.add_child(AstraUI.label("감시", 22, AstraUI.NIGHT))
    box.add_child(AstraUI.label("한 구역에 감시 드론을 둡니다. 그 구역의 흔적 삭제를 막고, 접근한 사람의 특징을 기록합니다.", 14, AstraUI.MUTED, true))
    var options: Array = session.night_options().get("secure", [])
    if options.is_empty():
        box.add_child(AstraUI.label("지킬 흔적이 남은 구역이 없습니다.", 14, AstraUI.DIM))
    for room_id in options:
        var button := AstraUI.button("%s 감시" % session.room_name(str(room_id)), AstraUI.NIGHT, 15, 42)
        button.pressed.connect(_choose.bind("secure", str(room_id)))
        box.add_child(button)
    return card

func _choose(kind: String, target: String) -> void:
    var session: AstraGameSession = screen.session
    var result := session.choose_night_action(kind, target)
    if not bool(result.get("ok", false)):
        return
    var night: Dictionary = result.get("result", {})
    screen.fx.play("night")
    if bool(night.get("protected", false)):
        screen.fx.play("save")
        screen.fx.banner("습격 저지", "누군가 %s의 선실에 침입하려다 달아났다." % session.name_of(str(night.get("victim", ""))), AstraUI.GREEN, 1.3)
    elif str(night.get("victim", "")) != "":
        screen.fx.play("kill")
        screen.fx.flash(AstraUI.RED, 0.22, 0.6)
        screen.fx.banner("신호 두절", "%s의 생체 신호가 끊겼다." % session.name_of(str(night.get("victim", ""))), AstraUI.RED, 1.4)
    if bool(night.get("blocked_tamper", false)):
        screen.fx.toast("밤사이 기록을 지켰습니다. 자세한 내용은 아침 보고에 남았습니다.", AstraUI.NIGHT)

func _report(session: AstraGameSession) -> void:
    var panel := AstraUI.panel(Color(AstraUI.NIGHT, 0.07), Color(AstraUI.NIGHT, 0.5), 12, 16)
    _body.add_child(panel)
    var box := AstraUI.vbox(8)
    panel.add_child(box)
    box.add_child(AstraUI.label("밤사이 일어난 일", 16, AstraUI.NIGHT))
    for line in session.morning_report:
        box.add_child(AstraUI.label("▸ " + str(line), 17, AstraUI.TEXT, true))
    var clues: Array = session.night_result.get("clues", [])
    for clue in clues:
        var card := AstraClueCard.new()
        card.setup(session, clue, false)
        _body.add_child(card)
    _add_social_feedback(session)
    if session.outcome != "":
        _body.add_child(AstraUI.label("사건의 결말이 정해졌습니다. 아래 버튼으로 결과를 확인하세요.", 16, AstraUI.GOLD, true))
    else:
        _body.add_child(AstraUI.label("아래 버튼을 눌러 다음 날 아침으로 넘어가세요.", 15, AstraUI.MUTED))


func _add_social_feedback(session: AstraGameSession) -> void:
    var summary := session.night_feedback_summary()
    var relationships: Array = summary.get("relationship_changes",[])
    var consequences: Array = summary.get("consequences",[])
    if relationships.is_empty() and consequences.is_empty():
        return
    var panel := AstraUI.panel(Color(AstraUI.CYAN,0.035),Color(AstraUI.CYAN,0.24),10,12)
    _body.add_child(panel)
    var box := AstraUI.vbox(5)
    panel.add_child(box)
    box.add_child(AstraUI.label("오늘 남은 여파",AstraUI.T_META,AstraUI.CYAN))
    for entry in relationships:
        box.add_child(AstraUI.label(str(entry.get("pair","")),AstraUI.T_UI,AstraUI.TEXT))
        box.add_child(AstraUI.prose("· " + str(entry.get("text","")),AstraUI.T_META,AstraUI.MUTED))
    for entry in consequences:
        var who := str(entry.get("character",""))
        var prefix := (who + " · ") if who != "" else ""
        box.add_child(AstraUI.prose("· " + prefix + str(entry.get("text","")),AstraUI.T_META,AstraUI.MUTED))

func _backup() -> void:
    var box := AstraUI.vbox(8)
    box.add_child(AstraUI.label("구역의 원본을 보관하고 읽지 못했던 기록을 복원합니다. 사람을 보호하거나 침입자를 추적하지는 못합니다.",15,AstraUI.MUTED,true))
    var holder := []
    for id in screen.session.room_ids():
        var button := AstraUI.button(screen.session.room_name(str(id)),AstraUI.CYAN,16,44)
        button.pressed.connect(func():
            holder[0].close(-1)
            _choose("backup",str(id))
        )
        box.add_child(button)
    holder.append(AstraModal.open(screen.app.overlay_root(),"어느 기록을 남길까?",box,[["닫기",AstraUI.MUTED]]))
