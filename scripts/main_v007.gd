extends "res://scripts/main_v006.gd"

const NotebookBoardScript = preload("res://scripts/notebook_board.gd")
const EnvironmentBackdropScript = preload("res://scripts/environment_backdrop.gd")

var meta_progress := AstraMetaProgress.new()
var _last_relationship_event_count: int = 0
var _meta_recorded_key: String = ""

func _ready() -> void:
    meta_progress.load_data()
    super._ready()

func _replace_version_label(node: Node) -> void:
    if node is Label:
        var label := node as Label
        if label.text.begins_with("0.0.3") or label.text.begins_with("0.0.4") or label.text.begins_with("0.0.5") or label.text.begins_with("0.0.6"):
            label.text = "0.0.7 · Visual Link Board · Relationship Events · Persistent Archive · %s" % meta_progress.archive_rank()
        elif label.text == "CASE SHUFFLE PROTOCOL" or label.text == "INCIDENT ZERO":
            label.text = "ASTRA ARCHIVE"
        elif label.text.begins_with("Two incidents") or label.text == "DEAD AIR":
            label.text = meta_progress.summary()
    for child in node.get_children():
        _replace_version_label(child)

func _show_background() -> void:
    super._show_background()
    if game is AstraProgressionGameState:
        var backdrop := EnvironmentBackdropScript.new()
        backdrop.set_case((game as AstraProgressionGameState).case_id)
        backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        add_child(backdrop)

func _launch_case(preferred: String = "") -> void:
    notebook_open = false
    _meeting_ai_day = -1
    _meeting_ai_queue.clear()
    _meeting_ai_inflight = false
    _last_relationship_event_count = 0
    _meta_recorded_key = ""
    game = AstraProgressionGameState.new()
    var progression := game as AstraProgressionGameState
    progression.preferred_case_id = preferred
    game.state_changed.connect(_refresh)
    var seed := int(Time.get_unix_time_from_system()) % 1000000
    game.setup(seed)
    _build_game_ui()
    _install_ai_client_v006()
    _refresh()

func _progression_game() -> AstraProgressionGameState:
    return game as AstraProgressionGameState

func _refresh_actions() -> void:
    var progression := _progression_game()
    if progression == null:
        super._refresh_actions()
        return

    if notebook_open:
        for child in action_box.get_children():
            child.queue_free()
        detail_box.text = "[font_size=27][color=#55d6ff]INVESTIGATOR NOTEBOOK[/color][/font_size]\n[color=#8ea5c5]%s · Day %d · Evidence %d/8[/color]\n\n%s" % [progression.case_subtitle, progression.day, progression.discovered_evidence.size(), progression.relationship_event_report()]
        var board := NotebookBoardScript.new()
        board.configure(progression)
        action_box.add_child(board)
        _add_action("← 사건 화면으로 돌아가기", c_cyan, _close_notebook, "현재 phase로 복귀")
        return

    super._refresh_actions()

    if progression.relationship_event_log.size() > _last_relationship_event_count:
        var event := progression.latest_relationship_event()
        _last_relationship_event_count = progression.relationship_event_log.size()
        meta_progress.remember_relationship_event(str(event.get("key", "")))
        detail_box.append_text("\n\n[font_size=18][color=#ff9ed1]RELATIONSHIP EVENT[/color][/font_size]\n%s" % str(event.get("text", "")))

    if progression.phase_name() == "RESULT":
        _record_meta_progress_if_needed()
        _add_info("ARCHIVE · %s" % meta_progress.summary())

func _show_selected_profile() -> void:
    super._show_selected_profile()
    var progression := _progression_game()
    if progression == null or progression.selected_npc_id not in progression.npcs:
        return
    var path := progression.expression_asset_path(progression.selected_npc_id)
    if path != "" and ResourceLoader.exists(path):
        portrait_rect.texture = load(path)
        portrait_rect.modulate = Color.WHITE
    var old_overlay := portrait_rect.get_node_or_null("ExpressionOverlay")
    if old_overlay != null:
        old_overlay.queue_free()
    var overlay_path := progression.expression_overlay_path(progression.selected_npc_id)
    if ResourceLoader.exists(overlay_path):
        var overlay := TextureRect.new()
        overlay.name = "ExpressionOverlay"
        overlay.texture = load(overlay_path)
        overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
        overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        portrait_rect.add_child(overlay)
    detail_box.append_text("\n[color=#8ea5c5]Portrait Slot[/color]  %s" % progression.expression_slot(progression.selected_npc_id).to_upper())

func _record_meta_progress_if_needed() -> void:
    var progression := _progression_game()
    if progression == null or not progression.game_over:
        return
    var key := "%d:%s" % [progression.seed_value, progression.case_id]
    if key == _meta_recorded_key:
        return
    _meta_recorded_key = key
    var correct := 0
    for item in progression.day_vote_history:
        if str(item.get("role", "")) == "NULL":
            correct += 1
    var gain := progression.discovered_evidence.size() + progression.contradiction_register.size() * 2 + correct * 4
    meta_progress.record_case(progression.case_id, gain, correct)

func _refresh() -> void:
    super._refresh()
    var progression := _progression_game()
    if progression == null:
        return
    if score_label != null:
        score_label.text = "SCORE %04d  ·  ARCHIVE %03d" % [progression.score, meta_progress.total_insight]
