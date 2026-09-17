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
const STEP_LABELS := {"BRIEFING": "브리핑", "INVESTIGATION": "조사", "INTERROGATION": "심문", "MEETING": "회의", "VOTE": "투표", "NIGHT": "밤"}
const PHASE_COLORS := {
    "BRIEFING": AstraUI.CYAN, "INVESTIGATION": AstraUI.GOLD, "INTERROGATION": AstraUI.GREEN,
    "MEETING": AstraUI.PINK, "VOTE": AstraUI.RED, "NIGHT": AstraUI.NIGHT, "RESULT": AstraUI.GOLD
}

var app
var session: AstraGameSession
var fx: AstraFeedbackFX
var archive_change: Dictionary = {}

var _day_label: Label
var _stepper: HBoxContainer
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
    var margin := AstraUI.margin(AstraUI.vbox(10), 16, 12, 16, 12)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(margin)
    var root: VBoxContainer = margin.get_child(0)

    var top := AstraUI.hbox(14)
    root.add_child(top)
    var brand := AstraUI.vbox(0)
    top.add_child(brand)
    brand.add_child(AstraUI.label("ASTRA", 22, AstraUI.CYAN))
    brand.add_child(AstraUI.label("%s · %s" % [str(session.case_data.get("code", "")), str(session.case_data.get("title", ""))], 12, AstraUI.MUTED))
    _day_label = AstraUI.label("", 20, AstraUI.TEXT)
    top.add_child(_day_label)
    _stepper = AstraUI.hbox(4)
    _stepper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _stepper.alignment = BoxContainer.ALIGNMENT_CENTER
    top.add_child(_stepper)
    _ap_label = AstraUI.rich(15)
    _ap_label.custom_minimum_size = Vector2(230, 0)
    _ap_label.size_flags_horizontal = Control.SIZE_SHRINK_END
    _ap_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    top.add_child(_ap_label)
    var menu := AstraUI.button("메뉴 · Esc", AstraUI.MUTED, 14, 38)
    menu.pressed.connect(func(): app.show_pause_menu())
    top.add_child(menu)

    _hint_panel = AstraUI.panel(Color(AstraUI.CYAN, 0.06), Color(AstraUI.CYAN, 0.3), 8, 8)
    root.add_child(_hint_panel)
    var hint_row := AstraUI.hbox(10)
    _hint_panel.add_child(hint_row)
    _hint = AstraUI.label("", 15, AstraUI.TEXT, true)
    hint_row.add_child(_hint)
    hint_row.add_child(AstraUI.chip("사건 시간대 " + session.window_text(), AstraUI.GOLD, 13))

    var roster_panel := AstraUI.panel(AstraUI.PANEL, AstraUI.BORDER, 12, 8)
    root.add_child(roster_panel)
    var roster_box := AstraUI.vbox(6)
    roster_panel.add_child(roster_box)
    var roster_head := AstraUI.hbox(6)
    roster_box.add_child(roster_head)
    roster_head.add_child(AstraUI.label("승무원", 14, AstraUI.CYAN))
    roster_head.add_child(AstraUI.spacer())
    roster_head.add_child(AstraUI.label("표시: N 의심 · ✓ 신뢰 · ? 보류", 11, AstraUI.DIM))
    _roster = AstraUI.hbox(6)
    roster_box.add_child(_roster)
    var hotkey := 1
    for npc_id in AstraCrewCatalog.ORDER:
        var card := AstraCrewCard.new()
        card.setup(npc_id, hotkey)
        card.selected.connect(select)
        card.mark_pressed.connect(_on_mark)
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        _roster.add_child(card)
        _cards[npc_id] = card
        hotkey += 1

    var body := AstraUI.hbox(14)
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(body)

    _center = AstraUI.panel(AstraUI.PANEL, AstraUI.BORDER, 12, 16)
    _center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_child(_center)
    _holder = Control.new()
    _holder.clip_contents = true
    _holder.mouse_filter = Control.MOUSE_FILTER_PASS
    _center.add_child(_holder)

    _notebook = AstraNotebookPanel.new()
    _notebook.custom_minimum_size = Vector2(340, 0)
    body.add_child(_notebook)
    _notebook.setup(session)

    var bottom := AstraUI.hbox(12)
    root.add_child(bottom)
    _summary = AstraUI.rich(14)
    _summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bottom.add_child(_summary)
    _primary = AstraUI.button("", AstraUI.CYAN, 18, 54, true)
    _primary.custom_minimum_size = Vector2(320, 54)
    _primary.focus_mode = Control.FOCUS_NONE
    _primary.pressed.connect(_on_primary)
    bottom.add_child(_primary)

# ---------------------------------------------------------------- state sync

func _on_changed() -> void:
    if session == null:
        return
    if not session.crew.has(_selected):
        _selected = session.selected_id
    if session.phase == "INTERROGATION" and not session.pending_event.is_empty():
        _selected = str(session.pending_event.get("npc_id", _selected))
    _refresh_top()
    _refresh_roster()
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

func _refresh_top() -> void:
    _day_label.text = "DAY %d / %d" % [session.day, AstraGameSession.MAX_DAYS] if session.phase != "RESULT" else "사건 종료"
    AstraUI.clear(_stepper)
    var current := STEPS.find(session.phase)
    for index in range(STEPS.size()):
        var phase_id := str(STEPS[index])
        var color: Color = PHASE_COLORS.get(phase_id, AstraUI.CYAN)
        var active := index == current
        var done := current >= 0 and index < current or session.phase == "RESULT"
        var bg := Color(color, 0.25) if active else Color(AstraUI.PANEL_2, 0.8)
        var border := color if active else (Color(color, 0.35) if done else AstraUI.BORDER)
        var pill := PanelContainer.new()
        var box := AstraUI.style(bg, border, 14, 1, 10)
        box.content_margin_top = 4
        box.content_margin_bottom = 4
        pill.add_theme_stylebox_override("panel", box)
        pill.add_child(AstraUI.label(str(STEP_LABELS[phase_id]), 14, AstraUI.TEXT if active else (AstraUI.MUTED if done else AstraUI.DIM)))
        _stepper.add_child(pill)
        if index < STEPS.size() - 1:
            _stepper.add_child(AstraUI.label("›", 14, AstraUI.DIM))
    match session.phase:
        "INVESTIGATION":
            _ap_label.text = "[right][color=#%s]조사[/color] %s[/right]" % [AstraUI.hex(AstraUI.MUTED), AstraUI.pips(session.investigation_ap, session.investigation_ap_max(), AstraUI.GOLD)]
        "INTERROGATION":
            _ap_label.text = "[right][color=#%s]심문[/color] %s[/right]" % [AstraUI.hex(AstraUI.MUTED), AstraUI.pips(session.talk_ap, session.talk_ap_max(), AstraUI.GREEN)]
        "MEETING":
            _ap_label.text = "[right][color=#%s]발언권[/color] %s[/right]" % [AstraUI.hex(AstraUI.MUTED), AstraUI.pips(session.meeting_actions_left, session.meeting_actions_max(), AstraUI.CYAN)]
        _:
            _ap_label.text = "[right][color=#%s]%s[/color][/right]" % [AstraUI.hex(AstraUI.MUTED), session.protocol_name()]
    _hint.text = "지금 할 일  /  " + session.phase_hint()
    _hint_panel.visible = app.settings.show_hints or session.phase in ["VOTE", "NIGHT"]

func _refresh_roster() -> void:
    var intentions := {}
    if session.phase in ["MEETING", "VOTE"] and not session.vote_cast:
        intentions = session.vote_intentions()
    for npc_id in _cards.keys():
        _cards[npc_id].refresh(session, npc_id == _selected, str(intentions.get(npc_id, "")))

func _refresh_bottom() -> void:
    var member := session.npc(_selected)
    if member != null:
        var claim: Dictionary = session.known_claims.get(_selected, {})
        var claim_text := "진술 미확보"
        if not claim.is_empty():
            var mates: Array = claim.get("companions", [])
            claim_text = "진술: %s · %s" % [session.room_name(str(claim.get("position", ""))), "혼자" if mates.is_empty() else session.names_of(mates)]
        var mark := str(session.marks.get(_selected, ""))
        var mark_text := ""
        if mark != "":
            mark_text = " · [color=#%s]%s[/color]" % [AstraUI.hex(AstraUI.MARK_COLORS[mark]), str(AstraUI.MARK_LABEL[mark])]
        _summary.text = "[color=#%s]선택[/color]  [b][color=#%s]%s[/color][/b] %s · %s%s" % [AstraUI.hex(AstraUI.DIM), AstraUI.hex(member.accent), member.display_name, member.job, claim_text, mark_text]
    else:
        _summary.text = ""
    _primary.visible = session.phase != "RESULT"
    _primary.text = session.advance_label() + ("  →" if session.can_advance() else "")
    _primary.disabled = not session.can_advance()

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
    _center.add_theme_stylebox_override("panel", AstraUI.style(AstraUI.PANEL if session.phase != "NIGHT" else Color("080b1d"), Color(accent, 0.35), 12, 1, 16))

func _on_phase_changed(phase: String) -> void:
    _announce_phase(phase)

func _announce_phase(phase: String) -> void:
    var accent: Color = PHASE_COLORS.get(phase, AstraUI.CYAN)
    match phase:
        "BRIEFING":
            fx.banner("DAY %d" % session.day, "%s · %s" % [str(session.case_data.get("title", "")), "사건 브리핑" if session.day == 1 else "밤사이 보고"], accent)
            fx.play("phase")
        "INVESTIGATION":
            fx.banner("현장 조사", "흔적 두 개의 명단이 겹치는 사람을 찾으세요.", accent)
            fx.play("phase")
        "INTERROGATION":
            fx.banner("개인 심문", "말의 내용보다, 말이 어긋나는 지점을 보세요.", accent)
            fx.play("phase")
        "MEETING":
            fx.banner("공개 회의", "알리바이가 공개되고, 반박이 시작됩니다.", accent)
            fx.play("phase")
        "VOTE":
            fx.banner("격리 투표", "한 명을 격리합니다. 조사관의 표는 2표입니다.", accent)
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
    session.selected_id = npc_id
    _on_changed()

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
                warning = "조사 행동력이 %d 남았습니다. 남은 행동력은 다음 날로 넘어가지 않습니다." % session.investigation_ap
        "INTERROGATION":
            if session.talk_ap > 0:
                warning = "심문 행동력이 %d 남았습니다. 남은 행동력은 다음 날로 넘어가지 않습니다." % session.talk_ap
        "MEETING":
            if session.meeting_actions_left > 0:
                warning = "발언권이 %d회 남았습니다. 단서를 공개하거나 지목·변호하지 않고 투표로 넘어갈까요?" % session.meeting_actions_left
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
    if code >= KEY_1 and code <= KEY_8:
        select(str(AstraCrewCatalog.ORDER[code - KEY_1]))
        return true
    if code == KEY_SPACE or code == KEY_ENTER or code == KEY_KP_ENTER:
        if not _primary.disabled and _primary.visible:
            _on_primary()
        return true
    if code == KEY_N:
        _notebook.cycle_tab()
        return true
    if code == KEY_M:
        _on_mark(_selected)
        return true
    return false
