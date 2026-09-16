class_name AstraCaseTheoryPanel
extends VBoxContainer

signal theory_submitted(message: String)

var state: AstraDeductionGameState
var primary := OptionButton.new()
var secondary := OptionButton.new()
var confidence := HSlider.new()
var confidence_label := Label.new()
var status_label := Label.new()

func configure(game_state: AstraDeductionGameState) -> void:
    state = game_state
    custom_minimum_size = Vector2(0, 310)
    add_theme_constant_override("separation", 10)
    _build()

func _build() -> void:
    for child in get_children():
        child.queue_free()
    var title := Label.new()
    title.text = "CASE THEORY // TWO-SUSPECT MODEL"
    title.add_theme_font_size_override("font_size", 20)
    title.add_theme_color_override("font_color", Color("ffd36a"))
    add_child(title)

    var hint := Label.new()
    hint.text = "이번 Day에서 가장 가능성이 높은 두 명을 지정하세요. 정답 여부는 사건 종료 전까지 공개되지 않습니다."
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint.add_theme_color_override("font_color", Color("91a7c6"))
    add_child(hint)

    primary = OptionButton.new()
    secondary = OptionButton.new()
    _populate(primary)
    _populate(secondary)
    primary.select(0)
    secondary.select(1 if secondary.item_count > 1 else 0)
    add_child(_row("PRIMARY SUSPECT", primary))
    add_child(_row("SECONDARY SUSPECT", secondary))

    confidence = HSlider.new()
    confidence.min_value = 0
    confidence.max_value = 100
    confidence.step = 5
    confidence.value = 60
    confidence.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    confidence.value_changed.connect(_on_confidence_changed)
    confidence_label = Label.new()
    confidence_label.text = "60%"
    var conf_row := HBoxContainer.new()
    var conf_title := Label.new()
    conf_title.text = "CONFIDENCE"
    conf_title.custom_minimum_size = Vector2(180, 0)
    conf_row.add_child(conf_title)
    conf_row.add_child(confidence)
    conf_row.add_child(confidence_label)
    add_child(conf_row)

    var submit := Button.new()
    submit.text = "SUBMIT CASE THEORY"
    submit.custom_minimum_size = Vector2(0, 46)
    submit.pressed.connect(_submit)
    add_child(submit)

    status_label = Label.new()
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_color_override("font_color", Color("8ea5c5"))
    add_child(status_label)

    if state.theory_ready_for_vote():
        status_label.text = "현재 제출 · %s" % state.theory_summary()

func _row(label_text: String, option: OptionButton) -> HBoxContainer:
    var row := HBoxContainer.new()
    var label := Label.new()
    label.text = label_text
    label.custom_minimum_size = Vector2(180, 0)
    option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(label)
    row.add_child(option)
    return row

func _populate(option: OptionButton) -> void:
    option.clear()
    if state == null:
        return
    for npc_id in state.crew_order:
        var npc: NPCState = state.npcs[npc_id]
        option.add_item("%s · %s%s" % [npc.display_name, npc.job, " · ISOLATED" if not npc.alive else ""])
        option.set_item_metadata(option.item_count - 1, npc_id)

func _on_confidence_changed(value: float) -> void:
    confidence_label.text = "%d%%" % int(value)

func _submit() -> void:
    if state == null or primary.selected < 0 or secondary.selected < 0:
        return
    var p := str(primary.get_item_metadata(primary.selected))
    var s := str(secondary.get_item_metadata(secondary.selected))
    var result := state.submit_theory(p, s, int(confidence.value))
    status_label.text = str(result.get("message", ""))
    status_label.add_theme_color_override("font_color", Color("5ee3a0") if bool(result.get("ok", false)) else Color("ff6f7f"))
    if bool(result.get("ok", false)):
        theory_submitted.emit(status_label.text)
