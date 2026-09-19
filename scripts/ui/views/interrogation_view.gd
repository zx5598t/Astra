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
    _portrait.custom_minimum_size = Vector2(300, 400)
    _portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    row.add_child(_portrait)
    _portrait.show_member(member, true)
    # The scene text and the choices scroll: some private events run long, and at
    # 1366x768 the last option used to sit below the bottom of the window.
    var scroller := ScrollContainer.new()
    scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
    row.add_child(scroller)
    var box := AstraUI.vbox(12)
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroller.add_child(box)
    var head := AstraUI.hbox(8)
    box.add_child(head)
    head.add_child(AstraUI.chip("개인 면담", AstraUI.PINK, AstraUI.T_META))
    head.add_child(AstraUI.crew_tag(npc_id, AstraUI.T_BODY, true, 28))
    var scene := AstraUI.rich_prose(AstraUI.T_BODY)
    scene.text = "[i][color=#%s]%s[/color][/i]" % [AstraUI.hex(AstraUI.MUTED), AstraUI.escape(str(event.get("scene", "")))]
    box.add_child(scene)
    box.add_child(AstraUI.prose(str(event.get("prompt", "")), AstraUI.T_HEAD, AstraUI.TEXT))
    box.add_child(AstraUI.label("이 대화에는 시간이 들지 않습니다.", AstraUI.T_META, AstraUI.DIM))
    var choices: Array = event.get("choices", [])
    for index in range(choices.size()):
        var choice: Dictionary = choices[index]
        var button := AstraUI.button(str(choice.get("label", "")), AstraUI.PINK if index == 0 else AstraUI.CYAN, AstraUI.T_UI, 52)
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        button.pressed.connect(_resolve_event.bind(index))
        box.add_child(button)
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
        row.add_child(AstraUI.label("위쪽 승무원 명단에서 이야기할 사람을 고르세요.", AstraUI.T_BODY, AstraUI.MUTED))
        return row

    # ---- left: who am I talking to -------------------------------------
    #
    # The column scrolls. At 1366x768 the portrait, the status card and the
    # relationship card together are taller than the panel, and in 0.3.1 the
    # overflow was simply clipped off the bottom of the screen.
    var left_scroll := ScrollContainer.new()
    left_scroll.custom_minimum_size = Vector2(330, 0)
    left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    row.add_child(left_scroll)
    var left := AstraUI.vbox(8)
    left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    left_scroll.add_child(left)
    _portrait = AstraPortraitView.new()
    # 3:4 to match the cast art, so the figure fills the frame without cropping.
    _portrait.custom_minimum_size = Vector2(300, 400)
    left.add_child(_portrait)
    _portrait.show_member(member, animate)

    # One compact status card, instead of the three loose captions that used to
    # run off the bottom of the column and get clipped.
    var card := AstraUI.panel(Color(0.016, 0.031, 0.062, 0.93), Color(member.accent, 0.3), 10, 10)
    left.add_child(card)
    var card_box := AstraUI.vbox(5)
    card.add_child(card_box)
    card_box.add_child(AstraUI.crew_tag(npc_id, AstraUI.T_BODY, true, 28))
    var claim: Dictionary = session.known_claims.get(npc_id, {})
    if claim.is_empty():
        card_box.add_child(AstraUI.label("진술 · 아직 듣지 못함", AstraUI.T_META, AstraUI.DIM))
    else:
        var mates: Array = claim.get("companions", [])
        var mate_text := "혼자" if mates.is_empty() else AstraJosa.wa(session.names_of(mates)) + " 함께"
        card_box.add_child(AstraUI.prose("진술 · " + session.room_name(str(claim.get("position", ""))) + " / " + mate_text, AstraUI.T_META, AstraUI.TEXT))
    var issues := session.contradictions_on(npc_id).size()
    if member.secret_revealed:
        card_box.add_child(AstraUI.chip("숨긴 사정을 털어놓음", AstraUI.GOLD, AstraUI.T_META - 2))
    elif issues > 0:
        card_box.add_child(AstraUI.chip("진술에 어긋난 부분 %d건" % issues, AstraUI.RED, AstraUI.T_META - 2))
    # Who this person is watching, and why — right beside their face, so the
    # player does not have to keep fifty-six relationships in their head.
    left.add_child(AstraUI.relation_card(session, npc_id))

    # ---- right: the conversation ----------------------------------------
    var right := AstraUI.vbox(10)
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(right)

    var log_panel := AstraUI.panel(Color(AstraUI.BG, 0.74), AstraUI.BORDER, 10, 12)
    log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    right.add_child(log_panel)
    _transcript = AstraUI.rich(AstraUI.T_BODY, false)
    _transcript.add_theme_constant_override("line_separation", AstraUI.LINE_SPACING)
    _transcript.scroll_following = true
    _transcript.size_flags_vertical = Control.SIZE_EXPAND_FILL
    log_panel.add_child(_transcript)
    _transcript.text = _transcript_text(session, member)

    if not member.is_alive():
        right.add_child(AstraUI.label(AstraJosa.eun(member.display_name) + " 더 이상 심문할 수 없습니다.", AstraUI.T_BODY, AstraUI.GOLD))
        return row

    # Question buttons say what they are for on the button itself, not only in a
    # tooltip nobody hovers long enough to read.
    # The question list scrolls too: 0.4.0 offers up to nine of them and the
    # last few used to sit below the bottom of the window with no indication
    # that they existed.
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 8)
    grid.add_theme_constant_override("v_separation", 8)
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var grid_scroll := ScrollContainer.new()
    grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    grid_scroll.custom_minimum_size.y = 210
    grid_scroll.size_flags_vertical = Control.SIZE_SHRINK_END
    grid_scroll.add_child(grid)
    right.add_child(grid_scroll)
    for option in session.question_options(npc_id):
        var intent := str(option.get("intent", ""))
        var cell := AstraUI.vbox(1)
        cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var button := AstraUI.button(str(option.get("label", "")), _intent_color(intent), AstraUI.T_UI, 40)
        button.clip_text = true
        button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        button.disabled = not bool(option.get("enabled", false))
        button.tooltip_text = str(option.get("hint", ""))
        button.pressed.connect(_ask.bind(npc_id, intent))
        cell.add_child(button)
        var hint := AstraUI.label(str(option.get("hint", "")), AstraUI.T_META - 1, AstraUI.DIM)
        hint.clip_text = true
        hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        cell.add_child(hint)
        grid.add_child(cell)
        # In the tutorial the question that moves the case forward is ringed, so
        # the player is not left scanning eight buttons for the right one.
        if session.tutorial_active() and bool(option.get("key", false)) and not button.disabled:
            AstraUI.mark_as_target(button, AstraUI.GOLD, "")
    if session.talk_ap <= 0:
        right.add_child(AstraUI.label("질문을 다 썼습니다. 아래 버튼으로 회의를 소집하세요.", AstraUI.T_BODY, AstraUI.GOLD))
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
        # Speaker on its own line above the words. Running "이름  말" together on
        # one line made long answers wrap under the name and read as one block.
        if speaker == "player":
            lines.append("[color=#%s]▸ 탐사요원[/color]\n[color=#%s]%s[/color]" % [AstraUI.hex(AstraUI.CYAN), AstraUI.hex(AstraUI.MUTED), text])
        elif speaker == "narration":
            lines.append("[i][color=#%s]%s[/color][/i]" % [AstraUI.hex(AstraUI.PINK), text])
        else:
            lines.append("[color=#%s][b]%s[/b][/color] [color=#%s](%s)[/color]\n%s" % [
                AstraUI.hex(member.accent), member.display_name,
                AstraUI.hex(AstraUI.DIM), member.job, text])
    return "\n\n".join(PackedStringArray(lines))

func _intent_color(intent: String) -> Color:
    match intent:
        "EVIDENCE": return AstraUI.GOLD
        "CONTRADICTION": return AstraUI.RED
        "REASSURE", "CONFIDE", "PERSONAL": return AstraUI.GREEN
        "PRESSURE": return Color("ff9a6a")
        "WITNESS", "TIMELINE": return AstraUI.VIOLET
        "TRUST": return AstraUI.PINK
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
