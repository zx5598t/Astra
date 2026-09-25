extends HBoxContainer

# Meeting. The room argues one point at a time: someone puts something on the
# table, the named person answers, a third person weighs in — then it pauses.
# At each pause the explorer can step in (2–3 options that fit this point) or
# keep listening. Public-source checks have a separate budget; spending the
# decisive intervention never skips the remaining player windows.

const TONE_COLOR := {"calm": AstraUI.CYAN, "press": AstraUI.RED, "defend": AstraUI.GREEN, "redirect": AstraUI.GOLD, "confront": AstraUI.PINK}
const REVEAL_DELAY := 0.95

var screen
var _feed: VBoxContainer
var _feed_scroll: ScrollContainer
var _mood: Label
var _board: VBoxContainer
var _actions: VBoxContainer
var _shown: int = 0
var _timer: Timer
var _picker_open: bool = false

func setup(game_screen) -> void:
    screen = game_screen
    add_theme_constant_override("separation", 16)
    var left := AstraUI.vbox(8)
    left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    left.size_flags_stretch_ratio = 1.6
    add_child(left)
    _mood = AstraUI.label("", AstraUI.T_META, AstraUI.GOLD, true)
    left.add_child(_mood)
    var feed_panel := AstraUI.panel(Color(0.02, 0.035, 0.06, 0.9), AstraUI.BORDER, 12, 14)
    feed_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    left.add_child(feed_panel)
    _feed = AstraUI.vbox(10)
    _feed_scroll = AstraUI.scroll(_feed)
    feed_panel.add_child(_feed_scroll)
    _feed_scroll.gui_input.connect(func(event: InputEvent):
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _reveal_all()
    )

    var right := AstraUI.vbox(10)
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.custom_minimum_size.x = 400
    add_child(right)
    var board_panel := AstraUI.panel(Color(0.02, 0.035, 0.06, 0.88), AstraUI.BORDER, 12, 12)
    right.add_child(board_panel)
    var board_box := AstraUI.vbox(4)
    board_panel.add_child(board_box)
    board_box.add_child(AstraUI.label("모두가 말한 %s의 위치" % screen.session.incident_time(), AstraUI.T_META, AstraUI.CYAN))
    _board = AstraUI.vbox(3)
    board_box.add_child(_board)
    var action_panel := AstraUI.panel(Color(0.03, 0.05, 0.08, 0.94), Color(AstraUI.GOLD, 0.4), 12, 12)
    action_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    right.add_child(action_panel)
    _actions = AstraUI.vbox(8)
    action_panel.add_child(AstraUI.scroll(_actions))

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
    # The first meeting's mood is already in its opening narration.
    var mood := "말이 조금씩 날카로워진다."
    match s.meeting_temperature():
        "grief": mood = "사람 하나가 빠진 회의. 목소리가 낮다."
        "low": return "오늘의 질문 · %s" % s.day_question()
        "high": mood = "이제 아무도 돌려 말하지 않는다."
    return "오늘의 질문 · %s   —   %s" % [s.day_question(), mood]

func _render_board() -> void:
    var s: AstraGameSession = screen.session
    AstraUI.clear(_board)
    var conflicted := {}
    for item in s.manual_contradictions:
        if int(item.get("day", 0)) == s.day:
            for id in item.get("targets", []):
                conflicted[str(id)] = true
    for npc_id in s.living_ids():
        if not s.public_claims.has(npc_id):
            continue
        var claim := s.current_claim(str(npc_id))
        var mates: Array = claim.get("companions", [])
        var row := AstraUI.hbox(6)
        row.add_child(AstraUI.crew_dot(str(npc_id), 26))
        row.add_child(AstraUI.label(s.name_of(str(npc_id)), AstraUI.T_META, AstraCrewCatalog.accent(str(npc_id))))
        var where := s.room_name(str(claim.get("position", "")))
        if str(claim.get("position", "")) == "cabin:" + str(npc_id):
            where = "자기 선실"
        var text := where + (" · " + AstraJosa.wa(s.names_of(mates)) + " 함께" if not mates.is_empty() else " · 혼자")
        var label := AstraUI.label(text, AstraUI.T_META, AstraUI.TEXT)
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.clip_text = true
        row.add_child(label)
        if conflicted.has(str(npc_id)):
            row.add_child(AstraUI.label("말이 안 맞음", AstraUI.T_META - 2, AstraUI.RED))
        _board.add_child(row)

func _reveal_next() -> void:
    var s: AstraGameSession = screen.session
    if _shown >= s.meeting_feed.size():
        _timer.stop()
        _on_caught_up()
        return
    var entry: Dictionary = s.meeting_feed[_shown]
    _shown += 1
    var node := _line_node(entry)
    _feed.add_child(node)
    AstraUI.fade_in(node, 0.2)
    screen.fx.play("tick")
    call_deferred("_scroll_bottom")
    screen.refresh_objective()
    if _shown >= s.meeting_feed.size():
        _timer.stop()
        _on_caught_up()

func _reveal_all() -> void:
    while _shown < screen.session.meeting_feed.size():
        var entry: Dictionary = screen.session.meeting_feed[_shown]
        _shown += 1
        _feed.add_child(_line_node(entry))
    _timer.stop()
    call_deferred("_scroll_bottom")
    _on_caught_up()

func consume_advance() -> bool:
    if pending_lines() > 0:
        _reveal_all()
        return true
    return false

func _scroll_bottom() -> void:
    if is_instance_valid(_feed_scroll):
        _feed_scroll.scroll_vertical = int(_feed_scroll.get_v_scroll_bar().max_value)

# Caught up with the room: if the explorer has nothing left to say, the room
# simply carries on to the end of the meeting.
func _on_caught_up() -> void:
    var s: AstraGameSession = screen.session
    if s.phase != "MEETING":
        return
    _render_actions()
    screen.refresh_objective()

func _line_node(entry: Dictionary) -> Control:
    var s: AstraGameSession = screen.session
    var speaker := str(entry.get("speaker", ""))
    var text := str(entry.get("text", ""))
    if speaker == "":
        var n := AstraUI.prose(text, AstraUI.T_META, AstraUI.MUTED)
        n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        return n
    var anchor := str(entry.get("thread_role", "")) == "anchor"
    var row := AstraUI.hbox(10)
    if anchor:
        row.add_theme_constant_override("separation", 10)
    if speaker == "player":
        var bubble := AstraUI.panel(Color(AstraUI.GOLD, 0.12), Color(AstraUI.GOLD, 0.6), 10, 12)
        var box := AstraUI.vbox(2)
        bubble.add_child(box)
        box.add_child(AstraUI.label(AstraUI.player_name(s), AstraUI.T_META, AstraUI.GOLD))
        box.add_child(AstraUI.prose(text, AstraUI.T_BODY, AstraUI.TEXT))
        bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(AstraUI.spacer())
        row.add_child(bubble)
        row.add_child(AstraUI.player_face(s, Vector2(58, 58)))
        return row
    var face := AstraUI.thumb(AstraCrewCatalog.portrait_path(speaker, _face_for(entry)), Vector2(58, 72))
    face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    row.add_child(face)
    var accent: Color = AstraCrewCatalog.accent(speaker)
    var bubble2 := AstraUI.panel(Color(accent, 0.07), Color(accent, 0.45 if anchor else 0.25), 10, 10)
    bubble2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var col := AstraUI.vbox(2)
    bubble2.add_child(col)
    var head := AstraUI.hbox(8)
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
        "calm": return "neutral"
        "record": return "neutral"
    return "neutral"

func _render_actions() -> void:
    var s: AstraGameSession = screen.session
    AstraUI.clear(_actions)
    if pending_lines() > 0:
        _actions.add_child(AstraUI.label("듣는 중…", AstraUI.T_UI, AstraUI.MUTED))
        var skip := AstraUI.button("끝까지 보기  ▸▸", AstraUI.MUTED, AstraUI.T_META, 36)
        skip.pressed.connect(_reveal_all)
        _actions.add_child(skip)
        return
    if _picker_open:
        _render_accuse_picker()
        return
    var soft := s.clarification_options()
    if not soft.is_empty():
        _actions.add_child(AstraUI.label("되묻기 · 강한 개입과 별도", AstraUI.T_META, AstraUI.CYAN))
        for option in soft:
            var check_button := AstraUI.button(str(option["label"]), AstraUI.CYAN, AstraUI.T_UI, 46)
            check_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            check_button.pressed.connect(_intervene.bind("clarify", str(option["ref"])))
            _actions.add_child(check_button)
    var options := s.meeting_options()
    if not options.is_empty():
        var title := "끼어들 수 있습니다  (%d번 남음)" % s.meeting_actions_left
        _actions.add_child(AstraUI.label(title, AstraUI.T_UI, AstraUI.GOLD))
        for option in options:
            var kind := str(option.get("kind", ""))
            var accent: Color = TONE_COLOR.get(str(option.get("tone", "calm")), AstraUI.CYAN)
            var button := AstraUI.button(str(option.get("label", "")), accent, AstraUI.T_UI, 46)
            button.alignment = HORIZONTAL_ALIGNMENT_LEFT
            button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            button.tooltip_text = str(option.get("detail", ""))
            if kind == "accuse":
                button.pressed.connect(func():
                    _picker_open = true
                    _render_actions()
                )
            else:
                button.pressed.connect(_intervene.bind(kind, str(option.get("ref", ""))))
            _actions.add_child(button)
            var detail := str(option.get("detail", ""))
            if detail != "" and kind != "accuse":
                var small := AstraUI.label(detail, AstraUI.T_META - 2, AstraUI.DIM, true)
                small.max_lines_visible = 2
                _actions.add_child(small)
    if not s.meeting_over():
        var listen := AstraUI.button("계속 듣는다  ▸", AstraUI.CYAN, AstraUI.T_UI, 44, true)
        listen.pressed.connect(_continue)
        _actions.add_child(listen)
    else:
        _actions.add_child(AstraUI.prose("할 말은 다 나왔습니다. 이제 한 사람을 정해야 합니다.", AstraUI.T_META, AstraUI.MUTED))
        var vote := AstraUI.primary_button("투표하러 가기  →", AstraUI.RED)
        vote.custom_minimum_size.y = 52
        vote.pressed.connect(func(): screen.advance_phase())
        _actions.add_child(vote)

func _render_accuse_picker() -> void:
    var s: AstraGameSession = screen.session
    _actions.add_child(AstraUI.label("누구를 지목할까요?", AstraUI.T_UI, AstraUI.PINK))
    _actions.add_child(AstraUI.prose("당신을 믿는 사람일수록 이 지목에 따라 표를 옮깁니다. 근거가 없으면 믿음을 잃습니다.", AstraUI.T_META, AstraUI.MUTED))
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 6)
    grid.add_theme_constant_override("v_separation", 6)
    _actions.add_child(grid)
    for npc_id in s.living_ids():
        var button := AstraUI.button(s.name_of(str(npc_id)), AstraCrewCatalog.accent(str(npc_id)), AstraUI.T_UI, 44)
        button.icon = AstraUI.texture(AstraCrewCatalog.dot_path(str(npc_id)))
        button.expand_icon = true
        button.add_theme_constant_override("icon_max_width", 30)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.pressed.connect(func():
            _picker_open = false
            _intervene("accuse", str(npc_id))
        )
        grid.add_child(button)
    var back := AstraUI.button("취소", AstraUI.MUTED, AstraUI.T_META, 36)
    back.pressed.connect(func():
        _picker_open = false
        _render_actions()
    )
    _actions.add_child(back)

func _intervene(kind: String, ref: String) -> void:
    var s: AstraGameSession = screen.session
    var result := s.intervene(kind, ref)
    if not bool(result.get("ok", false)):
        screen.fx.toast("지금은 그렇게 할 수 없습니다.", AstraUI.GOLD)
        return
    screen.fx.play("select")
    # The actual reason from DecisionTrace is spoken in the feed.
    _timer.start()
    _render_actions()

func _continue() -> void:
    screen.fx.play("click")
    screen.session.meeting_continue()
    _timer.start()
    _render_actions()
