extends VBoxContainer

# The public meeting.
#
# 0.3.1 played the whole meeting on a 0.55-second timer. Eight people spoke,
# the feed scrolled, and by the time the player had read the third line the
# eighth had already gone past. The information was all there and none of it
# landed, which is why the meeting felt like log output rather than an argument.
#
# 0.4.0 reverses the default: nothing advances until the player asks for it.
# Auto is available, and even on auto the lines that carry a contradiction, a
# first appearance, a retraction or a death stop and wait (§20, §59).
#
# The feed still accumulates — a new line never replaces the last one — because
# the entire skill of this phase is comparing what somebody just said with what
# they said earlier.

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

# Lines the player is never allowed to blink past, even with auto on.
const IMPORTANT_KINDS := ["dispute", "record", "defense"]

var screen
var _header: RichTextLabel
var _feed_box: VBoxContainer
var _feed_scroll: ScrollContainer
var _actions: HBoxContainer
var _next_row: HBoxContainer
var _next_button: Button
var _auto_toggle: Button
var _shown: int = 0
var _queue: Array = []
var _timer: Timer
var _seen_speakers: Dictionary = {}

func setup(game_screen) -> void:
    screen = game_screen
    add_theme_constant_override("separation", 10)
    size_flags_vertical = Control.SIZE_EXPAND_FILL

    var head_row := AstraUI.hbox(10)
    add_child(head_row)
    _header = AstraUI.rich(AstraUI.T_HEAD)
    head_row.add_child(_header)
    _auto_toggle = AstraUI.button("자동 진행", AstraUI.MUTED, AstraUI.T_META, 34)
    _auto_toggle.tooltip_text = AstraCodex.tooltip("auto")
    _auto_toggle.pressed.connect(_toggle_auto)
    head_row.add_child(_auto_toggle)
    var log_button := AstraUI.button("전체 기록", AstraUI.MUTED, AstraUI.T_META, 34)
    log_button.tooltip_text = AstraCodex.tooltip("log")
    log_button.pressed.connect(_open_log)
    head_row.add_child(log_button)

    var panel := AstraUI.panel(Color(AstraUI.BG, 0.62), AstraUI.BORDER, 10, 12)
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    add_child(panel)
    _feed_box = AstraUI.vbox(10)
    _feed_scroll = AstraUI.scroll(_feed_box)
    panel.add_child(_feed_scroll)

    # The "next speaker" control is the primary action of this screen while
    # anyone is still waiting to talk; the meeting actions sit below it and are
    # only reachable once the room has finished speaking its current round.
    _next_row = AstraUI.hbox(10)
    add_child(_next_row)
    _next_button = AstraUI.button("다음 발언  ▸", AstraUI.CYAN, AstraUI.T_UI, 46, true)
    _next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _next_button.pressed.connect(_reveal_next)
    _next_row.add_child(_next_button)
    # Explicitly asking for the rest of the round is fine; having it happen on a
    # timer is what 0.4.0 removes.
    var all_button := AstraUI.button("남은 발언 모두 보기", AstraUI.MUTED, AstraUI.T_META, 46)
    all_button.pressed.connect(_flush)
    _next_row.add_child(all_button)

    _actions = AstraUI.hbox(8)
    add_child(_actions)

    _timer = Timer.new()
    _timer.one_shot = true
    _timer.timeout.connect(_on_auto_tick)
    add_child(_timer)
    refresh()

# How many statements are still waiting, so the objective line in the header can
# say "listen" rather than "act" while the room is still talking.
func pending_lines() -> int:
    return _queue.size()

# Called by the game screen so Space steps the transcript instead of skipping
# the phase. Returns true when it consumed the key.
func consume_advance() -> bool:
    if _queue.is_empty():
        return false
    _reveal_next()
    return true

func _notify_screen() -> void:
    if screen != null and screen.has_method("refresh_objective"):
        screen.refresh_objective()

func refresh() -> void:
    var session: AstraGameSession = screen.session
    var waiting := _queue.size()
    _header.text = "[b]공개 회의 · DAY %d[/b]" % session.day
    var total := session.meeting_feed.size()
    var pending := _shown + _queue.size()
    if total < pending:
        AstraUI.clear(_feed_box)
        _shown = 0
        _queue.clear()
        pending = 0
    for index in range(pending, total):
        _queue.append(session.meeting_feed[index])
    if waiting == 0 and not _queue.is_empty():
        _schedule_auto()
    _refresh_next_row(session)
    _refresh_actions(session)

func _refresh_next_row(_session: AstraGameSession) -> void:
    var waiting := _queue.size()
    _next_row.visible = waiting > 0
    if waiting > 0:
        _next_button.text = "다음 발언  ▸    (%d건 남음)" % waiting if waiting > 1 else "다음 발언  ▸    (마지막)"

func _toggle_auto() -> void:
    var settings = screen.app.settings
    settings.auto_advance = not settings.auto_advance
    settings.save_data()
    _auto_toggle.text = "자동 진행 · 켬" if settings.auto_advance else "자동 진행"
    if settings.auto_advance:
        _schedule_auto()

func _schedule_auto() -> void:
    var settings = screen.app.settings
    if not settings.auto_advance or _queue.is_empty() or not is_inside_tree():
        return
    if settings.pause_on_important and _is_important(_queue[0]):
        return
    # Longer lines get longer on screen. A fixed interval is what made the old
    # meeting unreadable: a twelve-word accusation and a two-word grunt were
    # given the same time.
    var text := str(_queue[0].get("text", ""))
    var seconds: float = clampf(1.4 + float(text.length()) * 0.055, 1.6, 6.0) * float(settings.auto_delay)
    _timer.wait_time = seconds
    _timer.start()

func _on_auto_tick() -> void:
    _reveal_next()

func _is_important(entry: Dictionary) -> bool:
    var session: AstraGameSession = screen.session
    if str(entry.get("kind", "")) in IMPORTANT_KINDS:
        return true
    var speaker := str(entry.get("speaker", ""))
    # First time this person speaks in this meeting, or they are standing on a
    # contradiction the player has already uncovered.
    if speaker != "player" and not _seen_speakers.has(speaker):
        return true
    return session.has_contradiction_on(speaker)

func _reveal_next() -> void:
    _timer.stop()
    if _queue.is_empty():
        _refresh_next_row(screen.session)
        return
    _add_entry(_queue.pop_front())
    _refresh_next_row(screen.session)
    _refresh_actions(screen.session)
    _notify_screen()
    _schedule_auto()

# Player-initiated: show everything that is still waiting. Used by the button
# above and by the automated UI run.
func _flush() -> void:
    _timer.stop()
    while not _queue.is_empty():
        _add_entry(_queue.pop_front())
    _refresh_next_row(screen.session)
    _refresh_actions(screen.session)
    _notify_screen()

func _add_entry(entry: Dictionary) -> void:
    var session: AstraGameSession = screen.session
    _shown += 1
    var speaker := str(entry.get("speaker", ""))
    var kind := str(entry.get("kind", ""))
    var tag: Array = KIND_TAGS.get(kind, ["발언", AstraUI.MUTED])
    var is_player := speaker == "player"
    var accent: Color = AstraUI.CYAN if is_player else AstraCrewCatalog.accent(speaker)
    if not is_player:
        _seen_speakers[speaker] = true
    var card := AstraUI.speaker_card(
        speaker,
        "조사관" if is_player else "%s (%s)" % [session.name_of(speaker), AstraCrewCatalog.role_short(speaker)],
        str(tag[0]), tag[1],
        str(entry.get("text", "")),
        accent, is_player
    )
    _feed_box.add_child(card)

    # When somebody has just contradicted themselves, the player gets a chance
    # to say so on the spot. The game does not say "this is a lie" — it offers
    # the move and leaves the reading to the player (§4, §28).
    if not is_player and session.has_feature("claim_search"):
        var changed: Array = session.changed_story(speaker)
        if not changed.is_empty() and not _feed_box.has_meta("challenged_" + speaker):
            _feed_box.set_meta("challenged_" + speaker, true)
            _feed_box.add_child(_challenge_row(speaker, changed[0]))

    AstraUI.fade_in(card, 0.16)
    screen.fx.play("alert" if kind == "dispute" else "talk")
    _scroll_to_bottom.call_deferred()

func _challenge_row(speaker: String, conflict: Dictionary) -> Control:
    var session: AstraGameSession = screen.session
    var card := AstraUI.panel(Color(AstraUI.GOLD, 0.08), Color(AstraUI.GOLD, 0.45), 8, 10)
    var box := AstraUI.vbox(6)
    card.add_child(box)
    box.add_child(AstraUI.label("이전 발언과 다릅니다", AstraUI.T_META, AstraUI.GOLD))
    box.add_child(AstraUI.prose(str(conflict.get("reason", "")), AstraUI.T_META, AstraUI.MUTED))
    var row := AstraUI.hbox(8)
    box.add_child(row)
    var press := AstraUI.button("지금 짚는다", AstraUI.GOLD, AstraUI.T_UI, 38)
    press.pressed.connect(func():
        session.record_player_claim(AstraClaimLedger.KIND_WITNESS,
            "%s|i 앞서 한 말과 지금 한 말이 다르다고 지적했다." % session.name_of(speaker), {"target": speaker})
        session.accuse(speaker)
        card.queue_free()
    )
    row.add_child(press)
    var hold := AstraUI.button("일단 넘어간다", AstraUI.MUTED, AstraUI.T_UI, 38)
    hold.pressed.connect(func(): card.queue_free())
    row.add_child(hold)
    return card

func _open_log() -> void:
    var session: AstraGameSession = screen.session
    var box := AstraUI.vbox(8)
    for entry in session.meeting_feed:
        var speaker := str(entry.get("speaker", ""))
        var line := AstraUI.prose("[%s] %s" % ["조사관" if speaker == "player" else session.name_of(speaker), str(entry.get("text", ""))], AstraUI.T_META, AstraUI.TEXT)
        box.add_child(line)
    var scroller := AstraUI.scroll(box)
    scroller.custom_minimum_size.y = 460
    AstraModal.open(screen.app.overlay_root(), "회의 기록 · DAY %d" % session.day, scroller, [["닫기", AstraUI.MUTED]], Callable(), 760.0)

# Godot only knows how tall the feed is after the new card has been laid out,
# so a single deferred call lands on the old maximum and leaves the newest line
# below the fold. Waiting for the container to finish sorting, then scrolling,
# is what makes "다음 발언" actually show the next speaker.
# Godot only knows how tall the feed is after the new card has been laid out, so
# the scroll is applied one more deferred hop later. This used to be an `await`
# coroutine, which held a reference to the whole feed and leaked the UI tree at
# shutdown when the view was freed mid-await.
func _scroll_to_bottom() -> void:
    if _feed_scroll == null or not is_instance_valid(_feed_scroll) or not is_inside_tree():
        return
    _apply_scroll.call_deferred()

func _apply_scroll() -> void:
    if _feed_scroll == null or not is_instance_valid(_feed_scroll) or not is_inside_tree():
        return
    var bar := _feed_scroll.get_v_scroll_bar()
    _feed_scroll.scroll_vertical = int(bar.max_value)
    if _feed_box.get_child_count() > 0:
        var last := _feed_box.get_child(_feed_box.get_child_count() - 1)
        if last is Control:
            _feed_scroll.ensure_control_visible(last)

func _refresh_actions(session: AstraGameSession) -> void:
    AstraUI.clear(_actions)
    # While people are still speaking, the meeting controls stay out of the way.
    # The one thing to do right now is listen to the next person.
    if not _queue.is_empty():
        _actions.add_child(AstraUI.label("발언이 끝나면 개입할 수 있습니다.", AstraUI.T_META, AstraUI.DIM))
        return
    var left := session.meeting_actions_left > 0
    var target: String = screen.selected_id()
    var target_ok := left and session.is_alive(target)
    var unpublished := 0
    for clue in session.found_clues():
        if not bool(clue.get("public", false)):
            unpublished += 1

    var present := AstraUI.button("단서 공개…", AstraUI.GOLD, AstraUI.T_UI, 46)
    present.disabled = not left or unpublished == 0
    present.tooltip_text = AstraCodex.tooltip("present")
    present.pressed.connect(_present)
    present.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _actions.add_child(present)

    var target_name := session.name_of(target) if target != "" else "?"
    var accuse := AstraUI.button("지목 · " + target_name, AstraUI.RED, AstraUI.T_UI, 46)
    accuse.disabled = not target_ok
    accuse.tooltip_text = AstraCodex.tooltip("accuse")
    accuse.pressed.connect(_accuse)
    accuse.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _actions.add_child(accuse)

    var defend := AstraUI.button("변호 · " + target_name, AstraUI.GREEN, AstraUI.T_UI, 46)
    defend.disabled = not target_ok
    defend.tooltip_text = AstraCodex.tooltip("defend")
    defend.pressed.connect(_defend)
    defend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _actions.add_child(defend)

    # The move that makes two people answer each other rather than answer you.
    var candidates := session.confront_candidates(target)
    var confront := AstraUI.button("대질 · " + target_name, AstraUI.VIOLET, AstraUI.T_UI, 46)
    confront.disabled = not left or candidates.is_empty()
    confront.tooltip_text = AstraCodex.tooltip("confront")
    confront.pressed.connect(_confront)
    confront.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _actions.add_child(confront)

    if session.has_feature("hypothesis"):
        var hypothesis := AstraUI.button("나의 가설…", AstraUI.CYAN, AstraUI.T_UI, 46)
        hypothesis.disabled = not left or session.hypotheses().is_empty()
        hypothesis.pressed.connect(_hypothesis)
        _actions.add_child(hypothesis)

func _present() -> void:
    var session: AstraGameSession = screen.session
    var options: Array = []
    for clue in session.found_clues():
        if not bool(clue.get("public", false)):
            options.append(clue)
    screen.open_clue_picker("어떤 단서를 공개할까요?", options, func(clue_id: String):
        if bool(session.present_clue(clue_id).get("ok", false)):
            session.record_player_claim(AstraClaimLedger.KIND_WITNESS, "단서를 공개했다: " + str(session.clue_by_id(clue_id).get("title", "")))
            screen.fx.play("clue")
    )

func _accuse() -> void:
    var session: AstraGameSession = screen.session
    var result := session.accuse(screen.selected_id())
    if bool(result.get("ok", false)):
        screen.fx.play("alert")
        if float(result.get("support", 0.0)) < 0.25:
            screen.fx.toast("몇 사람이 시선을 피한다. 아직 이들을 납득시키지 못한 듯하다.", AstraUI.MUTED)

func _defend() -> void:
    var session: AstraGameSession = screen.session
    if bool(session.defend(screen.selected_id()).get("ok", false)):
        screen.fx.play("save")

func _hypothesis() -> void:
    var session: AstraGameSession = screen.session
    var box := AstraUI.vbox(8)
    var holder := []
    var links := session.hypotheses()
    for index in range(links.size()):
        var link: Dictionary = links[index]
        var button := AstraUI.button(session.name_of(str(link["npc"])) + " / " + str(link["relation"]) + " / " + str(session.clue_by_id(str(link["clue"])).get("title", "")), AstraUI.CYAN, AstraUI.T_UI, 48)
        button.disabled = not session.is_alive(str(link["npc"]))
        button.pressed.connect(func():
            if not holder.is_empty():
                holder[0].close(-1)
            session.present_hypothesis(index)
        )
        box.add_child(button)
    var scroll := AstraUI.scroll(box)
    scroll.custom_minimum_size.y = 360
    holder.append(AstraModal.open(screen.app.overlay_root(), "어떤 가설을 말할까?", scroll, [["닫기", AstraUI.MUTED]], Callable(), 850))

# Pick who to put opposite the selected person. Only people whose statement
# actually touches theirs are offered, with the reason on the button, so the
# player is choosing an argument rather than guessing at a pairing.
func _confront() -> void:
    var session: AstraGameSession = screen.session
    var target: String = screen.selected_id()
    var candidates := session.confront_candidates(target)
    if candidates.is_empty():
        return
    var box := AstraUI.vbox(8)
    box.add_child(AstraUI.prose("%s와 함께 다시 말하게 할 사람을 고르세요. 두 사람의 진술이 맞으면 오히려 둘 다 의심에서 멀어집니다." % session.name_of(target), AstraUI.T_BODY, AstraUI.TEXT))
    var holder := []
    for candidate in candidates:
        var other := str(candidate["id"])
        var row := AstraUI.vbox(1)
        var button := AstraUI.button(session.name_of(other) + "  (" + AstraCrewCatalog.role_short(other) + ")", AstraUI.VIOLET, AstraUI.T_UI, 46)
        button.icon = AstraUI.texture(AstraCrewCatalog.dot_path(other))
        button.expand_icon = true
        button.add_theme_constant_override("icon_max_width", 34)
        button.pressed.connect(func():
            if not holder.is_empty() and is_instance_valid(holder[0]):
                holder[0].close(-1)
            _do_confront(target, other)
        )
        row.add_child(button)
        row.add_child(AstraUI.label(str(candidate["reason"]), AstraUI.T_META, AstraUI.DIM))
        box.add_child(row)
    holder.append(AstraModal.open(screen.app.overlay_root(), "누구와 대질할까요?", box, [["취소", AstraUI.MUTED]], Callable(), 620.0))

func _do_confront(a_id: String, b_id: String) -> void:
    var session: AstraGameSession = screen.session
    var result := session.confront(a_id, b_id)
    if not bool(result.get("ok", false)):
        return
    if bool(result.get("conflict", false)):
        screen.fx.play("slip")
        screen.fx.banner("진술 충돌", "%s와 %s의 말이 맞지 않는다." % [session.name_of(a_id), session.name_of(b_id)], AstraUI.RED, 1.3)
    else:
        screen.fx.play("save")
        screen.fx.toast("두 사람의 말이 맞았다. 이제 둘을 몰아가기는 더 어려워졌다.", AstraUI.GREEN, 4.0)
