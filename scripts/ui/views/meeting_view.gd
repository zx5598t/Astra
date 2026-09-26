extends HBoxContainer

# Meeting. The room argues one point at a time: someone puts something on the
# table, the named person answers, a third person weighs in — then it pauses.
# At each pause the explorer can ask a short question about the point (three a
# Day), take up someone's words with what they know (link a statement to one
# or two pieces of evidence), press, defend or accuse (three moves a Day), or
# keep listening. The board on the right says, in words, where each person
# stands; nothing is scored on screen.
#
# Scrolling: new lines are followed only while the reader is at the bottom;
# reading back is never interrupted (a "새 발언 ↓" chip appears instead). The
# scroll happens after layout has settled, with room left under the last line.

const TONE_COLOR := {"calm": AstraUI.CYAN, "press": AstraUI.RED, "defend": AstraUI.GREEN, "redirect": AstraUI.GOLD, "confront": AstraUI.PINK}
const STATUS_COLOR := {"conflict": AstraUI.RED, "explained": AstraUI.GREEN, "supported": AstraUI.GREEN, "pointed": AstraUI.GOLD, "open": AstraUI.DIM}
const REVEAL_DELAY := 0.95

var screen
var _feed: VBoxContainer
var _feed_scroll: ScrollContainer
var _feed_pad: Control
var _new_chip: Button
var _mood: Label
var _board: VBoxContainer
var _issues: VBoxContainer
var _actions: VBoxContainer
var _actions_scroll: ScrollContainer
var _shown: int = 0
var _timer: Timer
var _picker := ""
var _link_statement := ""
var _link_evidence := ""

func setup(game_screen) -> void:
    screen = game_screen
    add_theme_constant_override("separation", AstraUI.SPACE_LG)
    var left := AstraUI.vbox(AstraUI.SPACE_SM)
    left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    left.size_flags_stretch_ratio = 1.55
    add_child(left)
    _mood = AstraUI.label("", AstraUI.T_META, AstraUI.GOLD, true)
    left.add_child(_mood)
    var feed_panel := AstraUI.panel(Color(0.02, 0.035, 0.06, 0.9), AstraUI.BORDER, 12, AstraUI.PANEL_PADDING)
    feed_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    left.add_child(feed_panel)
    var feed_stack := Control.new()
    feed_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
    feed_panel.add_child(feed_stack)
    _feed = AstraUI.vbox(AstraUI.SPACE_MD)
    _feed_scroll = AstraUI.scroll(_feed)
    _feed_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    feed_stack.add_child(_feed_scroll)
    AstraUI.track_follow(_feed_scroll)
    _feed_pad = AstraUI.bottom_pad()
    _feed.add_child(_feed_pad)
    _feed_scroll.gui_input.connect(func(event: InputEvent):
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _reveal_all()
    )
    _new_chip = AstraUI.button("새 발언 ↓", AstraUI.GOLD, AstraUI.T_META, 34, true)
    _new_chip.visible = false
    _new_chip.anchor_left = 0.5
    _new_chip.anchor_right = 0.5
    _new_chip.anchor_top = 1.0
    _new_chip.anchor_bottom = 1.0
    _new_chip.offset_left = -70
    _new_chip.offset_right = 70
    _new_chip.offset_top = -46
    _new_chip.offset_bottom = -8
    _new_chip.pressed.connect(func():
        _new_chip.visible = false
        AstraUI.follow_bottom(_feed_scroll, true)
    )
    feed_stack.add_child(_new_chip)
    _feed_scroll.get_v_scroll_bar().value_changed.connect(func(_v):
        if AstraUI.is_following(_feed_scroll):
            _new_chip.visible = false
    )

    var right := AstraUI.vbox(AstraUI.SPACE_MD)
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.custom_minimum_size.x = 380
    add_child(right)
    var board_panel := AstraUI.panel(Color(0.02, 0.035, 0.06, 0.88), AstraUI.BORDER, 12, AstraUI.SPACE_MD)
    right.add_child(board_panel)
    var board_box := AstraUI.vbox(AstraUI.SPACE_XS)
    board_panel.add_child(board_box)
    board_box.add_child(AstraUI.label("%s · 각자 한 말과 지금 상태" % screen.session.incident_time(), AstraUI.T_META, AstraUI.CYAN))
    _board = AstraUI.vbox(3)
    board_box.add_child(_board)
    _issues = AstraUI.vbox(2)
    board_box.add_child(_issues)
    var action_panel := AstraUI.panel(Color(0.03, 0.05, 0.08, 0.94), Color(AstraUI.GOLD, 0.4), 12, AstraUI.SPACE_MD)
    action_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    right.add_child(action_panel)
    _actions = AstraUI.vbox(AstraUI.BUTTON_GAP)
    _actions_scroll = AstraUI.scroll(_actions)
    action_panel.add_child(_actions_scroll)

    _timer = Timer.new()
    _timer.one_shot = false
    _timer.wait_time = 0.12 if AstraUI.reduce_motion else REVEAL_DELAY
    _timer.timeout.connect(_reveal_next)
    add_child(_timer)
    _timer.start()
    refresh()

func pending_lines() -> int:
    return maxi(0, screen.session.meeting_feed.size() - _shown)

func refresh() -> void:
    var s: AstraGameSession = screen.session
    if s.phase != "MEETING":
        return
    _mood.text = _mood_text()
    _render_board()
    if pending_lines() > 0 and _timer.is_stopped():
        _timer.start()
    _render_actions()

func _mood_text() -> String:
    var s: AstraGameSession = screen.session
    var mood := "말이 조금씩 날카로워진다."
    match s.meeting_temperature():
        "grief": mood = "사람 하나가 빠진 회의. 목소리가 낮다."
        "low": return "오늘의 질문 · %s" % s.day_question()
        "high": mood = "이제 아무도 돌려 말하지 않는다."
    return "오늘의 질문 · %s   —   %s" % [s.day_question(), mood]

func _render_board() -> void:
    var s: AstraGameSession = screen.session
    AstraUI.clear(_board)
    for npc_id in s.living_ids():
        if not s.public_claims.has(npc_id):
            continue
        var claim := s.current_claim(str(npc_id))
        var mates: Array = claim.get("companions", [])
        var row := AstraUI.hbox(AstraUI.SPACE_SM)
        row.add_child(AstraUI.crew_dot(str(npc_id), 24))
        var name_label := AstraUI.label(s.name_of(str(npc_id)), AstraUI.T_META, AstraCrewCatalog.accent(str(npc_id)))
        name_label.custom_minimum_size.x = 42
        row.add_child(name_label)
        var where := s.room_name(str(claim.get("position", "")))
        if str(claim.get("position", "")) == "cabin:" + str(npc_id):
            where = "자기 선실"
        var text := where + (" · " + AstraJosa.wa(s.names_of(mates)) + " 함께" if not mates.is_empty() else " · 혼자")
        var claim_label := AstraUI.label(text, AstraUI.T_META, AstraUI.TEXT, true)
        row.add_child(claim_label)
        var status := s.board_status(str(npc_id))
        var tone: Color = STATUS_COLOR.get(str(status["tone"]), AstraUI.DIM)
        row.add_child(AstraUI.chip(str(status["text"]), tone, AstraUI.T_META - 3))
        _board.add_child(row)
    AstraUI.clear(_issues)
    var open := 0
    for item in s.contradictions:
        if not bool(item.get("public", false)):
            continue
        if open == 0:
            _issues.add_child(AstraUI.label("지금 걸려 있는 말", AstraUI.T_META - 1, AstraUI.GOLD))
        open += 1
        var line := AstraUI.label("· " + str(item.get("detail", "")), AstraUI.T_META - 1, AstraUI.MUTED, true)
        _issues.add_child(line)
        if open >= 3:
            break

func _reveal_next() -> void:
    var s: AstraGameSession = screen.session
    if _shown >= s.meeting_feed.size():
        _timer.stop()
        _on_caught_up()
        return
    var entry: Dictionary = s.meeting_feed[_shown]
    _shown += 1
    _append(_line_node(entry), true)
    screen.fx.play("tick")
    screen.refresh_objective()
    if _shown >= s.meeting_feed.size():
        _timer.stop()
        _on_caught_up()

func _append(node: Control, animate: bool) -> void:
    _feed.add_child(node)
    _feed.move_child(_feed_pad, -1)
    if animate:
        AstraUI.fade_in(node, 0.2)
    if AstraUI.is_following(_feed_scroll):
        _follow_after_layout()
    else:
        _new_chip.visible = true

func _follow_after_layout() -> void:
    await AstraUI.follow_bottom(_feed_scroll)
    if not is_instance_valid(_feed_scroll) or not is_instance_valid(_new_chip):
        return
    # The reader can move during AstraUI's two-frame layout settle. If that
    # cancelled the queued follow, make the unread-line affordance visible.
    if not AstraUI.is_following(_feed_scroll):
        _new_chip.visible = true

func _reveal_all() -> void:
    while _shown < screen.session.meeting_feed.size():
        var entry: Dictionary = screen.session.meeting_feed[_shown]
        _shown += 1
        _feed.add_child(_line_node(entry))
    _feed.move_child(_feed_pad, -1)
    _timer.stop()
    # "끝까지 보기" always lands on the last line, whole.
    AstraUI.follow_bottom(_feed_scroll, true)
    _on_caught_up()

func consume_advance() -> bool:
    if pending_lines() > 0:
        _reveal_all()
        return true
    return false

func _on_caught_up() -> void:
    var s: AstraGameSession = screen.session
    if s.phase != "MEETING":
        return
    _render_board()
    _render_actions()
    screen.refresh_objective()

func _line_node(entry: Dictionary) -> Control:
    var s: AstraGameSession = screen.session
    var speaker := str(entry.get("speaker", ""))
    var text := str(entry.get("text", ""))
    if speaker == "":
        var n := AstraUI.prose(text, AstraUI.T_META, AstraUI.MUTED)
        n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        return AstraUI.margin(n, AstraUI.SPACE_LG, AstraUI.SPACE_XS, AstraUI.SPACE_LG, AstraUI.SPACE_XS)
    var anchor := str(entry.get("thread_role", "")) == "anchor"
    var row := AstraUI.hbox(AstraUI.SPACE_MD)
    if speaker == "player":
        var bubble := AstraUI.panel(Color(AstraUI.GOLD, 0.12), Color(AstraUI.GOLD, 0.6), 10, AstraUI.BUBBLE_PADDING)
        var box := AstraUI.vbox(AstraUI.SPACE_XS)
        bubble.add_child(box)
        box.add_child(AstraUI.label(AstraUI.player_name(s), AstraUI.T_META, AstraUI.GOLD))
        box.add_child(AstraUI.prose(text, AstraUI.T_BODY, AstraUI.TEXT))
        bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(AstraUI.spacer())
        row.add_child(bubble)
        var me := AstraUI.player_face(s, Vector2(58, 58))
        me.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
        row.add_child(me)
        return row
    var face := AstraUI.thumb(AstraCrewCatalog.portrait_path(speaker, _face_for(entry)), Vector2(58, 72))
    face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    row.add_child(face)
    var accent: Color = AstraCrewCatalog.accent(speaker)
    var bubble2 := AstraUI.panel(Color(accent, 0.07), Color(accent, 0.45 if anchor else 0.25), 10, AstraUI.BUBBLE_PADDING)
    bubble2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var col := AstraUI.vbox(AstraUI.SPACE_XS)
    bubble2.add_child(col)
    var head := AstraUI.hbox(AstraUI.SPACE_SM)
    col.add_child(head)
    head.add_child(AstraUI.label(s.name_of(speaker), AstraUI.T_META, accent))
    var context := str(entry.get("reply_context", ""))
    if context != "" and not anchor:
        head.add_child(AstraUI.label("· " + context, AstraUI.T_META - 2, AstraUI.DIM))
    col.add_child(AstraUI.prose(text, AstraUI.T_BODY, AstraUI.TEXT))
    row.add_child(bubble2)
    return row

func _face_for(entry: Dictionary) -> String:
    match str(entry.get("kind", "")):
        "suspect", "dispute": return "determined"
        "defense": return "annoyed"
        "mourn": return "sad"
    return "neutral"

func _render_actions() -> void:
    var s: AstraGameSession = screen.session
    AstraUI.clear(_actions)
    if pending_lines() > 0:
        _actions.add_child(AstraUI.label("듣는 중…", AstraUI.T_UI, AstraUI.MUTED))
        var skip := AstraUI.button("끝까지 보기  ▸▸", AstraUI.MUTED, AstraUI.T_META, 40)
        skip.pressed.connect(_reveal_all)
        _actions.add_child(skip)
        return
    match _picker:
        "accuse":
            _render_accuse_picker()
            _finish_actions()
            return
        "link_statement":
            _render_link_statements()
            _finish_actions()
            return
        "link_evidence":
            _render_link_evidence()
            _finish_actions()
            return
    var soft := s.clarification_options()
    if not soft.is_empty():
        _actions.add_child(AstraUI.label("확인 질문 · 오늘 %d번 남음" % int(s.stage_state().get("clarifications_left", 3)), AstraUI.T_META, AstraUI.CYAN))
        for option in soft:
            var check_button := AstraUI.choice_button(str(option["label"]), AstraUI.CYAN, AstraUI.T_UI)
            check_button.pressed.connect(_intervene.bind("clarify", str(option["ref"])))
            _actions.add_child(check_button)
    var options := s.meeting_options()
    if not options.is_empty():
        _actions.add_child(AstraUI.label("발언 · 오늘 %d번 남음" % s.meeting_actions_left, AstraUI.T_UI, AstraUI.GOLD))
        for option in options:
            var kind := str(option.get("kind", ""))
            var accent: Color = TONE_COLOR.get(str(option.get("tone", "calm")), AstraUI.CYAN)
            var button := AstraUI.choice_button(str(option.get("label", "")), accent, AstraUI.T_UI)
            match kind:
                "accuse":
                    button.pressed.connect(func():
                        _picker = "accuse"
                        _render_actions()
                    )
                "link":
                    button.pressed.connect(func():
                        _picker = "link_statement"
                        _render_actions()
                    )
                _:
                    button.pressed.connect(_intervene.bind(kind, str(option.get("ref", ""))))
            _actions.add_child(button)
            var detail := str(option.get("detail", ""))
            if detail != "":
                _actions.add_child(AstraUI.label(detail, AstraUI.T_META - 2, AstraUI.DIM, true))
    if not s.meeting_over():
        var listen := AstraUI.choice_button("계속 듣는다  ▸", AstraUI.CYAN, AstraUI.T_UI, true)
        listen.pressed.connect(_continue)
        _actions.add_child(listen)
    else:
        _actions.add_child(AstraUI.prose("오늘 꺼낼 말은 다 나왔습니다. 위의 정리를 보고, 마지막 말을 들은 뒤 한 사람을 정합니다.", AstraUI.T_META, AstraUI.MUTED))
        var vote := AstraUI.primary_button("투표하러 가기  →", AstraUI.RED)
        vote.custom_minimum_size.y = 52
        vote.pressed.connect(func(): screen.advance_phase())
        _actions.add_child(vote)
    _finish_actions()

# The first actionable control gets focus (keyboard play) and the list keeps
# room under its last button.
func _finish_actions() -> void:
    _actions.add_child(AstraUI.bottom_pad())
    _actions_scroll.scroll_vertical = 0
    for child in _actions.get_children():
        if child is Button:
            var target := child as Button
            (func(): if is_instance_valid(target) and target.is_inside_tree() and target.is_visible_in_tree(): target.grab_focus()).call_deferred()
            break

func _render_accuse_picker() -> void:
    var s: AstraGameSession = screen.session
    _actions.add_child(AstraUI.label("누구를 지목할까요?", AstraUI.T_UI, AstraUI.PINK))
    _actions.add_child(AstraUI.prose("당신을 믿는 사람일수록 이 지목에 따라 표를 옮깁니다. 근거가 없으면 믿음을 잃습니다.", AstraUI.T_META, AstraUI.MUTED))
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", AstraUI.SPACE_SM)
    grid.add_theme_constant_override("v_separation", AstraUI.SPACE_SM)
    _actions.add_child(grid)
    for npc_id in s.living_ids():
        var button := AstraUI.button(s.name_of(str(npc_id)), AstraCrewCatalog.accent(str(npc_id)), AstraUI.T_UI, 44)
        button.icon = AstraUI.texture(AstraCrewCatalog.dot_path(str(npc_id)))
        button.expand_icon = true
        button.add_theme_constant_override("icon_max_width", 30)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.pressed.connect(func():
            _picker = ""
            _intervene("accuse", str(npc_id))
        )
        grid.add_child(button)
    _actions.add_child(_cancel_button())

func _render_link_statements() -> void:
    var s: AstraGameSession = screen.session
    _actions.add_child(AstraUI.label("1 / 2 · 어떤 말을 따질까요?", AstraUI.T_UI, AstraUI.GOLD))
    _actions.add_child(AstraUI.prose("들은 말 하나를 고르세요. 다음에 그 말과 맞지 않는(또는 뒷받침하는) 근거를 고릅니다.", AstraUI.T_META, AstraUI.MUTED))
    for statement in s.link_statements():
        var button := AstraUI.choice_button(str(statement["label"]), AstraUI.GOLD, AstraUI.T_META)
        button.pressed.connect(func():
            _link_statement = str(statement["ref"])
            _link_evidence = ""
            _picker = "link_evidence"
            _render_actions()
        )
        _actions.add_child(button)
    _actions.add_child(_cancel_button())

func _render_link_evidence() -> void:
    var s: AstraGameSession = screen.session
    var statement_label := ""
    for statement in s.link_statements():
        if str(statement["ref"]) == _link_statement:
            statement_label = str(statement["label"])
    _actions.add_child(AstraUI.label("2 / 2 · 무엇과 이어 볼까요?", AstraUI.T_UI, AstraUI.GOLD))
    _actions.add_child(AstraUI.prose("따질 말 · " + statement_label, AstraUI.T_META, AstraUI.TEXT))
    if _link_evidence != "":
        _actions.add_child(AstraUI.prose("첫 번째 근거를 골랐습니다. 같은 쪽을 가리키는 다른 사람의 근거를 하나 더 붙이거나, 이대로 말합니다.", AstraUI.T_META, AstraUI.CYAN))
        var now := AstraUI.choice_button("이대로 말한다  →", AstraUI.GOLD, AstraUI.T_UI, true)
        now.pressed.connect(func(): _submit_link(""))
        _actions.add_child(now)
    for evidence in s.link_evidence(_link_statement):
        var ref := str(evidence["ref"])
        if ref == _link_evidence:
            continue
        var button := AstraUI.choice_button(str(evidence["label"]), AstraUI.CYAN, AstraUI.T_META)
        button.pressed.connect(func():
            if _link_evidence == "" and str(evidence.get("kind", "")) == "fragment":
                _link_evidence = ref
                _render_actions()
            elif _link_evidence == "":
                _link_evidence = ref
                _submit_link("")
            else:
                _submit_link(ref)
        )
        _actions.add_child(button)
    _actions.add_child(_cancel_button())

func _submit_link(second: String) -> void:
    var ref := "%s|%s" % [_link_statement, _link_evidence]
    if second != "":
        ref += "|" + second
    _picker = ""
    _link_statement = ""
    _link_evidence = ""
    _intervene("link", ref)

func _cancel_button() -> Button:
    var back := AstraUI.button("취소", AstraUI.MUTED, AstraUI.T_META, 40)
    back.pressed.connect(func():
        _picker = ""
        _link_statement = ""
        _link_evidence = ""
        _render_actions()
    )
    return back

func _intervene(kind: String, ref: String) -> void:
    var s: AstraGameSession = screen.session
    var result := s.intervene(kind, ref)
    if not bool(result.get("ok", false)):
        screen.fx.toast("지금은 그렇게 할 수 없습니다.", AstraUI.GOLD)
        _render_actions()
        return
    screen.fx.play("select")
    # The player's own words are what they are reading now: bring them into view.
    AstraUI.follow_bottom(_feed_scroll, true)
    _timer.start()
    _render_actions()

func _continue() -> void:
    screen.fx.play("click")
    screen.session.meeting_continue()
    AstraUI.follow_bottom(_feed_scroll, true)
    _timer.start()
    _render_actions()
