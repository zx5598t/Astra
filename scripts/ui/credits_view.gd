class_name AstraCreditsView
extends Control

# Credits are part of the story (§36): after the last image and ASTRA's last
# line, the people of the ship, the explorer's name, a thank-you, and then
# DEEP RECONSTRUCTION opening with a small flourish (§75). Click / Space
# hurries it; the last step always waits for the player.

signal finished

var _lines: VBoxContainer
var _unlock: PanelContainer
var _continue: Button
var _tween: Tween
var _stage: int = 0

func setup(session: AstraGameSession) -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var bg := ColorRect.new()
    bg.color = Color("03050a")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    _lines = AstraUI.vbox(10)
    _lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _lines.alignment = BoxContainer.ALIGNMENT_CENTER
    add_child(_lines)
    var entries: Array = [["A S T R A", 64, AstraUI.TEXT], ["마지막 교신", AstraUI.T_TITLE, AstraUI.CYAN], ["", AstraUI.T_UI, AstraUI.DIM]]
    for id in AstraCrewCatalog.ORDER:
        entries.append(["%s  ·  %s" % [AstraCrewCatalog.display_name(str(id)), AstraCrewCatalog.role_short(str(id))], AstraUI.T_BODY, AstraCrewCatalog.accent(str(id))])
    entries.append(["", AstraUI.T_UI, AstraUI.DIM])
    entries.append(["탐사요원  ·  %s" % AstraUI.player_name(session), AstraUI.T_HEAD, AstraUI.GOLD])
    entries.append(["", AstraUI.T_UI, AstraUI.DIM])
    entries.append(["끝까지 함께해 주셔서 고맙습니다.", AstraUI.T_BODY, AstraUI.MUTED])
    for entry in entries:
        var label := AstraUI.label(str(entry[0]), int(entry[1]), entry[2])
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.modulate.a = 0.0
        _lines.add_child(label)
    _unlock = AstraUI.reading_panel(AstraUI.VIOLET, 0.96)
    _unlock.anchor_left = 0.5
    _unlock.anchor_right = 0.5
    _unlock.anchor_top = 0.5
    _unlock.anchor_bottom = 0.5
    _unlock.offset_left = -330
    _unlock.offset_right = 330
    _unlock.offset_top = -120
    _unlock.offset_bottom = 120
    _unlock.visible = false
    add_child(_unlock)
    var box := AstraUI.vbox(8)
    _unlock.add_child(box)
    var head := AstraUI.label("심층 재구성  ·  DEEP RECONSTRUCTION", AstraUI.T_TITLE, AstraUI.VIOLET)
    head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(head)
    var tag := AstraUI.label("UNLOCKED", AstraUI.T_HEAD, AstraUI.GOLD)
    tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(tag)
    var blurb := AstraUI.prose("같은 사람들, 새로운 재구성. 한 번 쓰러지면 끝나는 연속 도전입니다. 사람을 읽는 실력만으로 얼마나 깊이 내려갈 수 있을까요.", AstraUI.T_UI, AstraUI.TEXT)
    blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(blurb)
    _continue = AstraUI.primary_button("계속   →", AstraUI.VIOLET)
    _continue.pressed.connect(func(): finished.emit())
    box.add_child(_continue)
    _play.call_deferred()

func _play() -> void:
    _tween = create_tween()
    var step := 0.08 if AstraUI.reduce_motion else 0.55
    for child in _lines.get_children():
        _tween.tween_property(child, "modulate:a", 1.0, step)
    _tween.tween_interval(0.4 if AstraUI.reduce_motion else 2.2)
    _tween.tween_callback(_show_unlock)

func _show_unlock() -> void:
    if _stage >= 1:
        return
    _stage = 1
    if _tween != null and _tween.is_valid():
        _tween.kill()
    for child in _lines.get_children():
        child.modulate.a = 1.0
    _lines.modulate = Color(1, 1, 1, 0.06)
    _unlock.visible = true
    _unlock.pivot_offset = _unlock.size * 0.5
    if not AstraUI.reduce_motion:
        _unlock.scale = Vector2(0.85, 0.85)
        _unlock.modulate.a = 0.0
        var pop := create_tween().set_parallel(true)
        pop.tween_property(_unlock, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        pop.tween_property(_unlock, "modulate:a", 1.0, 0.35)
    _continue.grab_focus.call_deferred()

func consume_advance() -> bool:
    if _stage == 0:
        _show_unlock()
        return true
    finished.emit()
    return true

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _stage == 0:
        _show_unlock()
