extends "res://scripts/main_v007.gd"

const InteractiveBoardScript = preload("res://scripts/interactive_notebook_board.gd")
const FeedbackFXScript = preload("res://scripts/feedback_fx.gd")

var feedback_fx: AstraFeedbackFX
var _last_personal_result: String = ""

func _replace_version_label(node: Node) -> void:
    if node is Label:
        var label := node as Label
        if label.text.begins_with("0.0.3") or label.text.begins_with("0.0.4") or label.text.begins_with("0.0.5") or label.text.begins_with("0.0.6") or label.text.begins_with("0.0.7"):
            label.text = "0.0.8 · Player Hypotheses · Echo Ward · Personal Events · FX · CI · %s" % meta_progress.archive_rank()
        elif label.text == "ASTRA ARCHIVE":
            label.text = "ASTRA // OBSERVER ARCHIVE"
    for child in node.get_children():
        _replace_version_label(child)

func _launch_case(preferred: String = "") -> void:
    notebook_open = false
    _meeting_ai_day = -1
    _meeting_ai_queue.clear()
    _meeting_ai_inflight = false
    _last_relationship_event_count = 0
    _meta_recorded_key = ""
    _last_personal_result = ""
    game = AstraHypothesisGameState.new()
    var hypothesis := game as AstraHypothesisGameState
    hypothesis.preferred_case_id = preferred
    game.state_changed.connect(_refresh)
    var seed := int(Time.get_unix_time_from_system()) % 1000000
    game.setup(seed)
    _build_game_ui()
    _install_ai_client_v006()
    _install_feedback_fx()
    _refresh()
    if feedback_fx != null:
        feedback_fx.flash(c_cyan, 0.10)

func _install_feedback_fx() -> void:
    if feedback_fx != null and is_instance_valid(feedback_fx):
        feedback_fx.queue_free()
    feedback_fx = FeedbackFXScript.new()
    add_child(feedback_fx)

func _hypothesis_game() -> AstraHypothesisGameState:
    return game as AstraHypothesisGameState

func _refresh_actions() -> void:
    var hypothesis := _hypothesis_game()
    if hypothesis == null:
        super._refresh_actions()
        return

    if notebook_open:
        for child in action_box.get_children():
            child.queue_free()
        detail_box.text = "[font_size=27][color=#55d6ff]PLAYER HYPOTHESIS BOARD[/color][/font_size]\n[color=#8ea5c5]%s · Day %d · Evidence %d/8 · Your links %d[/color]\n\n[color=#ffd36a]왼쪽 증거를 고른 뒤 오른쪽 Crew를 클릭해 직접 가설을 만드세요.[/color]" % [hypothesis.case_subtitle, hypothesis.day, hypothesis.discovered_evidence.size(), hypothesis.manual_links.size()]
        var board := InteractiveBoardScript.new()
        board.configure(hypothesis)
        board.hypothesis_changed.connect(_on_hypothesis_changed)
        action_box.add_child(board)
        _add_action("← 사건 화면으로 돌아가기", c_cyan, _close_notebook, "가설 연결은 이번 사건 동안 유지")
        return

    if not hypothesis.pending_personal_event.is_empty():
        _show_personal_event(hypothesis)
        return

    super._refresh_actions()

    if _last_personal_result != "":
        detail_box.append_text("\n\n[font_size=18][color=#ff9ed1]PRIVATE CHANNEL RESULT[/color][/font_size]\n%s" % _last_personal_result)
        _last_personal_result = ""

func _show_personal_event(hypothesis: AstraHypothesisGameState) -> void:
    for child in action_box.get_children():
        child.queue_free()
    var event: Dictionary = hypothesis.pending_personal_event
    var npc_id := str(event.get("npc_id", ""))
    var npc_name := npc_id
    if npc_id in hypothesis.npcs:
        npc_name = hypothesis.npcs[npc_id].display_name
        hypothesis.selected_npc_id = npc_id
        _show_selected_profile()
    detail_box.append_text("\n\n[font_size=24][color=#ff9ed1]%s[/color][/font_size]\n%s" % [str(event.get("title", "PRIVATE CHANNEL")), str(event.get("prompt", ""))])
    var choices: Array = event.get("choices", [])
    for i in range(choices.size()):
        var choice: Dictionary = choices[i]
        _add_action(str(choice.get("label", "선택")), c_green if i == 0 else c_panel, _resolve_personal_event.bind(i), "%s와의 관계에 영향을 줄 수 있음" % npc_name)

func _resolve_personal_event(choice_index: int) -> void:
    var hypothesis := _hypothesis_game()
    if hypothesis == null:
        return
    var npc_id := str(hypothesis.pending_personal_event.get("npc_id", ""))
    _last_personal_result = hypothesis.resolve_personal_event(choice_index)
    if npc_id != "":
        meta_progress.record_personal_choice(npc_id, choice_index)
    if feedback_fx != null:
        feedback_fx.play("click")
        feedback_fx.flash(Color("ff9ed1"), 0.09)
    _refresh_actions()
    _refresh_npcs()

func _on_hypothesis_changed() -> void:
    meta_progress.record_hypothesis_link()
    if feedback_fx != null:
        feedback_fx.play("click")
        feedback_fx.flash(c_gold, 0.055)

func _investigate(location: String) -> void:
    var hypothesis := _hypothesis_game()
    var before := 0
    if hypothesis != null:
        before = hypothesis.discovered_evidence.size()
    super._investigate(location)
    if hypothesis != null and hypothesis.discovered_evidence.size() > before and feedback_fx != null:
        feedback_fx.play("evidence")
        feedback_fx.flash(c_gold, 0.15)

func _talk(intent: String) -> void:
    if feedback_fx != null:
        feedback_fx.play("click")
    super._talk(intent)

func _advance() -> void:
    if feedback_fx != null:
        feedback_fx.play("click")
        feedback_fx.flash(c_cyan, 0.07)
    super._advance()

func _vote(npc_id: String) -> void:
    if feedback_fx != null:
        feedback_fx.play("alert")
        feedback_fx.flash(c_red, 0.18)
        feedback_fx.shake(self, 7.0)
    super._vote(npc_id)

func _refresh() -> void:
    super._refresh()
    var hypothesis := _hypothesis_game()
    if hypothesis == null:
        return
    if phase_label != null:
        phase_label.text = "DAY %d · %s · %s · HYP %d" % [hypothesis.day, hypothesis.phase_display_name(), hypothesis.case_subtitle, hypothesis.manual_links.size()]
