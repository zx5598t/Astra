class_name AstraOpeningView
extends Control

# The first thirty seconds of a new campaign: where you are, who you are, and
# the first face you meet. Everything after this — what went wrong, why one of
# the crew must go into a pod tonight, who to talk to first — is told by the
# crew in Stage 1's own morning scene, not by a menu or a rules page.

signal finished

const BEATS := [
    {"art": "res://assets/art031/backgrounds/medical.webp", "dark": true, "speaker": "",
        "action": "ASTRA · 장거리 탐사선",
        "text": "수면 포드의 뚜껑이 열린다. 당신은 이 배의 탐사요원이다. 방금 긴 잠에서 깨어났다."},
    {"art": "res://assets/art031/backgrounds/medical.webp", "speaker": "mira", "intro": "mira",
        "text": "깨어났네요. 천천히 숨 쉬어요. …저는 미라, 의무관이에요. 당신까지 다섯 명이 먼저 깨어났어요."},
    {"art": "res://assets/art031/backgrounds/medical.webp", "speaker": "mira", "expression": "suspicious",
        "text": "일어나자마자 미안해요. 이상한 일이 하나 있어요. 다들 모여 있으니까 같이 가요."}
]

var _app
var _index: int = -1
var _stage: AstraVNStage
var _done: bool = false

func setup(app_node) -> void:
    _app = app_node
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Color(0.008, 0.012, 0.026, 1.0)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    _stage = AstraVNStage.new()
    add_child(_stage)
    _stage.advanced.connect(_advance)
    var skip := AstraUI.button("건너뛰기  ▸▸", AstraUI.MUTED, AstraUI.T_META, 34)
    skip.anchor_left = 1.0
    skip.anchor_right = 1.0
    skip.offset_left = -170.0
    skip.offset_right = -16.0
    skip.offset_top = 14.0
    skip.offset_bottom = 48.0
    skip.pressed.connect(_finish)
    add_child(skip)
    _advance()

func _advance() -> void:
    if _done:
        return
    _index += 1
    if _index >= BEATS.size():
        _finish()
        return
    var beat: Dictionary = Dictionary(BEATS[_index]).duplicate()
    beat["caption"] = "%d / %d" % [_index + 1, BEATS.size()]
    _stage.show_beat(beat)
    if _app != null and _app.fx != null:
        _app.fx.play("talk" if str(beat.get("speaker", "")) != "" else "phase")

func _finish() -> void:
    if _done:
        return
    _done = true
    finished.emit()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            _finish()
        elif event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
            _stage.consume_advance()
        get_viewport().set_input_as_handled()
