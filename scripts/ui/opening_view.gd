class_name AstraOpeningView
extends Control

# The first sixty seconds.
#
# 0.3.1 opened on a menu and explained the premise inside a modal the player had
# to dismiss before anything happened. The words "Null", "재구성" and "프로토콜"
# all appeared before a single button had been pressed.
#
# This version answers the four questions a new player actually has, in order,
# and stops:
#
#   무슨 일이 있었지?   — a research ship went silent with eight people aboard
#   나는 누구지?        — you reconstruct what the damaged recorder still holds
#   왜 조사하지?        — some of them were acting on a hidden order, and killed
#   누구를 찾지?        — the game calls those people Null
#
# Every beat waits for a click. There is no timer to lose a line to, the skip
# button is on screen from the first frame, and every line of text sits inside
# an opaque panel instead of being painted straight onto the art, because light
# text over a bright hull is text nobody can read.

signal finished

# `art` picks the backdrop; `who` set means the line is spoken by a person.
const BEATS := [
    {"art":"wake", "system":"ASTRA · 의료실", "text":"손목을 잡은 손이 따뜻하다.\n천장에는 느리게 깜빡이는 등이 하나 있다."},
    {"art":"wake", "who":"mira", "text":"들리나요? 천천히 눈 떠요.\n탐사팀 명부에 이름이 있었어요. 당신 맞죠?"},
    {"art":"wake", "who":"rho", "text":"미라, 문 열려? 잠깐만. 이쪽 전원부터 살려 볼게."},
    {"art":"wake", "who":"noa", "text":"당신까지 다섯 명. 나머지 포드 네 개는 아직 닫혀 있어요."},
    {"art":"wake", "who":"dax", "text":"돌아가던 중이라고? 나는 탐사 임무로 왔는데."},
    {"art":"wake", "system":"수신 기록", "text":"목적지: 지구.\n바로 아래, 같은 날짜의 명령서에는 다른 이름이 적혀 있다."}
]
const ART := {"wake":"res://assets/art031/backgrounds/medical.webp"}

var _app
var _index: int = -1
var _backdrop: TextureRect
var _scrim: ColorRect
var _panel_holder: Control
var _skip: Button
var _progress: Label
var _done: bool = false
var _current_art: String = ""

func setup(app_node) -> void:
    _app = app_node
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP

    var bg := ColorRect.new()
    bg.color = Color(0.008, 0.012, 0.026, 1.0)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)

    _backdrop = TextureRect.new()
    _backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    _backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_backdrop)

    # A flat scrim over the whole frame plus the gradient from the art module.
    # Without it the white hull and the white text land on top of each other.
    _scrim = ColorRect.new()
    _scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _scrim.color = Color(0.01, 0.02, 0.05, 0.42)
    _scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_scrim)
    add_child(AstraArt.shade())

    # The text always lives in the same place, in a box of the same size, so the
    # eye never has to search for where the line went.
    _panel_holder = Control.new()
    _panel_holder.anchor_left = 0.0
    _panel_holder.anchor_right = 1.0
    _panel_holder.anchor_top = 1.0
    _panel_holder.anchor_bottom = 1.0
    _panel_holder.offset_left = 90.0
    _panel_holder.offset_right = -90.0
    _panel_holder.offset_top = -250.0
    _panel_holder.offset_bottom = -80.0
    _panel_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_panel_holder)

    _skip = AstraUI.secondary_button("건너뛰기", AstraUI.MUTED)
    _skip.anchor_left = 1.0
    _skip.anchor_right = 1.0
    _skip.offset_left = -152.0
    _skip.offset_right = -28.0
    _skip.offset_top = 24.0
    _skip.offset_bottom = 64.0
    _skip.pressed.connect(_finish)
    add_child(_skip)

    _progress = AstraUI.label("", AstraUI.T_META, AstraUI.DIM)
    _progress.anchor_top = 1.0
    _progress.anchor_bottom = 1.0
    _progress.anchor_left = 0.5
    _progress.anchor_right = 0.5
    _progress.offset_left = -200.0
    _progress.offset_right = 200.0
    _progress.offset_top = -58.0
    _progress.offset_bottom = -30.0
    _progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(_progress)

    _advance()

func _advance() -> void:
    if _done:
        return
    _index += 1
    if _index >= BEATS.size():
        _finish()
        return
    var beat: Dictionary = BEATS[_index]
    var art_key := str(beat.get("art", "ship"))
    if art_key != _current_art:
        _current_art = art_key
        _backdrop.texture = AstraUI.texture(str(ART.get(art_key, "")))
        if not AstraUI.reduce_motion:
            AstraUI.fade_in(_backdrop, 0.3)
    AstraUI.clear(_panel_holder)
    var card := _build_card(beat)
    card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _panel_holder.add_child(card)
    if not AstraUI.reduce_motion:
        AstraUI.fade_in(card, 0.18)
    _progress.text = "클릭하거나 아무 키나 누르세요      %d / %d" % [_index + 1, BEATS.size()]
    _play(beat)

func _build_card(beat: Dictionary) -> Control:
    var who := str(beat.get("who", ""))
    if who != "" and AstraCrewCatalog.CREW.has(who):
        var member_card := AstraUI.dialogue_box(who, AstraCrewCatalog.display_name(who), str(beat.get("text", "")), AstraCrewCatalog.accent(who))
        return member_card
    var card := AstraUI.reading_panel(AstraUI.CYAN)
    var box := AstraUI.vbox(8)
    card.add_child(box)
    if who != "":
        var head := AstraUI.hbox(8)
        box.add_child(head)
        head.add_child(AstraUI.label(who, AstraUI.T_HEAD, AstraUI.MUTED))
        head.add_child(AstraUI.chip("복원된 음성", AstraUI.CYAN, AstraUI.T_META - 2))
    elif str(beat.get("system", "")) != "":
        box.add_child(AstraUI.label(str(beat["system"]), AstraUI.T_META, AstraUI.CYAN))
    var body := AstraUI.rich_prose(AstraUI.T_HEAD if who != "" else AstraUI.T_BODY)
    body.text = str(beat.get("text", ""))
    box.add_child(body)
    return card

func _play(beat: Dictionary) -> void:
    if _app == null or _app.fx == null:
        return
    if str(beat.get("who", "")) != "":
        _app.fx.play("talk")
    elif str(beat.get("art", "")) == "faces":
        _app.fx.play("slip")
    else:
        _app.fx.play("phase")

func _finish() -> void:
    if _done:
        return
    _done = true
    finished.emit()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        accept_event()
        _advance()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            _finish()
        else:
            _advance()
        get_viewport().set_input_as_handled()
