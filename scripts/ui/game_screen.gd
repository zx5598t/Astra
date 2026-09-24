class_name AstraGameScreen
extends Control

# In-Stage layout, top to bottom:
#   one thin bar   — where you are (PART · STAGE · DAY), the four steps of a
#                    Day, who is still here, and three small utility buttons
#   one line       — what to do right now (hidden while a scene is playing)
#   the view       — the scene, the conversation, the meeting, the vote
# Each view carries its own next step at the place the eye already is, so
# there is no second "next" button anywhere else (§44–§49, §77).

const BriefingView = preload("res://scripts/ui/views/briefing_view.gd")
const InterrogationView = preload("res://scripts/ui/views/interrogation_view.gd")
const MeetingView = preload("res://scripts/ui/views/meeting_view.gd")
const VoteView = preload("res://scripts/ui/views/vote_view.gd")
const NightView = preload("res://scripts/ui/views/night_view.gd")
const ResultView = preload("res://scripts/ui/views/result_view.gd")

const STEPS := ["INTERROGATION", "MEETING", "VOTE", "NIGHT"]
const STEP_LABELS := {"INTERROGATION": "대화", "MEETING": "회의", "VOTE": "투표", "NIGHT": "밤"}
const PHASE_COLORS := {
    "BRIEFING": AstraUI.CYAN, "INTERROGATION": AstraUI.GREEN,
    "MEETING": AstraUI.PINK, "VOTE": AstraUI.RED, "NIGHT": AstraUI.NIGHT, "RESULT": AstraUI.GOLD
}

var app
var session: AstraGameSession
var fx: AstraFeedbackFX
var archive_change: Dictionary = {}

var _background: TextureRect
var _where: Label
var _title: Label
var _day: Label
var _steps: Dictionary = {}
var _status: Label
var _protocol: Label
var _note_button: Button
var _objective_panel: PanelContainer
var _objective: Label
var _budget: Label
var _holder: Control
var _view: Control
var _view_phase: String = ""
var _recorded: bool = false
var _advancing: bool = false

func setup(app_node, game_session: AstraGameSession, feedback: AstraFeedbackFX) -> void:
    app = app_node
    session = game_session
    fx = feedback
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _build()
    session.changed.connect(_on_changed)
    session.phase_changed.connect(_on_phase_changed)
    session.notice.connect(_on_notice)
    _on_changed()

func _build() -> void:
    _background = AstraUI.thumb(AstraArt.background(str(AstraStageStory.STAGE_ART.get(session.case_id, "bridge"))), Vector2.ZERO)
    _background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _background.modulate = Color(0.42, 0.46, 0.55)
    add_child(_background)
    add_child(AstraArt.shade())
    var root := AstraUI.vbox(8)
    var margin := AstraUI.margin(root, 18, 10, 18, 12)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(margin)

    # ---- the thin bar
    var bar := AstraUI.hbox(14)
    bar.custom_minimum_size.y = 40
    root.add_child(bar)
    var where := AstraUI.vbox(0)
    bar.add_child(where)
    _where = AstraUI.label("", AstraUI.T_META - 2, AstraUI.MUTED)
    where.add_child(_where)
    var title_row := AstraUI.hbox(8)
    where.add_child(title_row)
    _title = AstraUI.label("", AstraUI.T_UI, AstraUI.TEXT)
    title_row.add_child(_title)
    _day = AstraUI.label("", AstraUI.T_UI, AstraUI.GOLD)
    title_row.add_child(_day)
    bar.add_child(AstraUI.spacer())
    var stepper := AstraUI.hbox(6)
    bar.add_child(stepper)
    for index in range(STEPS.size()):
        var step := str(STEPS[index])
        if index > 0:
            stepper.add_child(AstraUI.label("›", AstraUI.T_META, AstraUI.DIM))
        var cell := AstraUI.label(str(STEP_LABELS[step]), AstraUI.T_UI, AstraUI.DIM)
        stepper.add_child(cell)
        _steps[step] = cell
    bar.add_child(AstraUI.spacer())
    var right := AstraUI.vbox(0)
    bar.add_child(right)
    _status = AstraUI.label("", AstraUI.T_META, AstraUI.TEXT)
    _status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    right.add_child(_status)
    _protocol = AstraUI.label("", AstraUI.T_META - 2, AstraUI.VIOLET)
    _protocol.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    right.add_child(_protocol)
    _note_button = AstraUI.button("노트", AstraUI.MUTED, AstraUI.T_META, 34)
    _note_button.tooltip_text = "오늘 들은 말과 알아낸 사실 정리 (N)"
    _note_button.pressed.connect(open_notebook)
    bar.add_child(_note_button)
    var terms := AstraUI.button("용어", AstraUI.MUTED, AstraUI.T_META, 34)
    terms.tooltip_text = "게임에 나오는 말 풀이 (H)"
    terms.pressed.connect(open_glossary)
    bar.add_child(terms)
    var menu := AstraUI.button("≡", AstraUI.MUTED, AstraUI.T_UI, 34)
    menu.tooltip_text = "메뉴 (Esc)"
    menu.custom_minimum_size.x = 40
    menu.pressed.connect(func(): app.show_pause_menu())
    bar.add_child(menu)

    # ---- the one instruction line
    _objective_panel = AstraUI.panel(Color(AstraUI.CYAN, 0.08), Color(AstraUI.CYAN, 0.35), 8, 8)
    root.add_child(_objective_panel)
    var objective_row := AstraUI.hbox(10)
    _objective_panel.add_child(objective_row)
    objective_row.add_child(AstraUI.label("지금 할 일", AstraUI.T_META, AstraUI.CYAN))
    _objective = AstraUI.label("", AstraUI.T_UI, AstraUI.TEXT, true)
    objective_row.add_child(_objective)
    _budget = AstraUI.label("", AstraUI.T_UI, AstraUI.GOLD)
    objective_row.add_child(_budget)

    _holder = Control.new()
    _holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _holder.clip_contents = true
    _holder.mouse_filter = Control.MOUSE_FILTER_PASS
    root.add_child(_holder)

func _on_changed() -> void:
    if session == null:
        return
    _refresh_bar()
    # Record first: the result screen shows the run including this Stage.
    if session.phase == "RESULT" and not _recorded:
        _recorded = true
        archive_change = app.record_result(session)
        for feature in archive_change.get("new_features", []):
            app.meta.mark_unlock_announced(str(feature))
        app.meta.save_data()
    if session.phase != _view_phase or _view == null:
        _swap_view()
    elif _view.has_method("refresh"):
        _view.refresh()

func _refresh_bar() -> void:
    var info := session.header_info()
    _where.text = "%s · STAGE %d" % [str(info["part"]), int(info["stage"])]
    _title.text = str(info["title_ko"]) if str(info["title_ko"]) != "" else str(info["title"])
    _day.text = "DAY %d" % session.day
    # Deep has no Parts or Stage titles: depth and the depth's condition.
    if session.is_deep():
        _where.text = "심층 재구성 · 깊이 %d" % session.deep_depth()
        var mod := session.deep_modifier()
        _title.text = str(AstraDeepRun.MODIFIERS.get(mod, {}).get("name", "")) if mod != "" else "재구성"
    var status := "깨어 있음 %d" % int(info["active"])
    if int(info["isolated"]) > 0:
        status += "  ·  포드 격리 %d" % int(info["isolated"])
    if int(info["lost"]) > 0:
        status += "  ·  사망 %d" % int(info["lost"])
    _status.text = status
    _protocol.text = ""
    if session.protocol != "NONE":
        _protocol.text = session.protocol_name()
        if session.protocol == "GUARDIAN":
            _protocol.text += " · Aegis %d" % session.guardian_charges()
    for step in _steps:
        var cell: Label = _steps[step]
        var here: bool = step == session.phase
        var order := STEPS.find(session.phase)
        var done: bool = order >= 0 and STEPS.find(step) < order
        cell.add_theme_color_override("font_color", PHASE_COLORS.get(step, AstraUI.CYAN) if here else (AstraUI.MUTED if done else AstraUI.DIM))
        cell.add_theme_font_size_override("font_size", AstraUI.font_size(AstraUI.T_HEAD if here else AstraUI.T_UI))
    refresh_objective()

func refresh_objective() -> void:
    if session == null:
        return
    var phase := session.phase
    _objective_panel.visible = phase in ["INTERROGATION", "MEETING"]
    var text := session.next_step_text()
    if phase == "INTERROGATION" and session.conversations_used() == 0:
        text = "누구 말을 먼저 들어 볼까요? 얼굴을 누르면 바로 대화가 시작됩니다."
    if phase == "MEETING" and _view != null and _view.has_method("pending_lines") and int(_view.pending_lines()) > 0:
        text = "사람들이 말하는 중입니다. 화면을 누르면 끝까지 넘깁니다."
    _objective.text = text
    var accent: Color = PHASE_COLORS.get(phase, AstraUI.CYAN)
    _objective_panel.add_theme_stylebox_override("panel", AstraUI.style(Color(accent, 0.08), Color(accent, 0.38), 8, 1, 8))
    match phase:
        "INTERROGATION":
            _budget.text = "대화 %d/%d" % [session.conversations_left(), session.conversations_max()]
        "MEETING":
            _budget.text = "개입 %d" % session.meeting_actions_left
        _:
            _budget.text = ""
    _note_button.text = "노트" + (" •" if not session.known_fragments(session.day).is_empty() else "")

func _swap_view() -> void:
    if _view != null:
        _holder.remove_child(_view)
        _view.queue_free()
    _view_phase = session.phase
    var script: Script = BriefingView
    match session.phase:
        "INTERROGATION": script = InterrogationView
        "MEETING": script = MeetingView
        "VOTE": script = VoteView
        "NIGHT": script = NightView
        "RESULT": script = ResultView
    _view = script.new()
    _holder.add_child(_view)
    _view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _view.setup(self)
    AstraUI.fade_in(_view, 0.2)
    var full_scene := session.phase in ["BRIEFING", "RESULT", "NIGHT"]
    _background.visible = not full_scene
    refresh_objective()

func _on_phase_changed(phase: String) -> void:
    _advancing = false
    var accent: Color = PHASE_COLORS.get(phase, AstraUI.CYAN)
    match phase:
        "INTERROGATION":
            fx.play("phase")
        # No title banners: the phase strip and each screen's own heading
        # already say where we are, and a banner covered the first lines.
        "MEETING":
            fx.flash(accent, 0.08, 0.35)
            fx.play("phase")
        "VOTE":
            fx.flash(accent, 0.1, 0.35)
            fx.play("alert")
        "NIGHT":
            fx.flash(Color(0.02, 0.02, 0.1), 0.5, 0.9)
            fx.play("night")
        "BRIEFING":
            fx.play("phase")
            # After the people have told it, one short line for the record (§35).
            var night: Dictionary = session.night_result
            if session.day > 1 and bool(night.get("protected", false)):
                var who := "당신" if str(night.get("victim", "")) == "player" else session.name_of(str(night.get("victim", "")))
                fx.toast("AEGIS 차단 · %s 무사" % who, AstraUI.GOLD, 3.0)
        "RESULT":
            fx.play("win" if session.outcome == "WIN" else "lose")

func _on_notice(kind: String, payload: Dictionary) -> void:
    match kind:
        "admission":
            if bool(payload.get("public", false)):
                fx.toast(AstraJosa.i(session.name_of(str(payload.get("npc_id", "")))) + " 회의 중에 말을 바꿨습니다.", AstraUI.RED, 2.4)

# ---------------------------------------------------------------- actions

func advance_phase() -> void:
    if _advancing or not session.can_advance():
        return
    _advancing = true
    fx.play("click")
    session.advance()
    _advancing = false

func selected_id() -> String:
    return session.selected_id

func exit_to_title() -> void:
    app.show_title()

func restart_case() -> void:
    app.start_case(session.case_id, session.protocol)

func start_other_case(case_id: String) -> void:
    app.start_case(case_id, session.protocol)

func request_ai_line(npc_id: String, intent: String, result: Dictionary) -> void:
    app.request_ai_line(session, npc_id, intent, result)

func handle_hotkey(event: InputEventKey) -> bool:
    if session == null:
        return false
    var code := event.keycode
    if code == KEY_SPACE or code == KEY_ENTER or code == KEY_KP_ENTER:
        if _view != null and _view.has_method("consume_advance") and _view.consume_advance():
            return true
        return false
    if code == KEY_N:
        open_notebook()
        return true
    if code == KEY_H:
        open_glossary()
        return true
    return false

# QA-only playtime (§66): active seconds per kind of play, kept in the Stage
# stats (never shown in the game UI). Read from final_report["stats"].
func _process(delta: float) -> void:
    if session == null or session.phase == "" or not is_visible_in_tree():
        return
    var category := "STORY"
    match session.phase:
        "INTERROGATION": category = "CONVERSATION"
        "MEETING": category = "MEETING"
        "VOTE": category = "VOTE"
        "NIGHT": category = "NIGHT"
        "BRIEFING":
            if _view != null and "_interlude" in _view and _view._interlude != null:
                category = "INTERLUDE"
    if app != null and app.modal_open():
        category = "NOTEBOOK"
    var key := "time_" + category
    session.stats[key] = float(session.stats.get(key, 0.0)) + delta

func open_notebook() -> void:
    if app.modal_open():
        return
    var notebook := AstraNotebookPanel.new()
    notebook.custom_minimum_size = Vector2(0, 500)
    notebook.setup(session)
    AstraModal.open(app.overlay_root(), "노트 · DAY %d" % session.day, notebook, [["닫기", AstraUI.CYAN]], Callable(), 980)

func open_glossary() -> void:
    if app.modal_open():
        return
    var scroll := AstraUI.scroll(AstraHelpPanel.glossary())
    scroll.custom_minimum_size = Vector2(0, 480)
    AstraModal.open(app.overlay_root(), "용어 풀이", scroll, [["닫기", AstraUI.CYAN]], Callable(), 760)
