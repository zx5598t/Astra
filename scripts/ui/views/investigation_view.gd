extends VBoxContainer
var screen
var _rooms: HBoxContainer
var _stage: Control
var _latest: VBoxContainer
var _room_id := ""
var _last_clue_id := ""
func setup(game_screen) -> void:
    screen = game_screen
    add_theme_constant_override("separation",10)
    var session: AstraGameSession = screen.session
    _room_id = str(session.case_data["ops"][0]["room"])
    _rooms = AstraUI.hbox(8)
    add_child(_rooms)
    _stage = Control.new()
    _stage.custom_minimum_size.y = 255
    _stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _stage.clip_contents = true
    add_child(_stage)
    _latest = AstraUI.vbox(5)
    add_child(_latest)
    refresh()
func refresh() -> void:
    var session: AstraGameSession = screen.session
    AstraUI.clear(_rooms)
    var recommended: Array = session.recommended_rooms()
    for room in session.case_data["rooms"]:
        var id := str(room["id"])
        var status := session.room_status(id)
        var left := int(status.get("remaining", 0))
        # Rooms say how much is still there. 0.3.1 gave no way to tell a room you
        # had finished from one you had never opened, so people re-walked rooms
        # and ran out of time.
        var suffix := ""
        if left > 0:
            suffix = "   ●%d" % left
        elif int(status.get("found", 0)) > 0:
            suffix = "   ✓"
        var wanted: bool = id in recommended and left > 0
        var accent: Color = AstraUI.CYAN if id == _room_id else (AstraUI.GOLD if wanted else AstraUI.MUTED)
        var button := AstraUI.button(str(room["name"]) + suffix, accent, AstraUI.T_UI, 46, id == _room_id)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.tooltip_text = str(room.get("desc", ""))
        button.pressed.connect(func():
            _room_id = id
            screen.fx.play("select")
            refresh()
        )
        _rooms.add_child(button)
        # During calibration the recommended room is ringed, so a first-time
        # player does not spend the first minute hunting for where to click.
        if wanted and id != _room_id and session.tutorial_active():
            AstraUI.mark_as_target(button, AstraUI.GOLD, "")
    AstraUI.clear(_stage)
    var art := AstraUI.thumb(AstraArt.room(_room_id),Vector2.ZERO)
    art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _stage.add_child(art)
    _stage.add_child(AstraArt.shade())
    # Room name over its own dark plate, not straight onto the art: a bright
    # console behind white text made the caption unreadable in 0.3.1.
    var caption_card := AstraUI.panel(Color(0.016, 0.031, 0.062, 0.86), Color(AstraUI.CYAN, 0.35), 10, 12)
    caption_card.position = Vector2(18, 14)
    caption_card.custom_minimum_size.x = 300
    _stage.add_child(caption_card)
    var caption := AstraUI.vbox(2)
    caption_card.add_child(caption)
    caption.add_child(AstraUI.label(session.room_name(_room_id), AstraUI.T_TITLE, AstraUI.TEXT))
    caption.add_child(AstraUI.label("이동은 무료 · 조사 지점 1곳당 1 행동", AstraUI.T_META, AstraUI.MUTED))

    var points := session.investigation_points(_room_id)
    for i in range(points.size()):
        var point: Dictionary = points[i]
        var pos: Vector2 = point["position"]
        var searched: bool = bool(point["searched"])
        var available: bool = bool(point["available"])
        var box := AstraUI.vbox(2)
        box.anchor_left = pos.x
        box.anchor_top = pos.y
        box.offset_left = -95
        box.offset_top = -62
        box.offset_right = 95
        _stage.add_child(box)
        # A ring behind the icon so the hotspot reads as a hotspot rather than
        # as scenery. Unsearched points glow; finished ones go quiet.
        var badge := AstraUI.panel(
            Color(AstraUI.GOLD, 0.22) if available else Color(0.02, 0.04, 0.07, 0.7),
            AstraUI.GOLD if available else Color(AstraUI.DIM, 0.5), 999, 6)
        badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        box.add_child(badge)
        var icon := AstraArt.icon(str(point["icon"]), Vector2(52, 52))
        icon.modulate = Color.WHITE if available else Color(0.6, 0.64, 0.7)
        badge.add_child(icon)
        var label_text := str(point["label"])
        if searched:
            label_text = "✓  " + label_text
        elif available:
            label_text = "◉  " + label_text
        var button := AstraUI.button(label_text, AstraUI.GOLD if available else AstraUI.MUTED, AstraUI.T_UI, 44, available)
        button.tooltip_text = str(point["detail"])
        button.disabled = not available
        button.pressed.connect(_inspect.bind(str(point["id"])))
        box.add_child(button)
        if available and session.tutorial_active():
            AstraUI.mark_as_target(button, AstraUI.GOLD, "")
    AstraUI.clear(_latest)
    var clue := session.clue_by_id(_last_clue_id)
    if not clue.is_empty():
        var card := AstraClueCard.new()
        card.setup(session,clue,true)
        _latest.add_child(card)
    else:
        var intro := AstraUI.panel(Color(0.016, 0.031, 0.062, 0.9), Color(AstraUI.CYAN, 0.28), 10, 12)
        _latest.add_child(intro)
        var intro_box := AstraUI.vbox(4)
        intro.add_child(intro_box)
        intro_box.add_child(AstraUI.label("조사 지점", AstraUI.T_META, AstraUI.CYAN))
        var intro_text := AstraUI.rich_prose(AstraUI.T_BODY)
        intro_text.text = "[color=#ffd36a]◉[/color] 표시가 있는 곳이 아직 살펴보지 않은 지점입니다. 눌러서 기록을 확보하세요."
        intro_box.add_child(intro_text)
    var mission := session.mission_status()
    if str(mission.get("room","")) == _room_id and session.has_feature("night_tactics"):
        var row := AstraUI.hbox(10)
        _latest.add_child(row)
        row.add_child(AstraArt.icon("tools_02",Vector2(36,36)))
        row.add_child(AstraUI.label("선택 · " + str(mission.get("title","")),14,AstraUI.MUTED,true))
        var action := AstraUI.button("복구 완료" if bool(mission.get("complete",false)) else "설비 복구 · 1 행동",AstraUI.CYAN,14,36)
        action.disabled = not bool(mission.get("available",false))
        action.pressed.connect(_perform_mission)
        row.add_child(action)
func _inspect(point: String) -> void:
    var clue: Dictionary = screen.session.inspect_point(_room_id,point)
    _show_clue(clue)
func _show_clue(clue: Dictionary) -> void:
    if clue.is_empty():
        return
    _last_clue_id = str(clue["id"])
    screen.fx.play("clue")
    refresh()
func _search(room_id: String) -> void:
    _room_id = room_id
    _show_clue(screen.session.search_room(room_id))
func _perform_mission() -> void:
    var result: Dictionary = screen.session.perform_mission()
    if bool(result.get("ok",false)):
        screen.fx.play("clue")
        screen.fx.toast("설비가 다시 작동하기 시작했다.",AstraUI.GREEN)
