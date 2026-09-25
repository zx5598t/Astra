extends HBoxContainer

# Conversation (INTERROGATION). One click on a face starts a conversation;
# there is no room to pick first and no separate "talk" button (§76). The
# person answers at once, large on the right, and at most three follow-ups are
# offered — each one built from something the explorer actually knows.

const REACTION_FACE := {"SHAKEN": "shocked", "RESISTED": "annoyed", "ANGERED": "angry", "CONVINCED": "sad", "UNCERTAIN": "suspicious"}
const FACE_ALIAS := {"calm": "neutral", "warm": "smile", "uneasy": "suspicious", "tense": "determined"}

var screen
var _people: GridContainer
var _people_title: Label
var _people_budget: Label
var _right: VBoxContainer
var _portrait: TextureRect
var _name: Label
var _job: Label
var _tags: HBoxContainer
var _state: Label
var _log: VBoxContainer
var _log_scroll: ScrollContainer
var _options: VBoxContainer
var _options_scroll: ScrollContainer
var _analyst: Button
var _next: Button
var _cards: Dictionary = {}
var _selected: String = ""
var _last_lines: int = 0

func setup(game_screen) -> void:
    screen = game_screen
    add_theme_constant_override("separation", 16)
    var s: AstraGameSession = screen.session
    # ---- left: who to hear
    var left := AstraUI.vbox(10)
    left.custom_minimum_size.x = 430
    left.size_flags_stretch_ratio = 0.8
    left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_child(left)
    var head := AstraUI.hbox(10)
    left.add_child(head)
    _people_title = AstraUI.label("누구 말을 들어 볼까?", AstraUI.T_HEAD, AstraUI.TEXT)
    head.add_child(_people_title)
    head.add_child(AstraUI.spacer())
    _people_budget = AstraUI.label("", AstraUI.T_UI, AstraUI.GOLD)
    head.add_child(_people_budget)
    var question := AstraUI.prose("오늘의 질문 · " + s.day_question(), AstraUI.T_UI, AstraUI.GOLD)
    left.add_child(question)
    left.add_child(AstraUI.prose("모두의 말을 다 들을 수는 없습니다. 금색 표시는 오늘 사건과 관련된 일을 맡은 사람입니다.", AstraUI.T_META, AstraUI.MUTED))
    _people = GridContainer.new()
    _people.columns = 2
    _people.add_theme_constant_override("h_separation", 10)
    _people.add_theme_constant_override("v_separation", 10)
    var people_scroll := AstraUI.scroll(_people)
    people_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    left.add_child(people_scroll)
    for npc_id in s.active_roster():
        var card := _person_card(str(npc_id))
        _people.add_child(card)
        _cards[str(npc_id)] = card

    # ---- right: the conversation
    var right_panel := AstraUI.panel(Color(0.02, 0.035, 0.06, 0.9), AstraUI.BORDER, 12, 14)
    right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right_panel.size_flags_stretch_ratio = 1.25
    add_child(right_panel)
    # The speaker stands on the left of the panel, full height; the talk and
    # the questions take the rest, so the conversation always has room.
    var split := AstraUI.hbox(16)
    right_panel.add_child(split)
    var who := AstraUI.vbox(6)
    who.custom_minimum_size.x = 210
    split.add_child(who)
    _portrait = TextureRect.new()
    _portrait.custom_minimum_size = Vector2(210, 270)
    _portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _portrait.material = AstraUI.defringe_material()
    who.add_child(_portrait)
    _name = AstraUI.label("", AstraUI.T_TITLE, AstraUI.TEXT)
    who.add_child(_name)
    _job = AstraUI.label("", AstraUI.T_UI, AstraUI.MUTED)
    who.add_child(_job)
    _tags = AstraUI.hbox(6)
    who.add_child(_tags)
    _state = AstraUI.prose("", AstraUI.T_META, AstraUI.MUTED)
    who.add_child(_state)
    _analyst = AstraUI.button("정밀 대조", AstraUI.VIOLET, AstraUI.T_META, 36)
    _analyst.tooltip_text = "애널리스트 · 하루 한 번. 두 진술, 또는 진술과 기록이 서로 맞는지 대조합니다. 누가 Null인지는 알려 주지 않습니다."
    _analyst.pressed.connect(_open_analyst)
    who.add_child(_analyst)
    who.add_child(AstraUI.spacer(false))
    _right = AstraUI.vbox(10)
    _right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    split.add_child(_right)
    _log = AstraUI.vbox(AstraUI.SPACE_MD)
    _log_scroll = AstraUI.scroll(_log)
    _log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _log_scroll.size_flags_stretch_ratio = 1.6
    AstraUI.track_follow(_log_scroll)
    _right.add_child(_log_scroll)
    _options = AstraUI.vbox(AstraUI.BUTTON_GAP)
    _options_scroll = AstraUI.scroll(_options)
    _options_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _right.add_child(_options_scroll)
    _next = AstraUI.primary_button("회의 열기  →", AstraUI.GREEN)
    _next.custom_minimum_size.y = 48
    _next.pressed.connect(func(): screen.advance_phase())
    _right.add_child(_next)
    _selected = ""
    refresh()

func _person_card(npc_id: String) -> Button:
    var s: AstraGameSession = screen.session
    var card := Button.new()
    card.custom_minimum_size = Vector2(205, 128)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    card.focus_mode = Control.FOCUS_ALL
    card.clip_contents = true
    var row := AstraUI.hbox(10)
    row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    row.offset_left = 8
    row.offset_top = 6
    row.offset_right = -8
    row.offset_bottom = -6
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(row)
    var face := AstraUI.thumb(AstraCrewCatalog.portrait_path(npc_id, "neutral"), Vector2(88, 114))
    face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    face.name = "Face"
    row.add_child(face)
    var col := AstraUI.vbox(2)
    col.mouse_filter = Control.MOUSE_FILTER_IGNORE
    col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(col)
    var name := AstraUI.label(s.name_of(npc_id), AstraUI.T_HEAD, AstraCrewCatalog.accent(npc_id))
    name.name = "Name"
    col.add_child(name)
    col.add_child(AstraUI.label(str(AstraCrewCatalog.info(npc_id).get("job", "")), AstraUI.T_META, AstraUI.MUTED))
    var lead := AstraUI.label("", AstraUI.T_META, AstraUI.GOLD)
    lead.name = "Lead"
    col.add_child(lead)
    var state := AstraUI.label("", AstraUI.T_META, AstraUI.MUTED)
    state.name = "State"
    col.add_child(state)
    card.pressed.connect(_on_person.bind(npc_id))
    return card

func refresh() -> void:
    var s: AstraGameSession = screen.session
    if s.phase != "INTERROGATION":
        return
    var leads := s.talk_leads()
    _people_budget.text = "대화 %d / %d 남음" % [s.conversations_left(), s.conversations_max()]
    _people_budget.add_theme_color_override("font_color", AstraUI.GOLD if s.conversations_left() > 0 else AstraUI.DIM)
    for npc_id in _cards:
        var card: Button = _cards[npc_id]
        var member := s.npc(npc_id)
        var alive := member != null and member.is_alive()
        var open := s.conversation_open(npc_id)
        var lead: Label = card.find_child("Lead", true, false)
        var state: Label = card.find_child("State", true, false)
        lead.text = ("● " + str(leads[npc_id])) if leads.has(npc_id) and alive else ""
        var accent: Color = AstraCrewCatalog.accent(npc_id)
        if not alive:
            state.text = s.status_label(npc_id)
            card.disabled = true
            card.modulate = Color(0.55, 0.57, 0.62)
        elif open:
            state.text = "추가 질문 %d" % s.followups_left(npc_id) if s.followups_left(npc_id) > 0 else "이야기함"
            state.add_theme_color_override("font_color", AstraUI.GREEN)
            card.disabled = false
            card.modulate = Color.WHITE
        else:
            state.text = "대화하기" if s.conversations_left() > 0 else "오늘은 더 못 들음"
            state.add_theme_color_override("font_color", AstraUI.CYAN if s.conversations_left() > 0 else AstraUI.DIM)
            card.disabled = s.conversations_left() <= 0
            card.modulate = Color.WHITE if s.conversations_left() > 0 else Color(0.75, 0.77, 0.82)
        var selected: bool = npc_id == _selected
        card.add_theme_stylebox_override("normal", AstraUI.style(Color(accent, 0.16) if selected else Color(0.03, 0.05, 0.08, 0.92), accent if selected else (Color(AstraUI.GOLD, 0.6) if leads.has(npc_id) and not open and alive else AstraUI.BORDER), 10, 2 if selected else 1, 8))
        card.add_theme_stylebox_override("hover", AstraUI.style(Color(accent, 0.2), accent, 10, 2, 8))
        card.add_theme_stylebox_override("pressed", AstraUI.style(Color(accent, 0.28), accent, 10, 2, 8))
        card.add_theme_stylebox_override("disabled", AstraUI.style(Color(0.03, 0.04, 0.06, 0.85), AstraUI.BORDER, 10, 1, 8))
    _refresh_right()

func _refresh_right() -> void:
    var s: AstraGameSession = screen.session
    var done := s.phase_exhausted()
    _next.visible = s.conversations_used() > 0
    _next.text = "회의 열기  →" if done else "대화를 멈추고 회의 열기  →"
    _analyst.visible = s.analyst_available() and s.conversations_used() > 0
    if _selected == "" or not s.crew.has(_selected):
        _show_empty()
        return
    var member := s.npc(_selected)
    var face := str(FACE_ALIAS.get(member.expression, member.expression))
    _portrait.texture = AstraUI.texture(AstraCrewCatalog.portrait_path(_selected, face))
    _name.text = member.display_name
    _name.add_theme_color_override("font_color", member.accent)
    _job.text = member.job
    AstraUI.clear(_tags)
    var leads := s.talk_leads()
    if leads.has(_selected):
        _tags.add_child(AstraUI.chip(str(leads[_selected]), AstraUI.GOLD, AstraUI.T_META - 2))
    _tags.add_child(AstraUI.chip(member.mood_label(), AstraUI.CYAN, AstraUI.T_META - 2))
    if s.conversation_open(_selected):
        _state.text = "더 물을 수 있음 %d" % s.followups_left(_selected) if s.followups_left(_selected) > 0 else "오늘은 다 물었음"
    else:
        _state.text = "아직 이야기하지 않음"
    _render_log()
    _render_options()

func _show_empty() -> void:
    var s: AstraGameSession = screen.session
    _portrait.texture = null
    _name.text = "대화"
    _name.add_theme_color_override("font_color", AstraUI.TEXT)
    _job.text = ""
    AstraUI.clear(_tags)
    _state.text = ""
    AstraUI.clear(_log)
    AstraUI.clear(_options)
    var hint := "왼쪽에서 한 사람을 누르면 바로 이야기가 시작됩니다.\n그 사람은 %s에 어디 있었는지 말하고, 본 것이 있으면 꺼냅니다." % s.incident_time()
    if s.conversations_left() <= 0:
        hint = "오늘 대화를 모두 썼습니다. 들은 말을 가지고 회의로 가세요."
    _log.add_child(AstraUI.prose(hint, AstraUI.T_BODY, AstraUI.MUTED))

func _render_log() -> void:
    var s: AstraGameSession = screen.session
    AstraUI.clear(_log)
    var entries: Array = []
    for entry in s.transcripts.get(_selected, []):
        if int(entry.get("day", 0)) == s.day:
            entries.append(entry)
    if entries.is_empty():
        _log.add_child(AstraUI.prose("%s에게 %s의 일을 물어볼 수 있습니다. 대화 한 번을 씁니다." % [s.name_of(_selected), s.incident_time()], AstraUI.T_BODY, AstraUI.MUTED))
    for entry in entries:
        _log.add_child(_line_node(str(entry.get("speaker", "")), str(entry.get("text", ""))))
    if entries.size() != _last_lines:
        var start := _last_lines
        _last_lines = entries.size()
        for index in range(maxi(0, start), _log.get_child_count()):
            AstraUI.fade_in(_log.get_child(index), 0.25, 0.12 * float(index - start))
    _log.add_child(AstraUI.bottom_pad())
    # The log is rebuilt after every answer: land on the last line, whole,
    # once the layout has settled.
    AstraUI.follow_bottom(_log_scroll, true)

func _line_node(speaker: String, text: String) -> Control:
    var s: AstraGameSession = screen.session
    if speaker == "player":
        var row := AstraUI.hbox(0)
        row.add_child(AstraUI.spacer())
        var bubble := AstraUI.panel(Color(AstraUI.GOLD, 0.1), Color(AstraUI.GOLD, 0.35), 10, AstraUI.BUBBLE_PADDING)
        bubble.custom_minimum_size.x = 0
        var t := AstraUI.prose(text, AstraUI.T_UI, Color(1, 0.94, 0.8))
        t.custom_minimum_size.x = 360
        bubble.add_child(t)
        row.add_child(bubble)
        # the chosen explorer speaks with their own face
        var face := AstraUI.player_face(s, Vector2(46, 46))
        face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
        row.add_child(face)
        return row
    if speaker == "narration" or speaker == "":
        if text.begins_with("기록 ·"):
            var card := AstraUI.panel(Color(AstraUI.GOLD, 0.08), Color(AstraUI.GOLD, 0.7), 8, 12)
            var box := AstraUI.vbox(2)
            card.add_child(box)
            box.add_child(AstraUI.label("기록", AstraUI.T_META, AstraUI.GOLD))
            box.add_child(AstraUI.prose(text.trim_prefix("기록 ·").strip_edges(), AstraUI.T_UI, AstraUI.TEXT))
            return card
        var n := AstraUI.prose(text, AstraUI.T_META, AstraUI.DIM)
        return n
    var member := s.npc(speaker)
    var accent: Color = member.accent if member != null else AstraUI.CYAN
    var bubble2 := AstraUI.panel(Color(accent, 0.07), Color(accent, 0.35), 10, AstraUI.BUBBLE_PADDING)
    var body := AstraUI.prose(text, AstraUI.T_BODY, AstraUI.TEXT)
    bubble2.add_child(body)
    return bubble2

func _render_options() -> void:
    var s: AstraGameSession = screen.session
    AstraUI.clear(_options)
    var options := s.question_options(_selected)
    if options.is_empty():
        return
    for option in options:
        var intent := str(option.get("intent", ""))
        if intent == "STATEMENT":
            continue
        var tone := str(option.get("tone", ""))
        var accent: Color = AstraUI.RED if tone == "press" else (AstraUI.VIOLET if intent == "EMPATHY" else (AstraUI.GOLD if intent in ["CONFRONT", "RECORD"] else AstraUI.CYAN))
        var button := AstraUI.choice_button(str(option.get("label", "")), accent, AstraUI.T_UI)
        button.disabled = not bool(option.get("enabled", true))
        button.pressed.connect(_ask.bind(intent, str(option.get("ref", ""))))
        _options.add_child(button)
        var hint := str(option.get("hint", ""))
        if hint != "" and intent in ["CONFRONT", "RECORD", "EMPATHY"]:
            _options.add_child(AstraUI.label(hint, AstraUI.T_META - 2, AstraUI.DIM, true))
    _options.add_child(AstraUI.bottom_pad())

func _on_person(npc_id: String) -> void:
    var s: AstraGameSession = screen.session
    if _selected != npc_id:
        _last_lines = 0
    _selected = npc_id
    s.select(npc_id)
    if not s.conversation_open(npc_id) and s.conversations_left() > 0:
        screen.fx.play("select")
        var result := s.ask(npc_id, "STATEMENT")
        _after_result(result)
    refresh()

func _ask(intent: String, ref: String) -> void:
    var s: AstraGameSession = screen.session
    var result := s.ask(_selected, intent, ref)
    if not bool(result.get("ok", false)):
        screen.fx.toast("지금은 그 질문을 할 수 없습니다.", AstraUI.GOLD)
        return
    screen.fx.play("click")
    _after_result(result)
    refresh()

func _after_result(result: Dictionary) -> void:
    # A new record or sighting already appears as a card in the conversation and
    # lights the notebook dot; no toast on top of it.
    if bool(result.get("secret", false)):
        screen.fx.toast("숨긴 사정을 들었습니다. 회의에서 이 사람을 변호할 수 있습니다.", AstraUI.PINK, 2.6)
    if bool(result.get("changed_story", false)):
        screen.fx.toast("말이 바뀌었습니다. 노트에 남았습니다.", AstraUI.RED, 2.4)

func _open_analyst() -> void:
    var s: AstraGameSession = screen.session
    var items := s.analyst_candidates()
    if items.size() < 2:
        screen.fx.toast("대조할 진술이나 기록이 아직 두 개가 안 됩니다.", AstraUI.GOLD)
        return
    var picked: Array = []
    var list := AstraUI.vbox(6)
    list.add_child(AstraUI.prose("두 가지를 고르세요. 같은 사람의 같은 시각을 말하는지, 서로 부딪히는지 알려 줍니다.", AstraUI.T_META, AstraUI.MUTED))
    var holder := []
    for item in items:
        var button := AstraUI.choice_button(str(item["label"]), AstraUI.VIOLET, AstraUI.T_META)
        button.toggle_mode = true
        button.toggled.connect(func(on: bool):
            if on:
                picked.append(str(item["ref"]))
            else:
                picked.erase(str(item["ref"]))
            if picked.size() == 2:
                var result := s.analyst_compare(str(picked[0]), str(picked[1]))
                if not holder.is_empty() and is_instance_valid(holder[0]):
                    holder[0].close(-1)
                if bool(result.get("ok", false)):
                    var said: Dictionary = result.get("reaction", {})
                    var tail := ""
                    if not said.is_empty():
                        tail = "\n%s: “%s”" % [s.name_of(str(said.get("speaker", ""))), str(said.get("text", ""))]
                    screen.fx.toast("정밀 대조 · " + str(result.get("text", "")) + tail, AstraUI.VIOLET, 4.0)
                refresh()
        )
        list.add_child(button)
    var scroll := AstraUI.scroll(list)
    scroll.custom_minimum_size = Vector2(0, 380)
    holder.append(AstraModal.open(screen.app.overlay_root(), "정밀 대조", scroll, [["닫기", AstraUI.MUTED]], Callable(), 700.0))
