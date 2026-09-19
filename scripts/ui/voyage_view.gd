class_name AstraVoyageView
extends Control

var app
var session: AstraGameSession
var _root: VBoxContainer
var _recorded := false
var _refresh_pending := false

func setup(app_node, game: AstraGameSession) -> void:
    app = app_node
    session = game
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    session.changed.connect(_queue_refresh)
    _draw()

func _queue_refresh() -> void:
    if _refresh_pending: return
    _refresh_pending = true
    _draw.call_deferred()

func _draw() -> void:
    _refresh_pending = false
    if not is_inside_tree(): return
    AstraUI.clear(self)
    var state := session.voyage
    var chapter := AstraVoyageContent.chapter(session.case_id)
    var room := str(state.get("room","medbay"))
    var background := AstraUI.thumb(AstraArt.room(room),Vector2.ZERO)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.modulate = Color(0.42,0.47,0.55)
    add_child(background)
    add_child(AstraArt.shade())
    _root = AstraUI.vbox(12)
    var margin := AstraUI.margin(_root,28,20,28,20)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(margin)
    var top := AstraUI.hbox(12)
    _root.add_child(top)
    top.add_child(AstraUI.label("A S T R A",24,AstraUI.TEXT))
    top.add_child(AstraUI.label(str(chapter["title"]),20,AstraUI.CYAN))
    top.add_child(AstraUI.spacer())
    if not state.get("notes",[]).is_empty():
        var notes := AstraUI.secondary_button("현재 상황 · 기록")
        notes.pressed.connect(_notes)
        top.add_child(notes)
    var menu := AstraUI.secondary_button("메뉴 · Esc")
    menu.pressed.connect(app.show_pause_menu)
    top.add_child(menu)
    if session.phase == "RESULT":
        _ending(chapter)
        return
    var calibration := session.case_id == "CALIBRATION"
    var goal := str(chapter["goal"])
    var met_count: int = state["met"].size()
    if calibration:
        # First playthrough: name the exact next click instead of restating
        # the chapter's whole premise (see the first-play redesign notes).
        if not bool(state.get("goal_done",false)):
            goal = "빛나는 조사 지점을 눌러 전원 문제를 확인하세요."
        elif met_count < session.roster.size():
            var next_person := ""
            for id in session.roster:
                if id not in state["met"]:
                    next_person = AstraCrewCatalog.name_ko(str(id))
                    break
            goal = "%s와 이야기해 보세요." % next_person if next_person != "" else "남은 동료와 이야기해 보세요."
        else:
            goal = "아래의 ‘기록을 함께 확인한다’를 눌러 마무리하세요."
    elif bool(state.get("goal_done",false)):
        var still_needed := ""
        for who in session.REQUIRED_PEOPLE.get(session.case_id, []):
            if str(who) not in state["met"]:
                still_needed = AstraCrewCatalog.name_ko(str(who))
                break
        if still_needed != "":
            goal = "%s와 이야기해 보세요." % still_needed
        elif session.REQUIRED_PEOPLE.has(session.case_id):
            goal = "확인한 기록을 함께 살핀다."
        else:
            goal = "깨어 있는 동료들과 만나 기록을 확인한다." if met_count < 4 else "확인한 기록을 함께 살핀다."
    var objective := AstraUI.panel(Color(0.025,0.065,0.10,0.96),Color(AstraUI.CYAN,0.5),10,12)
    objective.add_child(AstraUI.prose("지금 할 일   " + goal,AstraUI.T_BODY,AstraUI.TEXT))
    _root.add_child(objective)
    var routes := AstraUI.hbox(7)
    _root.add_child(routes)
    for id in session.voyage_rooms():
        var destination := str(id)
        var button := AstraUI.button(str(AstraVoyageContent.ROOMS[id]["name"]),AstraUI.CYAN if destination == room else AstraUI.MUTED,16,42,destination == room)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.disabled = not state["scene"].is_empty()
        button.pressed.connect(func(): session.voyage_move(destination))
        routes.add_child(button)
    var body := AstraUI.hbox(16)
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _root.add_child(body)
    var stage := Control.new()
    stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stage.clip_contents = true
    body.add_child(stage)
    var art := AstraUI.thumb(AstraArt.room(room),Vector2.ZERO)
    art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    stage.add_child(art)
    stage.add_child(AstraArt.shade())
    var scene: Dictionary = state.get("scene",{})
    if scene.is_empty():
        _hotspots(stage)
    else:
        var speaker := str(scene.get("speaker",""))
        var line_index := int(state.get("line",-1))
        if line_index >= 0 and line_index < scene.get("lines",[]).size():
            var line: Array = scene["lines"][line_index]
            if str(line[0]) != "": speaker = str(line[0])
        if speaker != "":
            var mood: String = {"danger":"afraid","trust":"smile","suspected":"suspicious","conflict":"annoyed","grief":"sad","relief":"happy","night":"tired"}.get(str(scene.get("tag","")),"neutral")
            var portrait := AstraUI.thumb(AstraCrewCatalog.cast_path(speaker,mood),Vector2.ZERO)
            portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
            portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            stage.add_child(portrait)
        if scene.has("target"):
            var other := AstraUI.thumb(AstraCrewCatalog.dot_path(str(scene["target"])),Vector2(90,90))
            other.position = Vector2(12,12)
            stage.add_child(other)
    var panel := AstraUI.reading_panel(AstraUI.CYAN,0.97)
    panel.custom_minimum_size.x = 480
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.size_flags_stretch_ratio = 0.82
    body.add_child(panel)
    var words := AstraUI.vbox(14)
    panel.add_child(AstraUI.scroll(words))
    if scene.is_empty():
        words.add_child(AstraUI.label(str(AstraVoyageContent.ROOMS[room]["name"]),28,AstraUI.TEXT))
        words.add_child(AstraUI.prose("주변을 살펴보거나 여기 있는 동료와 이야기할 수 있다.",18,AstraUI.MUTED))
        if "recorder" in state.get("inventory",[]) and "recorder" not in state.get("used_items",[]):
            var item := AstraUI.button("휴대 기록기로 신호를 보관한다",AstraUI.GOLD,17,42)
            item.disabled = room != "comms"
            item.tooltip_text = "통신실에서 사용할 수 있다."
            item.pressed.connect(session.voyage_use_recorder)
            words.add_child(item)
        for id in session.voyage_people():
            var who := str(id)
            var person := AstraUI.hbox(10)
            words.add_child(person)
            person.add_child(AstraUI.thumb(AstraCrewCatalog.dot_path(who),Vector2(64,64)))
            var talk := AstraUI.button(AstraCrewCatalog.labelled(who)+" · 대화",AstraUI.CYAN,18,52)
            talk.pressed.connect(func(): session.voyage_talk(who))
            person.add_child(talk)
            var ask := AstraUI.button("“지금 확인할 기록이 있어?”",AstraUI.MUTED,17,40)
            ask.pressed.connect(func(): session.voyage_ask_goal(who))
            words.add_child(ask)
            if int(state.get("loop",0)) > 0:
                var follow := AstraUI.button("여기서 헤어진다" if state["companion"] == who else "“같이 갈래?”",AstraUI.MUTED,16,36)
                follow.pressed.connect(func(): session.voyage_follow(who))
                words.add_child(follow)
                var memory := AstraUI.button("“어디로 가던 중이었어?”",AstraUI.MUTED,16,36)
                memory.pressed.connect(func(): session.voyage_memory_talk(who))
                words.add_child(memory)
        if session.voyage_people().is_empty():
            words.add_child(AstraUI.prose("지금은 아무도 없다. 조사 지점을 누르면 발견한 내용이 기록에 남는다.",18,AstraUI.MUTED))
    else:
        _dialogue(words,scene,state)
    var footer := AstraUI.hbox(8)
    _root.add_child(footer)
    var nudge_person := ""
    if calibration and bool(state.get("goal_done",false)):
        for id in session.roster:
            if str(id) not in state["met"]:
                nudge_person = str(id)
                break
    elif bool(state.get("goal_done",false)):
        for who in session.REQUIRED_PEOPLE.get(session.case_id, []):
            if str(who) not in state["met"]:
                nudge_person = str(who)
                break
    for id in session.roster:
        var who := str(id)
        var person := AstraUI.button(AstraCrewCatalog.labelled(who,true),AstraUI.CYAN if who in state["met"] else AstraUI.MUTED,15,50)
        person.icon = AstraUI.texture(AstraCrewCatalog.dot_path(who))
        person.expand_icon = true
        person.add_theme_constant_override("icon_max_width",44)
        person.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        person.tooltip_text = AstraCrewCatalog.labelled(who)+" · 있는 곳으로 이동"
        person.disabled = not scene.is_empty()
        person.pressed.connect(func(): session.voyage_visit_person(who))
        AstraUI.set_tutorial_nudge(person, who == nudge_person)
        footer.add_child(person)
    var bottom := AstraUI.hbox(12)
    _root.add_child(bottom)
    bottom.add_child(AstraUI.prose("탐사요원 · 깨어 있는 동료 %d명 · 수면 중 %d명" % [session.roster.size(),8-session.roster.size()],16,AstraUI.MUTED))
    bottom.add_child(AstraUI.spacer())
    if session.voyage_can_finish():
        var next := AstraUI.primary_button("기록을 함께 확인한다   →")
        next.pressed.connect(func():
            if session.finish_voyage() and session.phase != "RESULT": app.show_session_screen()
        )
        bottom.add_child(next)

func _hotspots(stage: Control) -> void:
    var calibration := session.case_id == "CALIBRATION"
    for point in session.voyage_points():
        var key := str(session.voyage["room"])+":"+str(point[0])
        var done: bool = key in session.voyage["inspected"]
        var button := AstraUI.button(("✓ " if done else "◉ ")+str(point[1]),AstraUI.MUTED if done else AstraUI.GOLD,16,42)
        button.anchor_left = float(point[2])
        button.anchor_top = float(point[3])
        button.offset_left = -80
        button.offset_right = 80
        button.disabled = done
        AstraUI.set_tutorial_nudge(button, calibration and not done)
        var point_id := str(point[0])
        button.pressed.connect(func(): session.voyage_inspect(point_id))
        stage.add_child(button)

func _dialogue(words: VBoxContainer, scene: Dictionary, state: Dictionary) -> void:
    var speaker := str(scene.get("speaker",""))
    var line_index := int(state["line"])
    var lines: Array = scene.get("lines",[])
    if line_index >= 0 and line_index < lines.size() and str(lines[line_index][0]) != "":
        speaker = str(lines[line_index][0])
    if speaker != "":
        words.add_child(AstraUI.label(AstraCrewCatalog.labelled(speaker),22,AstraCrewCatalog.accent(speaker)))
    words.add_child(AstraUI.prose(str(scene.get("action","")),18,AstraUI.MUTED))
    if line_index >= 0 and line_index < lines.size():
        words.add_child(AstraUI.prose(str(lines[line_index][1]),24,AstraUI.TEXT))
    words.add_child(AstraUI.spacer(false))
    var choices: Array = scene.get("choices",[])
    if line_index >= lines.size()-1 and not choices.is_empty():
        for i in range(choices.size()):
            var button := AstraUI.button(str(choices[i]["label"]),AstraUI.CYAN,18,44)
            button.pressed.connect(func(): session.voyage_choose(i))
            words.add_child(button)
    else:
        var next := AstraUI.primary_button("주변으로 돌아간다" if line_index >= lines.size()-1 else "계속   ›")
        next.pressed.connect(session.voyage_next)
        words.add_child(next)

func _notes() -> void:
    var box := AstraUI.vbox(12)
    for line in session.voyage_summary():
        box.add_child(AstraUI.prose("• "+str(line),18,AstraUI.TEXT))
    if int(session.voyage.get("loop",0)) > 0:
        box.add_child(AstraUI.label("지난번과 달라진 점",20,AstraUI.CYAN))
        for line in session.voyage.get("changes",[]):
            box.add_child(AstraUI.prose("• "+str(line),17,AstraUI.MUTED))
    AstraModal.open(app.overlay_root(),"현재 상황",AstraUI.scroll(box),[["닫기",AstraUI.CYAN]],Callable(),720.0)

func _ending(chapter: Dictionary) -> void:
    if not _recorded:
        _recorded = true
        app.record_result(session)
    _root.add_child(AstraUI.spacer(false))
    var panel := AstraUI.reading_panel(AstraUI.CYAN,0.97)
    _root.add_child(panel)
    var box := AstraUI.vbox(22)
    panel.add_child(box)
    var framing := AstraVoyageContent.reset_framing(session.case_id)
    box.add_child(AstraUI.label(str(framing["title"]),30,AstraUI.CYAN))
    box.add_child(AstraUI.prose(str(chapter["outro"]),24,AstraUI.TEXT))
    box.add_child(AstraUI.prose(str(framing["detail"]),20,AstraUI.MUTED))
    var next := AstraUI.primary_button("다시 눈을 뜬다   →")
    next.pressed.connect(func(): app.start_case(app.meta.recommended_case_id(),app.selected_protocol,app.active_slot))
    box.add_child(next)
    var title := AstraUI.secondary_button("제목으로")
    title.pressed.connect(app.show_title)
    box.add_child(title)
    _root.add_child(AstraUI.spacer(false))

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and not app.modal_open():
        if event.keycode == KEY_ESCAPE:
            app.show_pause_menu()
            get_viewport().set_input_as_handled()
        elif event.keycode in [KEY_SPACE,KEY_ENTER] and session.phase == "EXPLORE":
            session.voyage_next()
            get_viewport().set_input_as_handled()
