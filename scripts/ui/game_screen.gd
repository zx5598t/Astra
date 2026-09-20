class_name AstraGameScreen
extends Control

# In-case layout:
#   top bar (case, day, phase stepper, menu) / hint bar
#   crew roster | phase view | notebook
#   bottom bar (selection summary, primary "next" button)

const BriefingView = preload("res://scripts/ui/views/briefing_view.gd")
const InvestigationView = preload("res://scripts/ui/views/investigation_view.gd")
const InterrogationView = preload("res://scripts/ui/views/interrogation_view.gd")
const MeetingView = preload("res://scripts/ui/views/meeting_view.gd")
const VoteView = preload("res://scripts/ui/views/vote_view.gd")
const NightView = preload("res://scripts/ui/views/night_view.gd")
const ResultView = preload("res://scripts/ui/views/result_view.gd")

const STEPS := ["BRIEFING", "INVESTIGATION", "INTERROGATION", "MEETING", "VOTE", "NIGHT"]
const STEP_LABELS := {"BRIEFING": "브리핑", "INVESTIGATION": "조사", "INTERROGATION": "대화", "MEETING": "회의", "VOTE": "투표", "NIGHT": "밤"}
const PHASE_COLORS := {
    "BRIEFING": AstraUI.CYAN, "INVESTIGATION": AstraUI.GOLD, "INTERROGATION": AstraUI.GREEN,
    "MEETING": AstraUI.PINK, "VOTE": AstraUI.RED, "NIGHT": AstraUI.NIGHT, "RESULT": AstraUI.GOLD
}

var app
var session: AstraGameSession
var fx: AstraFeedbackFX
var archive_change: Dictionary = {}

var _day_label: Label
var _ap_label: RichTextLabel
var _hint: Label
var _hint_panel: PanelContainer
var _roster: HBoxContainer
var _cards: Dictionary = {}
var _center: PanelContainer
var _holder: Control
var _view: Control
var _view_phase: String = ""
var _notebook: AstraNotebookPanel
var _summary: RichTextLabel
var _primary: Button
var _selected: String = ""
var _recorded: bool = false
var _background: TextureRect
var _roster_buttons: Dictionary = {}
var _note_button: Button
var _help_button: Button
var _objective_panel: PanelContainer
var _objective_tag: Label
var _objective_label: Label
var _objective_text: String = ""
var _stepper: HBoxContainer
var _budget_panel: PanelContainer
var _budget_row: HBoxContainer
var _budget_name: Label
var _budget_pips: RichTextLabel
var _budget_count: Label
var _step_labels: Dictionary = {}
var _ready_pulse: bool = false

func setup(app_node, game_session: AstraGameSession, feedback: AstraFeedbackFX) -> void:
    app = app_node
    session = game_session
    fx = feedback
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _selected = session.selected_id
    _build()
    session.changed.connect(_on_changed)
    session.phase_changed.connect(_on_phase_changed)
    session.notice.connect(_on_notice)
    _on_changed()
    _announce_phase(session.phase)

func _build() -> void:
    _background = AstraUI.thumb(AstraArt.chapter(session.case_id), Vector2.ZERO)
    _background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _background.modulate = Color(0.55, 0.60, 0.70)
    add_child(_background)
    add_child(AstraArt.shade())
    var root := AstraUI.vbox(12)
    var margin := AstraUI.margin(root,24,18,24,18)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(margin)
    var top := AstraUI.hbox(16)
    root.add_child(top)
    top.add_child(AstraUI.label("A S T R A", 22, AstraUI.TEXT))
    _day_label = AstraUI.label("", AstraUI.T_UI, AstraUI.TEXT)
    top.add_child(_day_label)
    # Where we are in the day, as a row of steps rather than a word. 0.3.1 named
    # the phase but never said what came before or after it, so "저녁 회의" gave
    # no sense of how much of the day was left.
    _stepper = AstraUI.hbox(4)
    top.add_child(_stepper)
    for index in range(STEPS.size()):
        var step := str(STEPS[index])
        var cell := AstraUI.label(str(STEP_LABELS.get(step, step)), AstraUI.T_META, AstraUI.DIM)
        cell.tooltip_text = str(AstraCodex.screen(step).get("purpose", ""))
        _stepper.add_child(cell)
        _step_labels[step] = cell
        if index < STEPS.size() - 1:
            _stepper.add_child(AstraUI.label("›", AstraUI.T_META, AstraUI.DIM))
    top.add_child(AstraUI.spacer())
    # Action points were drawn as a right-aligned grey caption and were the
    # single most missed piece of information in playtesting: people asked
    # questions until they ran out and only then noticed there was a budget.
    _budget_panel = AstraUI.panel(Color(0.04, 0.07, 0.11, 0.95), Color(AstraUI.GOLD, 0.45), 8, 10)
    top.add_child(_budget_panel)
    _budget_row = AstraUI.hbox(10)
    _budget_panel.add_child(_budget_row)
    _budget_name = AstraUI.label("", AstraUI.T_META, AstraUI.MUTED)
    _budget_row.add_child(_budget_name)
    _budget_pips = AstraUI.rich(AstraUI.T_UI)
    _budget_pips.custom_minimum_size.x = 90
    _budget_row.add_child(_budget_pips)
    _budget_count = AstraUI.label("", AstraUI.T_META, AstraUI.GOLD)
    _budget_row.add_child(_budget_count)
    _ap_label = AstraUI.rich(AstraUI.T_META)
    _ap_label.custom_minimum_size.x = 230
    top.add_child(_ap_label)
    _note_button = AstraUI.button("조사 노트 · N", AstraUI.CYAN, AstraUI.T_META, 40)
    _note_button.tooltip_text = AstraCodex.tooltip("notebook")
    _note_button.pressed.connect(open_notebook)
    top.add_child(_note_button)
    # The help button sits beside the objective it explains, in the same spot on
    # every screen, so "where do I look this up" has one answer (§10).
    _help_button = AstraUI.help_button()
    _help_button.pressed.connect(_open_screen_help)
    top.add_child(_help_button)
    var menu := AstraUI.button("메뉴 · Esc", AstraUI.MUTED, AstraUI.T_META, 40)
    menu.pressed.connect(func(): app.show_pause_menu())
    top.add_child(menu)

    # PRIMARY: one line saying what to do next, always in the same place.
    # Built once and updated in place. Rebuilding it into an anchored holder on
    # every refresh made it render empty on the first frame of a screen, before
    # the container had a size to anchor against.
    _objective_panel = AstraUI.panel(Color(AstraUI.CYAN, 0.09), Color(AstraUI.CYAN, 0.42), 8, 10)
    root.add_child(_objective_panel)
    var objective_row := AstraUI.hbox(10)
    _objective_panel.add_child(objective_row)
    _objective_tag = AstraUI.label("지금 할 일", AstraUI.T_META, AstraUI.CYAN)
    objective_row.add_child(_objective_tag)
    _objective_label = AstraUI.prose("", AstraUI.T_BODY, AstraUI.TEXT)
    objective_row.add_child(_objective_label)

    # SECONDARY: the phase hint, which the player can switch off.
    _hint_panel = AstraUI.panel(Color(0.03, 0.055, 0.09, 0.93), Color(AstraUI.CYAN, 0.3), 8, 10)
    root.add_child(_hint_panel)
    _hint = AstraUI.prose("", AstraUI.T_META, AstraUI.MUTED)
    _hint_panel.add_child(_hint)

    _roster = AstraUI.hbox(7)
    root.add_child(_roster)
    # Only the people in this case. The calibration roster is four, and showing
    # eight slots with four of them empty would undo the point of it.
    var roster: Array = session.active_roster()
    for index in range(roster.size()):
        var id := str(roster[index])
        # Sprite + Korean name + job on every roster button. The 0.3.1 button was
        # a number and a Latin name, which is the least memorable pair possible.
        var button := AstraUI.button("%s\n%s" % [session.name_of(id), AstraCrewCatalog.role_short(id)], AstraUI.MUTED, AstraUI.T_UI, 56)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.icon = AstraUI.texture(AstraCrewCatalog.dot_path(id))
        button.expand_icon = true
        button.add_theme_constant_override("icon_max_width", 40)
        button.clip_text = true
        button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        button.pressed.connect(select.bind(id))
        _roster.add_child(button)
        _roster_buttons[id] = button
    _center = AstraUI.panel(Color(0.03,0.05,0.08,0.91),AstraUI.BORDER,12,16)
    _center.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(_center)
    _holder = Control.new()
    _holder.clip_contents = true
    _holder.mouse_filter = Control.MOUSE_FILTER_PASS
    _center.add_child(_holder)
    var bottom := AstraUI.hbox(12)
    root.add_child(bottom)
    _summary = AstraUI.rich(AstraUI.T_META)
    bottom.add_child(_summary)
    # Marking is a 0.4.0 unlock: during calibration the player has four people
    # and one meeting, and a third annotation layer on top of that is noise.
    if session.has_feature("marks"):
        var mark := AstraUI.button("내 판단 표시 · M", AstraUI.MUTED, AstraUI.T_META, 42)
        mark.tooltip_text = AstraCodex.tooltip("mark")
        mark.pressed.connect(func(): _on_mark(_selected))
        bottom.add_child(mark)
    _primary = AstraUI.primary_button("")
    _primary.custom_minimum_size.x = 320
    _primary.pressed.connect(_on_primary)
    bottom.add_child(_primary)

func _on_changed() -> void:
    if session == null:
        return
    if not session.crew.has(_selected):
        _selected = session.selected_id
    if session.phase == "INTERROGATION" and not session.pending_event.is_empty():
        _selected = str(session.pending_event.get("npc_id", _selected))
    _refresh_top()
    _refresh_roster()
    if is_instance_valid(_notebook):
        _notebook.refresh()
    _refresh_bottom()
    if session.phase != _view_phase or _view == null:
        _swap_view()
    elif _view.has_method("refresh"):
        _view.refresh()
    if session.phase == "RESULT" and not _recorded:
        _recorded = true
        archive_change = app.record_result(session)
        if _view != null:
            _view.refresh()
        # Feature cards come after the result is on screen, so the player reads
        # what happened first and what they gained second (§35).
        var opened: Array = archive_change.get("new_features", [])
        if not opened.is_empty():
            for feature in opened:
                app.meta.mark_unlock_announced(str(feature))
            app.meta.save_data()

func _refresh_top() -> void:
    var day_text := "%d일째" % session.day
    if session.max_days > 1:
        day_text += " / %d" % session.max_days
    _day_label.text = "%s  ·  %s" % [str(session.case_data.get("title_ko", "")), day_text]
    _ap_label.text = "[right]" + session.time_caption() + "[/right]"
    _refresh_stepper()
    _refresh_budget()
    _refresh_objective_bar()

# Six labels for the six stages of a day, the current one highlighted. It
# answers "where am I and how much is left" without a sentence.
#
# Built once, recoloured on refresh. These used to be rebuilt on every `changed`
# signal — several times per action — which churned a RichTextLabel and a dozen
# Controls per refresh and left orphaned nodes behind.
func _refresh_stepper() -> void:
    var current := STEPS.find(session.phase)
    for index in range(STEPS.size()):
        var step := str(STEPS[index])
        var here := index == current
        var done := current >= 0 and index < current
        var accent: Color = PHASE_COLORS.get(step, AstraUI.CYAN)
        var cell: Label = _step_labels.get(step, null)
        if cell == null:
            continue
        cell.add_theme_color_override("font_color", accent if here else (AstraUI.MUTED if done else AstraUI.DIM))
        cell.add_theme_font_size_override("font_size", AstraUI.font_size(AstraUI.T_UI if here else AstraUI.T_META))

# How many actions are left, as pips, in a bordered box. Empty pips are what
# tell the player the budget existed in the first place.
func _refresh_budget() -> void:
    var spec := session.action_budget()
    if spec.is_empty():
        _budget_panel.visible = false
        return
    _budget_panel.visible = true
    var left := int(spec.get("left", 0))
    var maximum := int(spec.get("max", 0))
    var accent: Color = AstraUI.DIM if left <= 0 else AstraUI.GOLD
    _budget_panel.add_theme_stylebox_override("panel",
        AstraUI.style(Color(0.04, 0.07, 0.11, 0.95), Color(accent, 0.5), 8, 1, 10))
    _budget_name.text = str(spec.get("label", ""))
    _budget_pips.text = AstraUI.pips(left, maximum, accent)
    _budget_count.text = "%d / %d" % [left, maximum]
    _budget_count.add_theme_color_override("font_color", accent)

# The one line saying what to do next, plus the hint line under it.
func _refresh_objective_bar() -> void:
    _objective_text = str(session.current_objective().get("text", ""))
    # While the room is still speaking, the only thing to do is listen. The
    # session cannot know how much of the meeting the player has read, so the
    # view reports it.
    var waiting := 0
    if _view != null and _view.has_method("pending_lines"):
        waiting = int(_view.pending_lines())
        if waiting > 0:
            _objective_text = "발언을 끝까지 들으세요. %d건 남았습니다." % waiting
    var accent: Color = PHASE_COLORS.get(session.phase, AstraUI.CYAN)
    var hint := session.phase_hint()
    # During the tutorial the crew's own line says the same thing as the generic
    # objective, in a voice. Two bars saying one thing is two bars the player
    # stops reading, so the tutorial line becomes the objective and the second
    # bar goes away entirely.
    # "listen to the room" outranks the tutorial line: while people are still
    # speaking there is genuinely nothing else to do, and saying otherwise sends
    # the player looking for a button that is not there yet.
    var listening := waiting > 0
    var merged := not listening and session.tutorial_active() and hint != "" and session.phase not in ["VOTE", "NIGHT"]
    _objective_label.text = hint if merged else _objective_text
    _objective_tag.text = "안내" if merged else "지금 할 일"
    _objective_tag.add_theme_color_override("font_color", accent)
    _objective_panel.add_theme_stylebox_override("panel", AstraUI.style(Color(accent, 0.09), Color(accent, 0.42), 8, 1, 10))
    _objective_panel.visible = _objective_label.text != "" and session.phase != "RESULT"
    _hint.text = hint
    _hint_panel.visible = (not merged) and app.settings.show_hints and hint != "" and hint != _objective_text
    _note_button.text = "조사 노트 · N" + ("  •" if not session.found_clues().is_empty() else "")

# The meeting view calls this after revealing a line so the objective strip
# tracks "still listening" vs "your turn" without waiting for a session change.
func refresh_objective() -> void:
    if session != null:
        _refresh_top()
        _refresh_bottom()

func _open_screen_help() -> void:
    app.show_screen_help(session.phase, _objective_text)

func _refresh_roster() -> void:
    _roster.visible = session.phase in ["INTERROGATION", "MEETING", "VOTE", "NIGHT"]
    for id in _roster_buttons:
        var button: Button = _roster_buttons[id]
        var member := session.npc(id)
        var selected: bool = id == _selected
        button.add_theme_stylebox_override("normal",AstraUI.style(Color(0.09,0.16,0.24,0.94) if selected else Color(0.03,0.05,0.08,0.91),AstraUI.CYAN if selected else AstraUI.BORDER,8,1,8))
        button.modulate = Color.WHITE if member.is_alive() else Color(0.55,0.57,0.62)
        button.tooltip_text = member.job + " · " + (member.mood_label() if member.is_alive() else session.status_label(str(id)))

func _refresh_bottom() -> void:
    # The bottom strip is now the "where and when am I" line rather than a fixed
    # sentence that never changed.
    var line := "[color=#%s]%s[/color]" % [AstraUI.hex(AstraUI.MUTED), session.situation_line()]
    var member := session.npc(_selected)
    if member != null and session.phase not in ["INVESTIGATION", "BRIEFING"]:
        var who := "[b][color=#%s]%s[/color][/b] (%s)" % [AstraUI.hex(member.accent), member.display_name, member.job]
        if session.has_feature("marks"):
            var mark := str(session.marks.get(_selected, ""))
            who += "  ·  내 판단: " + str(AstraUI.MARK_LABEL.get(mark, "미정"))
        line = who + "        " + line
    _summary.text = line

    _primary.visible = session.phase != "RESULT"
    var can_advance := session.can_advance()
    _primary.disabled = not can_advance
    var done := session.phase_exhausted()
    _primary.text = session.advance_label() + ("  →" if can_advance else "")
    # When there is genuinely nothing left to do here, the next button stops
    # looking like one option among several and starts looking like the answer.
    if can_advance and done:
        _primary.text = "✔  " + _primary.text
        if not _ready_pulse:
            _ready_pulse = true
            _primary.add_theme_stylebox_override("normal", AstraUI.style(Color(AstraUI.GREEN, 0.42), AstraUI.GREEN, 8, 2, 10))
            _primary.add_theme_stylebox_override("hover", AstraUI.style(Color(AstraUI.GREEN, 0.58), AstraUI.GREEN, 8, 2, 10))
            _primary.add_theme_color_override("font_color", Color.WHITE)
    elif _ready_pulse:
        _ready_pulse = false
        _primary.add_theme_stylebox_override("normal", AstraUI.style(Color(AstraUI.CYAN, 0.34), Color(AstraUI.CYAN, 0.75), 8, 1, 10))
        _primary.add_theme_stylebox_override("hover", AstraUI.style(Color(AstraUI.CYAN, 0.5), AstraUI.CYAN, 8, 1, 10))
        _primary.add_theme_color_override("font_color", AstraUI.TEXT)

func _swap_view() -> void:
    if _view != null:
        _holder.remove_child(_view)
        _view.queue_free()
    _view_phase = session.phase
    var script: Script = BriefingView
    match session.phase:
        "INVESTIGATION": script = InvestigationView
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
    var accent: Color = PHASE_COLORS.get(session.phase, AstraUI.CYAN)
    _center.add_theme_stylebox_override("panel", AstraUI.style(Color(0.03,0.05,0.08,0.89), Color(accent,0.25),12,1,16))
    _background.texture = AstraUI.texture(AstraArt.background("breach" if session.phase == "NIGHT" else "lounge") if session.phase in ["MEETING","VOTE","NIGHT"] else AstraArt.chapter(session.case_id))

func _on_phase_changed(phase: String) -> void:
    _announce_phase(phase)

func _announce_phase(phase: String) -> void:
    var accent: Color = PHASE_COLORS.get(phase, AstraUI.CYAN)
    match phase:
        "BRIEFING":
            fx.banner("DAY %d" % session.day, "%s · %s" % [str(session.case_data.get("title", "")), "사건 브리핑" if session.day == 1 else "밤사이 보고"], accent)
            fx.play("phase")
        "INVESTIGATION":
            fx.banner("현장 조사", "어디를 살필지, 무엇을 남길지 선택하세요.", accent)
            fx.play("phase")
        "INTERROGATION":
            fx.banner("개인 심문", "말의 내용보다, 말이 어긋나는 지점을 보세요.", accent)
            fx.play("phase")
        "MEETING":
            fx.banner("공개 회의", "알리바이가 공개되고, 반박이 시작됩니다.", accent)
            fx.play("phase")
        "VOTE":
            fx.banner("장기수면 격리 투표", "최다 득표자는 사건이 끝날 때까지 포드로 이동합니다. 사망 처리가 아닙니다.", accent)
            fx.play("alert")
        "NIGHT":
            fx.banner("밤", "Null이 움직입니다.", accent, 1.1)
            fx.flash(Color(0.02, 0.02, 0.1), 0.5, 0.9)
            fx.play("night")
        "RESULT":
            var win := session.outcome == "WIN"
            fx.banner("사건 종료", str(session.final_report.get("title", "")), AstraUI.GREEN if win else AstraUI.RED, 1.5)
            fx.play("win" if win else "lose")

func _on_notice(kind: String, payload: Dictionary) -> void:
    match kind:
        "private_event":
            fx.toast(AstraJosa.i(session.name_of(str(payload.get("npc_id", "")))) + " 따로 이야기하고 싶어 합니다.", AstraUI.PINK)

# ---------------------------------------------------------------- actions

func selected_id() -> String:
    return _selected

func select(npc_id: String) -> void:
    if not session.crew.has(npc_id) or not session.pending_event.is_empty():
        return
    if npc_id != _selected:
        fx.play("select")
    _selected = npc_id
    session.select(npc_id)

func _on_mark(npc_id: String) -> void:
    var mark := session.cycle_mark(npc_id)
    fx.play("click")
    if mark != "":
        fx.toast("%s — %s로 표시" % [session.name_of(npc_id), str(AstraUI.MARK_LABEL[mark])], AstraUI.MARK_COLORS[mark], 1.6)

func _on_primary() -> void:
    if not session.can_advance():
        return
    var warning := ""
    match session.phase:
        "INVESTIGATION":
            if session.investigation_ap > 0:
                warning = "현장을 더 살펴볼 시간이 있습니다. 조사를 마치고 승무원에게 확인하러 갈까요?"
        "INTERROGATION":
            if session.talk_ap > 0:
                warning = "아직 대화를 이어 갈 수 있습니다. 지금 회의를 소집할까요?"
        "MEETING":
            if session.meeting_actions_left > 0:
                warning = "아직 회의에 개입할 수 있습니다. 발언을 마치고 투표할까요?"
    if warning != "":
        confirm("다음 단계로 넘어갈까요?", warning, "넘어가기", func(): _advance())
    else:
        _advance()

func _advance() -> void:
    fx.play("click")
    session.advance()

func open_clue_picker(title: String, clues: Array, callback: Callable) -> void:
    var list := AstraUI.vbox(8)
    if clues.is_empty():
        list.add_child(AstraUI.label("고를 수 있는 단서가 없습니다.", 15, AstraUI.MUTED))
    var holder := []
    for index in range(clues.size() - 1, -1, -1):
        var card := AstraClueCard.new()
        card.setup(session, clues[index], true, true)
        card.pressed.connect(func(clue_id: String):
            if not holder.is_empty() and is_instance_valid(holder[0]):
                holder[0].close(-1)
            callback.call(clue_id)
        )
        list.add_child(card)
    var scroller := AstraUI.scroll(list)
    scroller.custom_minimum_size = Vector2(0, 460)
    var modal := AstraModal.open(app.overlay_root(), title, scroller, [["닫기", AstraUI.MUTED]], Callable(), 720.0)
    holder.append(modal)

func confirm(title: String, body: String, ok_text: String, on_ok: Callable) -> void:
    var text := AstraUI.label(body, 16, AstraUI.TEXT, true)
    var handler := func(choice: int) -> void:
        if choice == 1:
            on_ok.call()
    AstraModal.open(app.overlay_root(), title, text, [["취소", AstraUI.MUTED], [ok_text, AstraUI.CYAN]], handler, 560.0)

func request_ai_line(npc_id: String, intent: String, result: Dictionary) -> void:
    app.request_ai_line(session, npc_id, intent, result)

func exit_to_title() -> void:
    app.show_title()

func restart_case() -> void:
    app.start_case(session.case_id, session.protocol)

func start_other_case(case_id: String) -> void:
    app.start_case(case_id, session.protocol)

func handle_hotkey(event: InputEventKey) -> bool:
    if session == null:
        return false
    var code := event.keycode
    var roster: Array = session.active_roster()
    if code >= KEY_1 and code < KEY_1 + roster.size():
        select(str(roster[code - KEY_1]))
        return true
    if code == KEY_SPACE or code == KEY_ENTER or code == KEY_KP_ENTER:
        # In a meeting, space belongs to the transcript: it steps to the next
        # speaker rather than skipping the whole phase (§20).
        if _view != null and _view.has_method("consume_advance") and _view.consume_advance():
            return true
        if not _primary.disabled and _primary.visible:
            _on_primary()
        return true
    if code == KEY_N:
        open_notebook()
        return true
    if code == KEY_M and session.has_feature("marks"):
        _on_mark(_selected)
        return true
    if code == KEY_H:
        _open_screen_help()
        return true
    return false

func open_notebook() -> void:
    if app.modal_open():
        return
    _notebook = AstraNotebookPanel.new()
    _notebook.custom_minimum_size = Vector2(0, 520)
    _notebook.setup(session)
    AstraModal.open(app.overlay_root(), "조사 노트 / 사실과 나의 가설", _notebook, [["현장으로 돌아가기", AstraUI.CYAN]], Callable(), 1040)
