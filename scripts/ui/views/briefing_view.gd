extends Control

# Morning (BRIEFING): the Day opens as a scene, not a report. People say what
# happened overnight and what went wrong today, in their own words, with their
# faces large on screen. One click per beat; a beat can be a few sentences.
# When the last beat is read the Day moves on by itself — there is no separate
# "start" button to press (§45, §47).

var screen
var _stage: AstraVNStage
var _skip: Button
var _finished_sent: bool = false

func setup(game_screen) -> void:
    screen = game_screen
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _stage = AstraVNStage.new()
    add_child(_stage)
    _stage.advanced.connect(_on_advance)
    _stage.chose.connect(_on_choose)
    _skip = AstraUI.button("장면 넘기기  ▸▸", AstraUI.MUTED, AstraUI.T_META, 34)
    _skip.anchor_left = 1.0
    _skip.anchor_right = 1.0
    _skip.offset_left = -190.0
    _skip.offset_right = -14.0
    _skip.offset_top = 12.0
    _skip.offset_bottom = 46.0
    _skip.tooltip_text = "선택이 필요한 장면이 나오거나 아침이 끝날 때까지 넘깁니다."
    _skip.pressed.connect(func():
        screen.session.story_skip()
    )
    add_child(_skip)
    refresh()

func refresh() -> void:
    var s: AstraGameSession = screen.session
    var scene := s.story_scene()
    if scene.is_empty():
        _finish()
        return
    # A playable scene takes the whole view until it is done (§8: pixel
    # characters for space and movement, portraits for feeling).
    if str(scene.get("kind", "")) == "interlude":
        _open_interlude(str(scene.get("interlude", "")))
        return
    _close_interlude()
    var lines: Array = scene.get("lines", [])
    var index := clampi(s.story_line_index(), 0, maxi(0, lines.size() - 1))
    var line: Array = lines[index] if not lines.is_empty() else ["", ""]
    var speaker := str(line[0])
    var text := str(line[1])
    var choices: Array = scene.get("choices", []) if index >= lines.size() - 1 else []
    var art := AstraArt.beat_art(scene, s.case_id)
    var kind := str(scene.get("kind", ""))
    var intro := ""
    if str(scene.get("speaker_intro", "")) != "" and speaker == str(scene.get("speaker_intro", "")):
        intro = speaker
    _stage.show_beat({
        "art": art,
        "dark": bool(scene.get("dark", false)) or kind == "night",
        "speaker": speaker if s.crew.has(speaker) else "",
        "expression": _expression_for(kind, speaker, text),
        "action": str(scene.get("action", "")) if index == 0 and not bool(scene.get("action_only", false)) else "",
        "text": text,
        "choices": choices,
        "intro": intro,
        "caption": "DAY %d · %s" % [s.day, "첫 아침" if s.day == 1 else "아침"]
    })
    _skip.visible = choices.is_empty()

# A face that fits the beat, used sparingly: grief and fear at night reports,
# relief when someone was saved; otherwise the person's current mood.
func _expression_for(kind: String, speaker: String, text: String) -> String:
    if not screen.session.crew.has(speaker):
        return "neutral"
    if kind == "night":
        return "afraid"
    if kind == "morning":
        if "다행" in text or "살았" in text or "무사" in text:
            return "smile"
        if "…" in text and ("어제" in text or "옆에" in text):
            return "sad"
    if "?" in text and kind == "incident":
        return "suspicious"
    if kind == "incident":
        return "determined"
    var member: AstraCrewMember = screen.session.npc(speaker)
    return member.expression if member != null else "neutral"

var _interlude: AstraInterludeView

func _open_interlude(id: String) -> void:
    if _interlude != null and is_instance_valid(_interlude) and _interlude.interlude_id == id:
        return
    _close_interlude()
    _stage.visible = false
    _skip.visible = false
    _interlude = AstraInterludeView.new()
    add_child(_interlude)
    _interlude.setup(screen.session, id, str(screen.session.player_profile().get("preset", "p1")))
    _interlude.done.connect(func(result: String):
        screen.fx.play("select")
        screen.session.finish_interlude(id, result)
    )
    AstraUI.fade_in(_interlude, 0.3)

func _close_interlude() -> void:
    if _interlude != null and is_instance_valid(_interlude):
        _interlude.queue_free()
    _interlude = null
    _stage.visible = true

func _on_advance() -> void:
    screen.session.story_next()
    screen.fx.play("click")

func _on_choose(index: int) -> void:
    screen.fx.play("select")
    screen.session.story_choose(index)

func _finish() -> void:
    if _finished_sent:
        return
    _finished_sent = true
    # Morning read: the Day starts. No confirmation button in between.
    screen.call_deferred("advance_phase")

func consume_advance() -> bool:
    if _interlude != null and is_instance_valid(_interlude):
        return _interlude.consume_advance()
    return _stage.consume_advance()
