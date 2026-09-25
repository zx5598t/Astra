extends Control

# End of a Stage: first the story (re-sync, the local answer, what is still
# unknown — or the failure scene), then two short panels: CONTAINMENT RESULT
# (who was Null, who was isolated, who was lost) and STORY RESULT (what this
# Stage settled and what it opened). Then one clear next step.

var screen
var _stage: AstraVNStage
var _summary: Control
var _shown_summary: bool = false

func setup(game_screen) -> void:
    screen = game_screen
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _stage = AstraVNStage.new()
    add_child(_stage)
    _stage.advanced.connect(func():
        screen.session.story_next()
        screen.fx.play("click")
    )
    _stage.chose.connect(func(index: int):
        screen.session.story_choose(index)
    )
    refresh()

func refresh() -> void:
    var s: AstraGameSession = screen.session
    if s.phase != "RESULT":
        return
    var scene := s.story_scene()
    if not scene.is_empty():
        _stage.visible = true
        var lines: Array = scene.get("lines", [])
        var index := clampi(s.story_line_index(), 0, maxi(0, lines.size() - 1))
        var line: Array = lines[index] if not lines.is_empty() else ["", ""]
        var speaker := str(line[0])
        _stage.show_beat({
            "art": AstraArt.beat_art(scene, s.case_id),
            "dark": bool(scene.get("dark", false)),
            "speaker": speaker if s.crew.has(speaker) else "",
            "expression": "neutral",
            "action": str(scene.get("action", "")) if index == 0 and not bool(scene.get("action_only", false)) else "",
            "text": str(line[1]),
            "choices": scene.get("choices", []) if index >= lines.size() - 1 else [],
            "caption": "STAGE %d · 끝" % s.stage_index()
        })
        return
    if _shown_summary:
        return
    # After the campaign's last epilogue: credits, then DEEP RECONSTRUCTION.
    if s.finale_tone() != "" and not _credits_done:
        _stage.visible = false
        if _credits == null:
            # Full screen, over the Stage bar: credits belong to the story.
            _credits = AstraCreditsView.new()
            screen.add_child(_credits)
            _credits.setup(s)
            _credits.finished.connect(func():
                _credits_done = true
                _credits.queue_free()
                _credits = null
                refresh()
            )
        return
    _shown_summary = true
    _stage.visible = false
    _build_summary()

var _credits: AstraCreditsView
var _credits_done: bool = false

func consume_advance() -> bool:
    if _credits != null and is_instance_valid(_credits):
        return _credits.consume_advance()
    if _stage.visible:
        return _stage.consume_advance()
    return false

func _build_summary() -> void:
    var s: AstraGameSession = screen.session
    var report := s.final_report
    var win := str(report.get("outcome", "")) == "WIN"
    var bg := AstraUI.thumb(AstraArt.background(str(AstraStageStory.STAGE_ART.get(s.case_id, "bridge"))), Vector2.ZERO)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.modulate = Color(0.3, 0.33, 0.42)
    add_child(bg)
    var root := AstraUI.vbox(12)
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.offset_left = 30
    root.offset_right = -30
    root.offset_top = 16
    root.offset_bottom = -16
    add_child(root)
    var head := AstraUI.hbox(14)
    root.add_child(head)
    head.add_child(AstraUI.label(str(report.get("title", "")), AstraUI.T_DISPLAY, AstraUI.GREEN if win else AstraUI.RED))
    var sub := AstraUI.vbox(2)
    sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    head.add_child(sub)
    if s.is_deep():
        sub.add_child(AstraUI.label("심층 재구성 · 깊이 %d" % s.deep_depth(), AstraUI.T_UI, AstraUI.MUTED))
    else:
        sub.add_child(AstraUI.label("%s · STAGE %d · %s" % [AstraCaseCatalog.part_label(s.case_id), s.stage_index(), str(AstraVoyageContent.chapter(s.case_id).get("title", s.case_data.get("title", "")))], AstraUI.T_UI, AstraUI.MUTED))
    sub.add_child(AstraUI.prose(str(report.get("subtitle", "")), AstraUI.T_UI, AstraUI.TEXT))
    var cols := AstraUI.hbox(16)
    cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(cols)

    # CONTAINMENT RESULT
    var left := AstraUI.reading_panel(AstraUI.GREEN if win else AstraUI.RED, 0.92)
    left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cols.add_child(left)
    var lbox := AstraUI.vbox(8)
    left.add_child(AstraUI.scroll(lbox))
    lbox.add_child(AstraUI.label("격리 결과", AstraUI.T_HEAD, AstraUI.GREEN if win else AstraUI.RED))
    var nulls: Array = report.get("nulls", [])
    var null_row := AstraUI.hbox(8)
    lbox.add_child(null_row)
    null_row.add_child(AstraUI.label("이번 주기의 Null ·", AstraUI.T_UI, AstraUI.MUTED))
    for id in nulls:
        null_row.add_child(AstraUI.crew_tag(str(id), AstraUI.T_UI, false, 30))
    for line in Dictionary(report.get("loop_summary", {})).get("lines", []):
        lbox.add_child(AstraUI.prose("· " + str(line), AstraUI.T_UI, AstraUI.TEXT))
    var pm: Dictionary = report.get("post_mortem", {})
    for line in pm.get("innocent_lies", []):
        lbox.add_child(AstraUI.prose("· " + str(line), AstraUI.T_META, AstraUI.MUTED))
    if not win:
        for line in pm.get("danger", []):
            lbox.add_child(AstraUI.prose("· Null이 당신을 노린 이유: " + str(line), AstraUI.T_META, AstraUI.GOLD))
    lbox.add_child(AstraUI.label("평가 %s · %d점" % [str(report.get("rank", "")), int(report.get("total", 0))], AstraUI.T_UI, AstraUI.GOLD))

    # STORY RESULT
    var right := AstraUI.reading_panel(AstraUI.VIOLET, 0.92)
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cols.add_child(right)
    var rbox := AstraUI.vbox(8)
    right.add_child(AstraUI.scroll(rbox))
    var story: Dictionary = report.get("story", {})
    if s.is_deep():
        # Deep tells no story: only the run so far.
        rbox.add_child(AstraUI.label("이번 도전", AstraUI.T_HEAD, AstraUI.VIOLET))
        var run: Dictionary = screen.app.deep_run
        var stats: Dictionary = run.get("stats", {})
        rbox.add_child(AstraUI.prose("깊이 %d까지 · 격리한 Null %d · 당신의 표 정확도 %d%%" % [s.deep_depth(), int(stats.get("contained", 0)), AstraDeepRun.accuracy(run)], AstraUI.T_UI, AstraUI.TEXT))
        if win:
            var next_depth := s.deep_depth() + 1
            var next_mod := AstraDeepRun.modifier_for(int(run.get("run_seed", 0)), next_depth)
            rbox.add_child(AstraUI.prose("다음 · 깊이 %d%s" % [next_depth, (" · 조건 " + str(AstraDeepRun.MODIFIERS.get(next_mod, {}).get("name", ""))) if next_mod != "" else ""], AstraUI.T_UI, AstraUI.GOLD))
        else:
            rbox.add_child(AstraUI.prose("한 목숨이 끝났다. 이번 도전은 여기까지다.", AstraUI.T_UI, AstraUI.MUTED))
    else:
        rbox.add_child(AstraUI.label("이야기", AstraUI.T_HEAD, AstraUI.VIOLET))
    if s.is_deep():
        pass
    elif win:
        if str(story.get("resolved", "")) != "":
            rbox.add_child(AstraUI.label("알게 된 것", AstraUI.T_META, AstraUI.GREEN))
            rbox.add_child(AstraUI.prose(str(story.get("resolved", "")), AstraUI.T_UI, AstraUI.TEXT))
        if str(story.get("open_question", "")) != "":
            rbox.add_child(AstraUI.label("아직 모르는 것", AstraUI.T_META, AstraUI.GOLD))
            rbox.add_child(AstraUI.prose(str(story.get("open_question", "")), AstraUI.T_UI, AstraUI.TEXT))
    else:
        if screen.app.can_rewind():
            rbox.add_child(AstraUI.prose("이번 재구성은 여기서 끊겼다. 하지만 오늘 아침은 아직 당신 안에 남아 있다. 되감으면 같은 사람들, 같은 진실의 아침으로 돌아간다. 그들은 아무것도 기억하지 못한다. 당신만 기억한다.", AstraUI.T_UI, AstraUI.TEXT))
            var memory: Dictionary = s.rewind_memory()
            rbox.add_child(AstraUI.label("가지고 돌아갈 기억", AstraUI.T_META, AstraUI.VIOLET))
            for note in Array(memory.get("notes", [])).slice(0, 4):
                rbox.add_child(AstraUI.prose("· " + str(note), AstraUI.T_META, AstraUI.MUTED))
        else:
            rbox.add_child(AstraUI.prose("이번 재구성은 여기서 끝났다. 다시 시도하면 같은 STAGE가 새로 재구성된다. 다음 주기의 Null이 같은 사람이라는 보장은 없다. 기억하는 사람은 당신뿐이다.", AstraUI.T_UI, AstraUI.TEXT))
    var reasons_given: Dictionary = s.stage_state().get("ballot_reasons", {})
    if not reasons_given.is_empty():
        rbox.add_child(AstraUI.label("당신이 댄 이유", AstraUI.T_META, AstraUI.GOLD))
        var days: Array = reasons_given.keys()
        days.sort()
        for key in days:
            var entry: Dictionary = reasons_given[key]
            rbox.add_child(AstraUI.prose("DAY %s · %s — %s" % [str(key), s.name_of(str(entry.get("target", ""))), str(entry.get("text", ""))], AstraUI.T_META, AstraUI.MUTED))

    var buttons := AstraUI.hbox(12)
    root.add_child(buttons)
    buttons.add_child(AstraUI.spacer())
    if s.is_deep():
        # One life: a cleared depth goes deeper, a lost one closes the run.
        var title_deep := AstraUI.button("타이틀로 (나중에 이어서)" if win else "타이틀로", AstraUI.MUTED, AstraUI.T_UI, 48)
        title_deep.pressed.connect(func(): screen.exit_to_title())
        buttons.add_child(title_deep)
        var go := AstraUI.primary_button("다음 깊이   →" if win else "도전 기록 보기   →", AstraUI.VIOLET)
        go.custom_minimum_size = Vector2(260, 52)
        go.pressed.connect(func():
            if win:
                screen.app.deep_next_depth()
            else:
                screen.app.show_deep("summary")
        )
        buttons.add_child(go)
        AstraUI.fade_in(root, 0.4)
        return
    var next_id := AstraCaseCatalog.next_stage(s.case_id)
    var title_button := AstraUI.button("타이틀로", AstraUI.MUTED, AstraUI.T_UI, 48)
    title_button.pressed.connect(func(): screen.exit_to_title())
    buttons.add_child(title_button)
    if not win:
        # The failed reconstruction can still be read before it is let go.
        var records := AstraUI.button("기록 확인", AstraUI.MUTED, AstraUI.T_UI, 48)
        records.pressed.connect(func(): screen.open_notebook())
        buttons.add_child(records)
    if not win:
        # Going back a Stage is always open to a slot that has reached it.
        var previous_id: String = screen.app.previous_case_id()
        if previous_id != "":
            var back := AstraUI.button("이전 STAGE로 돌아가기", AstraUI.MUTED, AstraUI.T_UI, 48)
            back.tooltip_text = "STAGE %d를 다시 재구성합니다. 진행한 캠페인은 그대로 남습니다." % AstraCaseCatalog.stage_index(previous_id)
            back.pressed.connect(func(): screen.start_other_case(previous_id))
            buttons.add_child(back)
    # A retry is a new reconstruction: new seed, possibly new Nulls (§28).
    var retry := AstraUI.button("이 Stage 다시" if win else "처음부터 새로 재구성", AstraUI.CYAN, AstraUI.T_UI, 48, not win and not screen.app.can_rewind())
    retry.pressed.connect(func(): screen.restart_case())
    buttons.add_child(retry)
    if not win and screen.app.can_rewind():
        # The same reconstruction, from this morning: only you remember.
        var rewind := AstraUI.primary_button("DAY %d 아침으로 되감기  ↺" % s.day, AstraUI.VIOLET)
        rewind.custom_minimum_size = Vector2(300, 52)
        rewind.tooltip_text = "같은 사람, 같은 진실. 이번 Stage에 한 번. 지난 시도에서 들은 것은 기억으로 남습니다."
        rewind.pressed.connect(func(): screen.app.rewind_to_dawn())
        buttons.add_child(rewind)
    if win and next_id != "":
        var next := AstraUI.primary_button("다음 STAGE  →", AstraUI.GREEN)
        next.custom_minimum_size = Vector2(260, 52)
        next.pressed.connect(func(): screen.start_other_case(next_id))
        buttons.add_child(next)
    AstraUI.fade_in(root, 0.4)
