extends VBoxContainer

# Private interrogation: large portrait, persistent per-character transcript
# (answers are always visible), and question buttons with their cost/hint.
# A pending private event takes over the view until the player answers it.

var screen
var _content: Control
var _portrait: AstraPortraitView
var _transcript: RichTextLabel
var _mode: String = ""
var _npc_shown: String = ""

func setup(game_screen) -> void:
    screen = game_screen
    add_theme_constant_override("separation", 10)
    size_flags_vertical = Control.SIZE_EXPAND_FILL
    refresh()

func refresh() -> void:
    var session: AstraGameSession = screen.session
    var mode := "event" if not session.pending_event.is_empty() else "talk"
    var npc_id: String = str(session.pending_event.get("npc_id", "")) if mode == "event" else screen.selected_id()
    if mode != _mode or npc_id != _npc_shown or _content == null:
        _mode = mode
        _npc_shown = npc_id
        _rebuild(session, npc_id)
    else:
        _update(session, npc_id)

func _rebuild(session: AstraGameSession, npc_id: String) -> void:
    AstraUI.clear(self)
    _content = null
    _portrait = null
    _transcript = null
    if _mode == "event":
        _content = _event_layout(session)
    else:
        _content = _talk_layout(session, npc_id)
    add_child(_content)

func _update(session: AstraGameSession, npc_id: String) -> void:
    if _mode == "talk":
        var old := _content
        _content = _talk_layout(session, npc_id, false)
        remove_child(old)
        old.queue_free()
        add_child(_content)

# ------------------------------------------------------------------ private event

func _event_layout(session: AstraGameSession) -> Control:
    var event := session.pending_event
    var npc_id := str(event.get("npc_id", ""))
    var member := session.npc(npc_id)
    var row := AstraUI.hbox(18)
    row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _portrait = AstraPortraitView.new()
    _portrait.custom_minimum_size = Vector2(214, 268)
    _portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    row.add_child(_portrait)
    _portrait.show_member(member, true)
    var box := AstraUI.vbox(12)
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(box)
    box.add_child(AstraUI.chip("개인 면담 · " + member.display_name, AstraUI.PINK, 13))
    var scene := AstraUI.rich(15)
    scene.text = "[i][color=#%s]%s[/color][/i]" % [AstraUI.hex(AstraUI.MUTED), AstraUI.escape(str(event.get("scene", "")))]
    box.add_child(scene)
    box.add_child(AstraUI.label(str(event.get("prompt", "")), 20, AstraUI.TEXT, true))
    box.add_child(AstraUI.label("어떻게 답할까요? (행동력은 소모하지 않습니다)", 13, AstraUI.DIM))
    var choices: Array = event.get("choices", [])
    for index in range(choices.size()):
        var choice: Dictionary = choices[index]
        var option := AstraUI.vbox(2)
        var button := AstraUI.button(str(choice.get("label", "")), AstraUI.PINK if index == 0 else AstraUI.CYAN, 16, 50)
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        button.pressed.connect(_resolve_event.bind(index))
        option.add_child(button)
        option.add_child(AstraUI.label(str(choice.get("hint", "")), 12, AstraUI.DIM, true))
        box.add_child(option)
    return row

func _resolve_event(index: int) -> void:
    var session: AstraGameSession = screen.session
    var result := session.resolve_private_event(index)
    if not bool(result.get("ok", false)):
        return
    screen.fx.play("secret" if result.has("clue") else "click")
    var text := str(result.get("text", ""))
    if text != "":
        screen.fx.toast(text, AstraUI.PINK, 5.0)
    screen.select(str(result.get("npc_id", "")))

# ------------------------------------------------------------------ talk

func _talk_layout(session: AstraGameSession, npc_id: String, animate: bool = true) -> Control:
    var member := session.npc(npc_id)
    var row := AstraUI.hbox(16)
    row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    if member == null:
        row.add_child(AstraUI.label("위쪽 승무원 명단에서 심문할 승무원을 고르세요.", 16, AstraUI.MUTED))
        return row

    var left := AstraUI.vbox(10)
    left.custom_minimum_size = Vector2(214, 0)
    row.add_child(left)
    _portrait = AstraPortraitView.new()
    _portrait.custom_minimum_size = Vector2(214, 268)
    left.add_child(_portrait)
    _portrait.show_member(member, animate)
    left.add_child(_stat_row("신뢰", member.trust, AstraUI.GREEN))
    left.add_child(_stat_row("긴장", member.stress, AstraUI.RED))
    left.add_child(AstraUI.label(str(member.info.get("speech_note", "")), 12, AstraUI.DIM, true))
    var claim: Dictionary = session.known_claims.get(npc_id, {})
    if claim.is_empty():
        left.add_child(AstraUI.label("진술 · 아직 듣지 못함", 13, AstraUI.MUTED, true))
    else:
        var mates: Array = claim.get("companions", [])
        left.add_child(AstraUI.label("진술 · %s, %s" % [session.room_name(str(claim.get("position", ""))), "혼자" if mates.is_empty() else AstraJosa.wa(session.names_of(mates)) + " 함께"], 13, AstraUI.TEXT, true))
    var issues := session.contradictions_on(npc_id).size()
    if member.secret_revealed:
        left.add_child(AstraUI.chip("숨긴 사정을 털어놓음", AstraUI.GOLD, 12))
    elif issues > 0:
        left.add_child(AstraUI.chip("관련 모순 %d건 · 추궁 가능" % issues, AstraUI.RED, 12))

    var right := AstraUI.vbox(10)
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(right)
    var head := AstraUI.rich(17)
    head.text = "[b][color=#%s]%s[/color][/b] [color=#%s]%s[/color]    [color=#%s]심문 행동력[/color] %s" % [AstraUI.hex(member.accent), member.display_name, AstraUI.hex(AstraUI.MUTED), member.job, AstraUI.hex(AstraUI.MUTED), AstraUI.pips(session.talk_ap, session.talk_ap_max(), AstraUI.GREEN)]
    right.add_child(head)

    var log_panel := AstraUI.panel(Color(AstraUI.BG, 0.6), AstraUI.BORDER, 10, 12)
    log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    right.add_child(log_panel)
    _transcript = AstraUI.rich(15, false)
    _transcript.scroll_following = true
    _transcript.size_flags_vertical = Control.SIZE_EXPAND_FILL
    log_panel.add_child(_transcript)
    _transcript.text = _transcript_text(session, member)

    if not member.is_alive():
        right.add_child(AstraUI.label(AstraJosa.eun(member.display_name) + " 더 이상 심문할 수 없습니다.", 15, AstraUI.GOLD))
        return row

    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 8)
    grid.add_theme_constant_override("v_separation", 6)
    right.add_child(grid)
    for option in session.question_options(npc_id):
        var cell := AstraUI.vbox(1)
        cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var intent := str(option.get("intent", ""))
        var button := AstraUI.button(str(option.get("label", "")), _intent_color(intent), 15, 40)
        button.clip_text = true
        button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        button.custom_minimum_size = Vector2(0, 40)
        button.disabled = not bool(option.get("enabled", false))
        button.tooltip_text = str(option.get("hint", ""))
        button.pressed.connect(_ask.bind(npc_id, intent))
        cell.add_child(button)
        cell.add_child(AstraUI.label(str(option.get("hint", "")), 11, AstraUI.DIM, true))
        grid.add_child(cell)
    if session.talk_ap <= 0:
        right.add_child(AstraUI.label("오늘 심문 행동력을 모두 썼습니다. 아래 버튼으로 공개 회의를 소집하세요.", 14, AstraUI.GOLD, true))
    return row

func _stat_row(title: String, value: float, color: Color) -> Control:
    var row := AstraUI.hbox(8)
    row.add_child(AstraUI.label(title, 13, AstraUI.MUTED))
    row.add_child(AstraUI.meter(value, color, 8))
    row.add_child(AstraUI.label("%d%%" % int(round(value * 100.0)), 13, AstraUI.TEXT))
    return row

func _transcript_text(session: AstraGameSession, member: AstraCrewMember) -> String:
    var entries: Array = session.transcripts.get(member.id, [])
    if entries.is_empty():
        return "[color=#%s]아직 나눈 대화가 없습니다. 아래 질문을 골라 보세요.\n\n· 알리바이는 출입 기록과 대조할 수 있습니다.\n· 단서를 보여 주면 명단에 든 사람과 아닌 사람의 반응이 다릅니다.\n· 모순을 찾았다면 추궁해 보세요.[/color]" % AstraUI.hex(AstraUI.DIM)
    var lines: Array = []
    var last_day := -1
    for entry in entries:
        var entry_day := int(entry.get("day", 1))
        if entry_day != last_day:
            last_day = entry_day
            lines.append("[center][color=#%s]— DAY %d —[/color][/center]" % [AstraUI.hex(AstraUI.DIM), entry_day])
        var speaker := str(entry.get("speaker", ""))
        var text := AstraUI.escape(str(entry.get("text", "")))
        if speaker == "player":
            lines.append("[color=#%s]조사관[/color]  [color=#%s]%s[/color]" % [AstraUI.hex(AstraUI.CYAN), AstraUI.hex(AstraUI.MUTED), text])
        elif speaker == "narration":
            lines.append("[i][color=#%s]%s[/color][/i]" % [AstraUI.hex(AstraUI.PINK), text])
        else:
            lines.append("[color=#%s][b]%s[/b][/color]  %s" % [AstraUI.hex(member.accent), member.display_name, text])
    return "\n\n".join(PackedStringArray(lines))

func _intent_color(intent: String) -> Color:
    match intent:
        "EVIDENCE": return AstraUI.GOLD
        "CONTRADICTION": return AstraUI.RED
        "REASSURE", "CONFIDE": return AstraUI.GREEN
        "PRESSURE": return Color("ff9a6a")
    return AstraUI.CYAN

func _ask(npc_id: String, intent: String) -> void:
    var session: AstraGameSession = screen.session
    if intent == "EVIDENCE":
        screen.open_clue_picker("어떤 단서를 보여 줄까요?", session.found_clues(), func(clue_id: String): _do_ask(npc_id, intent, clue_id))
        return
    _do_ask(npc_id, intent, "")

func _do_ask(npc_id: String, intent: String, clue_id: String) -> void:
    var session: AstraGameSession = screen.session
    var result := session.ask(npc_id, intent, clue_id)
    if not bool(result.get("ok", false)):
        return
    screen.fx.play("talk")
    if _portrait != null:
        _portrait.pulse()
    if bool(result.get("slip", false)):
        screen.fx.play("slip")
        screen.fx.banner("실언 포착", "%s — 알 수 없어야 할 사실을 입에 올렸다. 단서로 기록됨." % session.name_of(npc_id), AstraUI.RED, 1.4)
        screen.fx.flash(AstraUI.RED, 0.12)
    elif bool(result.get("secret", false)):
        screen.fx.play("secret")
        screen.fx.banner("숨긴 사정", "%s — 거짓 진술의 이유를 털어놓았다." % session.name_of(npc_id), AstraUI.GOLD, 1.3)
    elif result.has("clue"):
        screen.fx.play("clue")
        screen.fx.toast("새 단서 · " + str(result["clue"].get("title", "")), AstraUI.PINK)
    screen.request_ai_line(npc_id, intent, result)
