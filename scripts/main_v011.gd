extends "res://scripts/main_v010.gd"

const PRESENTATION_VERSION := "0.1.1"
const CharacterPresentationScript = preload("res://scripts/character_presentation.gd")
const MeetingCinematicScript = preload("res://scripts/meeting_cinematic.gd")

var character_presentation
var meeting_cinematic
var _phase_signature: String = ""
var _last_selected_character: String = ""

func _show_title_screen() -> void:
    _phase_signature = ""
    _last_selected_character = ""
    character_presentation = null
    meeting_cinematic = null
    super._show_title_screen()
    _replace_v011_labels(self)

func _replace_v011_labels(node: Node) -> void:
    if node is Label:
        var label := node as Label
        if label.text.begins_with("0.1.0 VERTICAL SLICE"):
            label.text = "0.1.1 CHARACTER PERFORMANCE · 표정, 대화, 회의 연출을 강화한 Vertical Slice"
        elif label.text == "ASTRA 0.1.0 · HOW TO PLAY":
            label.text = "ASTRA 0.1.1 · HOW TO PLAY"
    for child in node.get_children():
        _replace_v011_labels(child)

func _launch_case(preferred: String = "") -> void:
    _phase_signature = ""
    _last_selected_character = ""
    super._launch_case(preferred)
    var hypothesis = _hypothesis_game()
    if hypothesis != null and feedback_fx != null and is_instance_valid(feedback_fx):
        feedback_fx.play_case_sting(hypothesis.case_id)
        feedback_fx.phase_banner(hypothesis.case_subtitle.to_upper(), "OBSERVER LINK ESTABLISHED · %s" % selected_protocol, c_cyan)

func _build_game_ui() -> void:
    super._build_game_ui()
    _install_character_presentation()
    _install_meeting_cinematic()
    _replace_v011_labels(self)

func _install_character_presentation() -> void:
    if portrait_rect == null:
        return
    character_presentation = CharacterPresentationScript.new()
    portrait_rect.add_child(character_presentation)
    character_presentation.attach(portrait_rect)

func _install_meeting_cinematic() -> void:
    meeting_cinematic = MeetingCinematicScript.new()
    add_child(meeting_cinematic)

func _show_selected_profile() -> void:
    super._show_selected_profile()
    if character_presentation == null or not is_instance_valid(character_presentation):
        return
    if game == null or game.selected_npc_id not in game.npcs:
        return
    var npc: NPCState = game.npcs[game.selected_npc_id]
    var expression := "calm"
    if game.has_method("expression_slot"):
        expression = str(game.call("expression_slot", game.selected_npc_id))
    var changed := game.selected_npc_id != _last_selected_character
    _last_selected_character = game.selected_npc_id
    character_presentation.present(npc.display_name, npc.job, npc.accent, expression, changed)

func _select_npc(npc_id: String) -> void:
    var changed := npc_id != game.selected_npc_id
    super._select_npc(npc_id)
    if changed and feedback_fx != null and is_instance_valid(feedback_fx):
        feedback_fx.play("select")
    if changed and character_presentation != null and is_instance_valid(character_presentation):
        character_presentation.cue("FOCUS ACQUIRED", game.npcs[npc_id].accent)

func _talk(intent: String) -> void:
    var npc_id := game.selected_npc_id
    super._talk(intent)
    if feedback_fx != null and is_instance_valid(feedback_fx):
        feedback_fx.play("talk")
    if character_presentation != null and is_instance_valid(character_presentation) and npc_id in game.npcs:
        var npc: NPCState = game.npcs[npc_id]
        character_presentation.cue(_intent_tag(intent), npc.accent)
        character_presentation.pulse(str(game.call("expression_slot", npc_id)) if game.has_method("expression_slot") else "calm")

func _intent_tag(intent: String) -> String:
    match intent:
        "ALIBI": return "ALIBI RESPONSE"
        "MOTIVE": return "MOTIVE RESPONSE"
        "EVIDENCE": return "EVIDENCE REACTION"
        "CONTRADICTION": return "CONTRADICTION PRESSURE"
        "REASSURE": return "TRUST RESPONSE"
        "CONFIDE": return "PRIVATE JUDGMENT"
        "PRESSURE": return "PRESSURE RESPONSE"
    return intent + " RESPONSE"

func _investigate(location: String) -> void:
    var before := game.discovered_evidence.size()
    super._investigate(location)
    if game.discovered_evidence.size() > before and feedback_fx != null and is_instance_valid(feedback_fx):
        feedback_fx.phase_banner("EVIDENCE ACQUIRED", location, c_gold)

func _refresh() -> void:
    super._refresh()
    var hypothesis = _hypothesis_game()
    if hypothesis == null:
        return
    var signature := "%s:%d:%s" % [hypothesis.phase_name(), hypothesis.day, hypothesis.case_id]
    if signature == _phase_signature:
        return
    _phase_signature = signature
    _perform_phase_transition(hypothesis)

func _perform_phase_transition(hypothesis) -> void:
    if feedback_fx == null or not is_instance_valid(feedback_fx):
        return
    var phase := hypothesis.phase_name()
    var title := hypothesis.phase_display_name().to_upper()
    var subtitle := hypothesis.case_subtitle
    var accent := c_cyan

    match phase:
        "BRIEFING":
            title = "INCIDENT BRIEF"
            subtitle = "%s · %s" % [hypothesis.case_subtitle, selected_protocol]
        "INVESTIGATION":
            title = "FIELD INVESTIGATION"
            subtitle = "한정된 행동력으로 현장 기록을 확보하십시오."
            accent = c_gold
        "INTERROGATION":
            title = "PRIVATE INTERROGATION"
            subtitle = "말의 내용뿐 아니라 반응과 관계 변화를 관찰하십시오."
            accent = c_green
        "MEETING":
            title = "PUBLIC MEETING"
            subtitle = "공개 채널이 열렸습니다. 발언과 반박이 기록됩니다."
            accent = Color("ff9ed1")
        "VOTE":
            title = "CASE THEORY / ISOLATION"
            subtitle = "두 용의자 가설을 잠근 뒤 한 명을 격리하십시오."
            accent = c_red
        "RESULT":
            title = "INCIDENT CLOSED"
            subtitle = "Archive에 결과와 추리 평가를 기록합니다."
            accent = c_green if hypothesis.result_title == "NULL IDENTIFIED" else c_red

    feedback_fx.play("complete" if phase == "RESULT" else "phase")
    feedback_fx.phase_banner(title, subtitle, accent)

    if phase == "MEETING" and meeting_cinematic != null and is_instance_valid(meeting_cinematic):
        meeting_cinematic.play(hypothesis.meeting_events, hypothesis.npcs, 4)
    elif meeting_cinematic != null and is_instance_valid(meeting_cinematic):
        meeting_cinematic.stop()
