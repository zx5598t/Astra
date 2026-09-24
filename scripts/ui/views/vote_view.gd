extends VBoxContainer

# Vote. The two people the room leans toward say one last thing; every person
# is a face you can pick; one confirm. Then each ballot is read out in the
# voter's own words, the pod closes on whoever got the most, and someone close
# to them reacts. No role is shown (§32, §33).

var screen
var _header: Label
var _sub: Label
var _statements: HBoxContainer
var _grid: GridContainer
var _confirm: Button
var _reveal: VBoxContainer
var _reveal_scroll: ScrollContainer
var _after: VBoxContainer
var _choice: String = ""
var _mode: String = "choose"
var _queue: Array = []
var _timer: Timer

func setup(game_screen) -> void:
    screen = game_screen
    add_theme_constant_override("separation", 10)
    _header = AstraUI.label("", AstraUI.T_TITLE, AstraUI.TEXT)
    add_child(_header)
    _sub = AstraUI.prose("", AstraUI.T_UI, AstraUI.MUTED)
    add_child(_sub)
    _statements = AstraUI.hbox(12)
    add_child(_statements)
    _grid = GridContainer.new()
    _grid.columns = 4
    _grid.add_theme_constant_override("h_separation", 10)
    _grid.add_theme_constant_override("v_separation", 10)
    var grid_scroll := AstraUI.scroll(_grid)
    grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    add_child(grid_scroll)
    _reveal = AstraUI.vbox(6)
    _reveal_scroll = AstraUI.scroll(_reveal)
    _reveal_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _reveal_scroll.visible = false
    add_child(_reveal_scroll)
    _after = AstraUI.vbox(8)
    add_child(_after)
    var bottom := AstraUI.hbox(10)
    add_child(bottom)
    bottom.add_child(AstraUI.spacer())
    _confirm = AstraUI.primary_button("한 사람을 고르세요", AstraUI.RED)
    _confirm.custom_minimum_size = Vector2(360, 52)
    _confirm.disabled = true
    _confirm.pressed.connect(_on_confirm)
    bottom.add_child(_confirm)
    _timer = Timer.new()
    _timer.wait_time = 0.1 if AstraUI.reduce_motion else 0.7
    _timer.timeout.connect(_reveal_next)
    add_child(_timer)
    refresh()

func refresh() -> void:
    var s: AstraGameSession = screen.session
    if s.phase != "VOTE" or _mode != "choose":
        return
    var stage := s.vote_stage()
    var pool: Array = s.eligible_vote_targets()
    match stage:
        "RUNOFF":
            _header.text = "결선 투표"
            _sub.text = "최다 득표가 같았습니다. %s 중 한 사람에게 다시 투표합니다. 기권은 없습니다." % s.names_of(s.runoff_candidates())
            pool = s.runoff_candidates()
        "TIEBREAK":
            _header.text = "결선도 동률 · 당신이 정합니다"
            _sub.text = "두 번 모두 표가 갈렸습니다. %s 중 누구를 포드로 보낼지 탐사요원이 결정합니다." % s.names_of(s.runoff_candidates())
            pool = s.runoff_candidates()
        _:
            _header.text = "오늘 한 사람을 장기수면 포드로"
            if s.stage_index() == 1 and s.day == 1:
                _sub.text = "죽이는 게 아니라 이 Stage가 끝날 때까지 재우는 것입니다. 모두 한 표씩, 기권은 없습니다. 정체는 공개되지 않습니다."
            else:
                _sub.text = "모두 한 표씩, 기권은 없습니다."
    _render_statements(stage)
    AstraUI.clear(_grid)
    _grid.columns = 4 if pool.size() > 4 else maxi(2, pool.size())
    for npc_id in pool:
        _grid.add_child(_candidate(str(npc_id)))
    _update_confirm()

func _render_statements(stage: String) -> void:
    var s: AstraGameSession = screen.session
    AstraUI.clear(_statements)
    if stage != "BALLOT":
        _statements.visible = false
        return
    var statements := s.final_statements()
    _statements.visible = not statements.is_empty()
    for entry in statements:
        var id := str(entry.get("id", ""))
        var card := AstraUI.panel(Color(AstraCrewCatalog.accent(id), 0.07), Color(AstraCrewCatalog.accent(id), 0.4), 10, 10)
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var row := AstraUI.hbox(10)
        card.add_child(row)
        var face := AstraUI.thumb(AstraCrewCatalog.portrait_path(id, "determined"), Vector2(64, 80))
        face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        row.add_child(face)
        var col := AstraUI.vbox(2)
        col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(col)
        col.add_child(AstraUI.label("%s · 마지막으로 한마디" % str(entry.get("name", "")), AstraUI.T_META, AstraCrewCatalog.accent(id)))
        col.add_child(AstraUI.prose("“%s”" % str(entry.get("text", "")), AstraUI.T_UI, AstraUI.TEXT))
        _statements.add_child(card)

func _candidate(npc_id: String) -> Button:
    var s: AstraGameSession = screen.session
    var member := s.npc(npc_id)
    var accent: Color = member.accent
    var selected := npc_id == _choice
    var card := Button.new()
    card.custom_minimum_size = Vector2(170, 232)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    card.add_theme_stylebox_override("normal", AstraUI.style(Color(accent, 0.22) if selected else Color(0.03, 0.05, 0.08, 0.92), accent if selected else AstraUI.BORDER, 12, 3 if selected else 1, 6))
    card.add_theme_stylebox_override("hover", AstraUI.style(Color(accent, 0.18), accent, 12, 2, 6))
    card.add_theme_stylebox_override("pressed", AstraUI.style(Color(accent, 0.28), accent, 12, 3, 6))
    var col := AstraUI.vbox(2)
    col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    col.offset_left = 6
    col.offset_right = -6
    col.offset_top = 6
    col.offset_bottom = -6
    col.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(col)
    var face := AstraUI.thumb(AstraCrewCatalog.portrait_path(npc_id, "suspicious" if selected else "neutral"), Vector2(150, 170))
    face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    face.size_flags_vertical = Control.SIZE_EXPAND_FILL
    col.add_child(face)
    var name := AstraUI.label(member.display_name, AstraUI.T_HEAD, accent)
    name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    col.add_child(name)
    var job := AstraUI.label(member.job, AstraUI.T_META, AstraUI.MUTED)
    job.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    col.add_child(job)
    card.pressed.connect(func():
        _choice = npc_id
        screen.fx.play("select")
        refresh()
    )
    return card

func _update_confirm() -> void:
    var s: AstraGameSession = screen.session
    if _choice == "" or (s.vote_stage() in ["RUNOFF", "TIEBREAK"] and _choice not in s.runoff_candidates()):
        _choice = "" if s.vote_stage() in ["RUNOFF", "TIEBREAK"] and _choice not in s.runoff_candidates() else _choice
        _confirm.text = "한 사람을 고르세요"
        _confirm.disabled = true
        return
    _confirm.disabled = false
    _confirm.text = ("%s|eul 포드로 보낸다" if s.vote_stage() == "TIEBREAK" else "%s에게 투표한다") % s.name_of(_choice)
    _confirm.text = s._josa_inline(_confirm.text)

func _on_confirm() -> void:
    var s: AstraGameSession = screen.session
    if _choice == "":
        return
    var before := s.vote_stage()
    var result := s.resolve_tiebreak(_choice) if before == "TIEBREAK" else s.cast_vote(_choice)
    if not bool(result.get("ok", false)):
        screen.fx.toast("그 사람에게는 투표할 수 없습니다.", AstraUI.GOLD)
        return
    screen.fx.play("alert")
    _choice = ""
    _mode = "reveal"
    _statements.visible = false
    _grid.get_parent().visible = false
    _confirm.visible = false
    _reveal_scroll.visible = true
    AstraUI.clear(_reveal)
    _queue.clear()
    if before != "TIEBREAK":
        _header.text = "투표 결과" if before == "BALLOT" else "결선 투표 결과"
        _sub.text = "한 사람씩 표를 밝힙니다."
        for ballot in s.vote_ballots():
            _queue.append(ballot)
    # The first vote of the campaign is revealed slowly; after that a little
    # faster, and Space / Enter shows everything at once (§34).
    if AstraUI.reduce_motion:
        _timer.wait_time = 0.1
    else:
        _timer.wait_time = 0.7 if s.stage_index() == 1 and s.day == 1 and before == "BALLOT" else 0.4
    _timer.start()
    _reveal_next()

func _reveal_next() -> void:
    var s: AstraGameSession = screen.session
    if _queue.is_empty():
        _timer.stop()
        _finish_reveal()
        return
    var ballot: Dictionary = _queue.pop_front()
    var voter := str(ballot.get("voter", ""))
    var target := str(ballot.get("target", ""))
    var row := AstraUI.hbox(10)
    if voter == "player":
        row.add_child(AstraUI.player_face(s, Vector2(30, 30)))
        row.add_child(AstraUI.label(AstraUI.player_name(s), AstraUI.T_UI, AstraUI.GOLD))
    else:
        row.add_child(AstraUI.crew_dot(voter, 30))
        row.add_child(AstraUI.label(s.name_of(voter), AstraUI.T_UI, AstraCrewCatalog.accent(voter)))
    row.add_child(AstraUI.label("→", AstraUI.T_UI, AstraUI.MUTED))
    row.add_child(AstraUI.label(s.name_of(target), AstraUI.T_UI, AstraUI.TEXT))
    var line := str(ballot.get("line", ""))
    if line != "" and voter != "player":
        var quote := AstraUI.label("“%s”" % line, AstraUI.T_META, AstraUI.MUTED, true)
        row.add_child(quote)
    _reveal.add_child(row)
    AstraUI.fade_in(row, 0.2)
    screen.fx.play("tick")

func _finish_reveal() -> void:
    var s: AstraGameSession = screen.session
    AstraUI.clear(_after)
    var tally: Dictionary = s.last_vote.get("tally", {})
    if not tally.is_empty():
        var parts: Array = []
        var keys := tally.keys()
        keys.sort_custom(func(a, b): return int(tally[a]) > int(tally[b]))
        for key in keys:
            parts.append("%s %d" % [s.name_of(str(key)), int(tally[key])])
        _after.add_child(AstraUI.label("득표 · " + "  ·  ".join(PackedStringArray(parts)), AstraUI.T_UI, AstraUI.GOLD))
    if s.vote_stage() in ["RUNOFF", "TIEBREAK"] and not s.vote_cast:
        _after.add_child(AstraUI.prose(s.vote_result_text(), AstraUI.T_BODY, AstraUI.TEXT))
        var again := AstraUI.primary_button("결선으로  →" if s.vote_stage() == "RUNOFF" else "내가 정한다  →", AstraUI.RED)
        again.custom_minimum_size.y = 50
        again.pressed.connect(func():
            _mode = "choose"
            _reveal_scroll.visible = false
            _grid.get_parent().visible = true
            _confirm.visible = true
            AstraUI.clear(_after)
            refresh()
        )
        _after.add_child(again)
        return
    # The pod closes: the isolated person's last line, one close person's
    # reaction, then the ship. Two to four beats (§33).
    _header.text = s._josa_inline("%s|i 장기수면 포드로 들어간다" % s.name_of(str(s.last_vote.get("isolated", ""))))
    _sub.text = "정체는 공개되지 않습니다."
    var beats := AstraUI.panel(Color(0.02, 0.03, 0.06, 0.94), Color(AstraUI.VIOLET, 0.4), 12, 14)
    _after.add_child(beats)
    var box := AstraUI.vbox(8)
    beats.add_child(box)
    for beat in s.last_vote.get("aftermath", []):
        var speaker := str(beat.get("speaker", ""))
        var kind := str(beat.get("kind", ""))
        if kind in ["target", "observer"] and s.crew.has(speaker):
            var row := AstraUI.hbox(10)
            var face := AstraUI.thumb(AstraCrewCatalog.portrait_path(speaker, "sad"), Vector2(60, 74))
            face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            row.add_child(face)
            var col := AstraUI.vbox(2)
            col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            col.add_child(AstraUI.label(s.name_of(speaker), AstraUI.T_META, AstraCrewCatalog.accent(speaker)))
            col.add_child(AstraUI.prose(str(beat.get("text", "")), AstraUI.T_BODY, AstraUI.TEXT))
            row.add_child(col)
            box.add_child(row)
        else:
            box.add_child(AstraUI.prose(str(beat.get("text", "")), AstraUI.T_META, AstraUI.MUTED))
    AstraUI.fade_in(beats, 0.4)
    var next := AstraUI.primary_button("", AstraUI.NIGHT)
    next.custom_minimum_size.y = 52
    if s.outcome != "":
        next.text = "결과 보기  →"
    elif s.night_needs_choice():
        next.text = "밤 · 지킬 사람 고르기  →"
    else:
        next.text = "밤이 온다  →"
    next.pressed.connect(func(): screen.advance_phase())
    _after.add_child(next)

func consume_advance() -> bool:
    if _mode == "reveal" and not _queue.is_empty():
        while not _queue.is_empty():
            _reveal_next()
        _timer.stop()
        _finish_reveal()
        return true
    return false
