extends VBoxContainer

# Public meeting: statements play out one by one (skippable), live vote
# intentions, and the player's two actions: present a clue, accuse, defend.

const KIND_TAGS := {
    "alibi": ["알리바이", AstraUI.MUTED],
    "dispute": ["반박", AstraUI.RED],
    "suspect": ["의심", AstraUI.GOLD],
    "defense": ["해명", AstraUI.GREEN],
    "react": ["반응", AstraUI.CYAN],
    "mourn": ["애도", AstraUI.NIGHT],
    "calm": ["중재", AstraUI.GREEN],
    "record": ["기록 공개", AstraUI.PINK],
    "player": ["조사관", AstraUI.CYAN]
}

var screen
var _header: RichTextLabel
var _feed_box: VBoxContainer
var _feed_scroll: ScrollContainer
var _tally: HFlowContainer
var _actions: HBoxContainer
var _shown: int = 0
var _queue: Array = []
var _timer: Timer
var _skip: Button

func setup(game_screen) -> void:
    screen = game_screen
    add_theme_constant_override("separation", 10)
    size_flags_vertical = Control.SIZE_EXPAND_FILL
    var head_row := AstraUI.hbox(8)
    add_child(head_row)
    _header = AstraUI.rich(18)
    head_row.add_child(_header)
    _skip = AstraUI.button("발언 모두 보기", AstraUI.MUTED, 13, 32)
    _skip.pressed.connect(_flush)
    head_row.add_child(_skip)

    var panel := AstraUI.panel(Color(AstraUI.BG, 0.55), AstraUI.BORDER, 10, 10)
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    add_child(panel)
    _feed_box = AstraUI.vbox(8)
    _feed_scroll = AstraUI.scroll(_feed_box)
    panel.add_child(_feed_scroll)

    var tally_row := AstraUI.hbox(8)
    add_child(tally_row)
    tally_row.add_child(AstraUI.label("투표 의향", 13, AstraUI.GOLD))
    _tally = HFlowContainer.new()
    _tally.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _tally.add_theme_constant_override("h_separation", 6)
    tally_row.add_child(_tally)

    _actions = AstraUI.hbox(8)
    add_child(_actions)

    _timer = Timer.new()
    _timer.one_shot = false
    _timer.timeout.connect(_reveal_next)
    add_child(_timer)
    refresh()

func refresh() -> void:
    var session: AstraGameSession = screen.session
    _header.text = "[b]공개 회의 · DAY %d[/b]   [color=#%s]발언권[/color] %s" % [session.day, AstraUI.hex(AstraUI.MUTED), AstraUI.pips(session.meeting_actions_left, session.meeting_actions_max(), AstraUI.CYAN)]
    var total := session.meeting_feed.size()
    var pending := _shown + _queue.size()
    if total < pending:
        AstraUI.clear(_feed_box)
        _shown = 0
        _queue.clear()
        pending = 0
    for index in range(pending, total):
        _queue.append(session.meeting_feed[index])
    if not _queue.is_empty() and _timer.is_stopped():
        _timer.wait_time = clampf(0.55 / maxf(0.25, float(screen.app.settings.meeting_speed)), 0.12, 1.5)
        if is_inside_tree():
            _timer.start()
            _reveal_next()
        else:
            _flush()
    _skip.visible = not _queue.is_empty()
    _refresh_tally(session)
    _refresh_actions(session)

func _reveal_next() -> void:
    if _queue.is_empty():
        _timer.stop()
        _skip.visible = false
        return
    var entry: Dictionary = _queue.pop_front()
    _add_entry(entry, true)
    if _queue.is_empty():
        _timer.stop()
        _skip.visible = false

func _flush() -> void:
    _timer.stop()
    while not _queue.is_empty():
        _add_entry(_queue.pop_front(), false)
    _skip.visible = false

func _add_entry(entry: Dictionary, animate: bool) -> void:
    var session: AstraGameSession = screen.session
    _shown += 1
    var speaker := str(entry.get("speaker", ""))
    var kind := str(entry.get("kind", ""))
    var tag: Array = KIND_TAGS.get(kind, ["발언", AstraUI.MUTED])
    var is_player := speaker == "player"
    var accent: Color = AstraUI.CYAN if is_player else AstraCrewCatalog.accent(speaker)
    var card := AstraUI.panel(Color(accent, 0.1) if is_player else AstraUI.PANEL_2, Color(accent, 0.5 if is_player else 0.22), 10, 10)
    var row := AstraUI.hbox(10)
    card.add_child(row)
    if not is_player:
        var mood := "tense" if kind in ["dispute", "defense"] else ("warm" if kind == "calm" else "calm")
        row.add_child(AstraUI.thumb(AstraCrewCatalog.portrait_path(speaker, mood), Vector2(40, 50)))
    var box := AstraUI.vbox(3)
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(box)
    var head := AstraUI.hbox(6)
    box.add_child(head)
    head.add_child(AstraUI.label("조사관" if is_player else session.name_of(speaker), 15, accent))
    head.add_child(AstraUI.chip(str(tag[0]), tag[1], 11))
    var target := str(entry.get("target", ""))
    if target != "" and not is_player and kind in ["dispute", "suspect", "react"]:
        head.add_child(AstraUI.label("→ " + session.name_of(target), 12, AstraUI.DIM))
    box.add_child(AstraUI.label(str(entry.get("text", "")), 15, AstraUI.TEXT, true))
    _feed_box.add_child(card)
    if animate:
        AstraUI.fade_in(card, 0.2)
        if kind == "dispute":
            screen.fx.play("alert")
        else:
            screen.fx.play("talk")
    _scroll_to_bottom.call_deferred()

func _scroll_to_bottom() -> void:
    if _feed_scroll != null and is_instance_valid(_feed_scroll):
        _feed_scroll.scroll_vertical = int(_feed_scroll.get_v_scroll_bar().max_value)

func _refresh_tally(session: AstraGameSession) -> void:
    AstraUI.clear(_tally)
    var tally := session.vote_tally("")
    var ids: Array = tally.keys()
    ids.sort_custom(func(a, b): return int(tally[a]) > int(tally[b]))
    if ids.is_empty():
        _tally.add_child(AstraUI.label("아직 없음", 13, AstraUI.DIM))
    for npc_id in ids.slice(0, 5):
        _tally.add_child(AstraUI.chip("%s %d표" % [session.name_of(str(npc_id)), int(tally[npc_id])], AstraCrewCatalog.accent(str(npc_id)), 13))

func _refresh_actions(session: AstraGameSession) -> void:
    AstraUI.clear(_actions)
    var left := session.meeting_actions_left > 0
    var target: String = screen.selected_id()
    var target_ok := left and session.is_alive(target)
    var unpublished := 0
    for clue in session.found_clues():
        if not bool(clue.get("public", false)):
            unpublished += 1
    var present := AstraUI.button("단서 공개… (%d)" % unpublished, AstraUI.GOLD, 15, 46)
    present.disabled = not left or unpublished == 0
    present.tooltip_text = "확보한 단서를 모두에게 공개합니다. 출입 기록은 거짓 진술을 드러내고, 흔적은 후보 명단에 대한 의심을 키웁니다."
    present.pressed.connect(_present)
    present.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _actions.add_child(present)
    var target_name := session.name_of(target) if target != "" else "?"
    var accuse := AstraUI.button("지목 · " + target_name, AstraUI.RED, 15, 46)
    accuse.disabled = not target_ok
    accuse.tooltip_text = "명단에서 고른 사람을 공개적으로 지목합니다. 공개된 근거가 있을수록 설득력이 커지고, 근거가 없으면 조사관의 신뢰가 떨어집니다."
    accuse.pressed.connect(_accuse)
    accuse.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _actions.add_child(accuse)
    var defend := AstraUI.button("변호 · " + target_name, AstraUI.GREEN, 15, 46)
    defend.disabled = not target_ok
    defend.tooltip_text = "명단에서 고른 사람을 변호합니다. 출입 기록으로 확인됐거나 숨긴 사정을 밝혀낸 사람이라면 효과가 큽니다."
    defend.pressed.connect(_defend)
    defend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _actions.add_child(defend)

func _present() -> void:
    var session: AstraGameSession = screen.session
    var options: Array = []
    for clue in session.found_clues():
        if not bool(clue.get("public", false)):
            options.append(clue)
    screen.open_clue_picker("어떤 단서를 공개할까요?", options, func(clue_id: String):
        if bool(session.present_clue(clue_id).get("ok", false)):
            screen.fx.play("clue")
    )

func _accuse() -> void:
    var session: AstraGameSession = screen.session
    var result := session.accuse(screen.selected_id())
    if bool(result.get("ok", false)):
        screen.fx.play("alert")
        if float(result.get("support", 0.0)) < 0.25:
            screen.fx.toast("근거 없는 지목이었습니다. 승무원들의 신뢰가 조금 떨어졌습니다.", AstraUI.RED)

func _defend() -> void:
    var session: AstraGameSession = screen.session
    if bool(session.defend(screen.selected_id()).get("ok", false)):
        screen.fx.play("save")
