class_name AstraInterludeView
extends Control

# A short playable scene (§9-§16, §58-§63): walk a small room, go up to
# people, look at one or two things, do one small task with someone, and
# walk back into the Day with what it left. Movement: WASD / arrow keys, or
# click the floor; click a person or a thing to walk over and talk. E, Space
# or Enter talks / advances. Nothing here is timed.
#
# The people are not statues: they breathe, get on with their work, notice you
# when you come close (and go back to it when you leave), nod while they talk,
# react when a task works out, and watch you go at the end.

signal done(result: String)

const SPEED := 230.0
const REACH := 100.0

var session: AstraGameSession
var interlude_id: String = ""
var data: Dictionary = {}
var room: AstraDeckRoom
var player: AstraPixelActor
var actors: Dictionary = {}
var _stage: Control
var _dialog: PanelContainer
var _dialog_face: TextureRect
var _dialog_name: Label
var _dialog_text: Label
var _prompt: Label
var _hint: Label
var _skip: Button
var _task: Control
var _lines: Array = []
var _after_lines: Callable = Callable()
var _walk_to: Vector2 = Vector2.INF
var _walk_target: String = ""
var _near: String = ""
var _result: String = ""
var _closing: bool = false
var _talked: Dictionary = {}
var _talk_actor: String = ""
var _task_helper: String = ""
var _idle_time: float = 0.0
var _exiting: bool = false
var _exit_left: float = 0.0
var _exit_result: String = ""
var _can_stand: Callable

func setup(game_session: AstraGameSession, id: String, player_preset: String) -> void:
    session = game_session
    interlude_id = id
    data = AstraInterludes.data(id)
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var bg := ColorRect.new()
    bg.color = Color("05090f")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    _stage = Control.new()
    _stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _stage.offset_top = 52
    _stage.offset_bottom = -12
    _stage.clip_contents = true
    _stage.mouse_filter = Control.MOUSE_FILTER_STOP
    _stage.gui_input.connect(_on_stage_input)
    _stage.resized.connect(_fit_room)
    add_child(_stage)
    room = AstraDeckRoom.new()
    room.setup(data)
    _stage.add_child(room)
    for entry in data.get("actors", []):
        var npc_id := str(entry.get("id", ""))
        var actor := AstraPixelActor.new()
        actor.setup(AstraPixelActor.crew_sheet(npc_id), npc_id, session.name_of(npc_id), AstraCrewCatalog.accent(npc_id))
        actor.position = room.tile_to_px(entry.get("at", [1, 1]))
        actor.facing = str(entry.get("facing", "down"))
        actor.face(actor.facing)
        actor.home_facing = actor.facing
        actor.home = actor.position
        actor.style = str(entry.get("idle", "watch"))
        actor.seated = actor.style == "sit"
        actor.working = actor.style == "work"
        var pace: Array = entry.get("pace", [0, 0])
        actor.pace_offset = Vector2(float(pace[0]), float(pace[1])) * AstraInterludes.TILE
        room.add_child(actor)
        actors[npc_id] = actor
    _can_stand = func(point: Vector2) -> bool: return not room.blocked(point)
    player = AstraPixelActor.new()
    var preset := player_preset if ResourceLoader.exists(AstraPixelActor.player_sheet(player_preset)) else "p1"
    player.setup(AstraPixelActor.player_sheet(preset), "player", "나", AstraUI.GOLD)
    player.position = room.tile_to_px(data.get("spawn", [7.5, 8.0]))
    player.face("up")
    room.add_child(player)

    var top := AstraUI.hbox(12)
    top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    top.offset_left = 18
    top.offset_right = -14
    top.offset_top = 8
    top.offset_bottom = 48
    add_child(top)
    top.add_child(AstraUI.label(str(data.get("caption", "")), AstraUI.T_UI, AstraUI.MUTED))
    _hint = AstraUI.label("이동 WASD·방향키·클릭  ·  말 걸기 E / Space / 클릭", AstraUI.T_META, AstraUI.DIM)
    _hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    top.add_child(_hint)
    _skip = AstraUI.button("이 장면 건너뛰기  ▸▸", AstraUI.MUTED, AstraUI.T_META, 36)
    _skip.tooltip_text = "걷기 장면을 건너뜁니다. 이 장면에서 얻을 수 있던 것은 대화에서 다시 들을 수 있습니다."
    _skip.pressed.connect(func(): _close("skipped"))
    top.add_child(_skip)

    _prompt = AstraUI.label("", AstraUI.T_UI, AstraUI.GOLD)
    _prompt.visible = false
    _prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_prompt)

    _dialog = AstraUI.reading_panel(AstraUI.CYAN, 0.95)
    _dialog.anchor_left = 0.12
    _dialog.anchor_right = 0.88
    _dialog.anchor_top = 1.0
    _dialog.anchor_bottom = 1.0
    _dialog.offset_top = -170
    _dialog.offset_bottom = -22
    _dialog.mouse_filter = Control.MOUSE_FILTER_STOP
    _dialog.gui_input.connect(func(event: InputEvent):
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _advance_lines()
    )
    add_child(_dialog)
    var row := AstraUI.hbox(14)
    _dialog.add_child(row)
    _dialog_face = TextureRect.new()
    _dialog_face.custom_minimum_size = Vector2(96, 110)
    _dialog_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _dialog_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    _dialog_face.material = AstraUI.defringe_material()
    row.add_child(_dialog_face)
    var col := AstraUI.vbox(4)
    col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(col)
    _dialog_name = AstraUI.label("", AstraUI.T_HEAD, AstraUI.CYAN)
    col.add_child(_dialog_name)
    _dialog_text = AstraUI.prose("", AstraUI.T_BODY, AstraUI.TEXT)
    col.add_child(_dialog_text)
    _dialog.visible = false
    _fit_room.call_deferred()
    # The scene opens on one line, then the room is yours.
    _say([["", "%s. 누구에게 먼저 다가갈지는 당신이 정한다." % str(data.get("title", ""))]], func(): player.look_around())

func _fit_room() -> void:
    if room == null or _stage == null:
        return
    var room_size := room.room_px()
    var avail := _stage.size - Vector2(0, 150)
    if avail.x <= 0 or avail.y <= 0:
        return
    var s := minf(avail.x / room_size.x, avail.y / room_size.y)
    room.scale = Vector2(s, s)
    room.position = Vector2((_stage.size.x - room_size.x * s) * 0.5, maxf(0.0, (avail.y - room_size.y * s) * 0.5))

# ---------------------------------------------------------------- dialogue

func _say(lines: Array, after: Callable = Callable()) -> void:
    _lines = []
    for line in lines:
        _lines.append([str(line[0]), session._fill_story(str(line[1])), str(line[2]) if line.size() > 2 else ""])
    _after_lines = after
    _show_line()

func _show_line() -> void:
    if _lines.is_empty():
        _dialog.visible = false
        for id in actors:
            actors[id].talking = false
        player.working = false
        var next := _after_lines
        _after_lines = Callable()
        if next.is_valid():
            next.call()
        return
    var line: Array = _lines[0]
    var speaker := str(line[0])
    _dialog.visible = true
    for id in actors:
        actors[id].talking = id == speaker
    if session.crew.has(speaker):
        _dialog_face.texture = AstraUI.texture(AstraCrewCatalog.portrait_path(speaker, "neutral"))
        _dialog_face.visible = _dialog_face.texture != null
        _dialog_name.text = session.name_of(speaker)
        _dialog_name.add_theme_color_override("font_color", AstraCrewCatalog.accent(speaker))
        if actors.has(speaker):
            actors[speaker].look_at_point(player.position)
            if not player.working:
                player.look_at_point(actors[speaker].position)
            _play_cue(actors[speaker], _line_cue(speaker, str(line[1]), str(line[2])))
    else:
        _dialog_face.visible = false
        _dialog_name.text = ""
    _dialog_text.text = str(line[1])

func _advance_lines() -> void:
    if _lines.is_empty():
        return
    _lines.pop_front()
    _show_line()

# What a line does to the person saying it. Explicit cues in the data win;
# otherwise the line itself hints (a trailing-off "…", a question, a "!"),
# and some lines just get a nod. Stable per line, not random per viewing.
func _line_cue(speaker: String, text: String, given: String) -> String:
    if given != "":
        return given
    if not actors.has(speaker):
        return ""
    var plain := text.strip_edges()
    var roll := absi(hash(plain)) % 10
    if plain.begins_with("…"):
        return "…" if roll < 7 else "sigh"
    if plain.ends_with("!"):
        return "!"
    if plain.ends_with("?"):
        return "?" if roll < 5 else "tilt"
    if roll < 3:
        return "nod"
    return ""

func _play_cue(actor: AstraPixelActor, cue: String) -> void:
    match cue:
        "", "none":
            return
        "!":
            actor.emote("!", 1.2)
            actor.gesture("startle")
        "?":
            actor.emote("?", 1.4)
            actor.gesture("tilt")
        "…":
            actor.emote("…", 1.6)
        "♪":
            actor.emote("♪", 1.5)
            actor.gesture("hop")
        "sweat":
            actor.emote("sweat", 1.8)
            actor.gesture("shiver")
        _:
            actor.gesture(cue)

func consume_advance() -> bool:
    if _exiting or _closing:
        return true
    if _task != null and is_instance_valid(_task) and _task.visible:
        return _task.consume_advance()
    if _dialog.visible:
        _advance_lines()
        return true
    if _near != "":
        _interact(_near)
        return true
    return false

# ---------------------------------------------------------------- movement

func _process(delta: float) -> void:
    if room == null:
        return
    if _exiting:
        _exit_step(delta)
        return
    if _closing:
        return
    var busy := _dialog.visible or (_task != null and is_instance_valid(_task))
    var dir := Vector2.ZERO
    if not busy:
        if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
            dir.x -= 1.0
        if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
            dir.x += 1.0
        if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
            dir.y -= 1.0
        if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
            dir.y += 1.0
    if dir != Vector2.ZERO:
        _walk_to = Vector2.INF
        _walk_target = ""
    elif _walk_to != Vector2.INF and not busy:
        var to := _walk_to - player.position
        if to.length() < 6.0:
            _walk_to = Vector2.INF
            if _walk_target != "":
                var target := _walk_target
                _walk_target = ""
                _interact(target)
        else:
            dir = to.normalized()
    if dir != Vector2.ZERO:
        dir = dir.normalized()
        var step := dir * SPEED * delta
        var moved := false
        for axis in [Vector2(step.x, 0), Vector2(0, step.y)]:
            if axis == Vector2.ZERO:
                continue
            var next: Vector2 = player.position + axis
            if not room.blocked(next) and not _hits_actor(next):
                player.position = next
                moved = true
        if absf(dir.x) > absf(dir.y):
            player.face("right" if dir.x > 0 else "left")
        else:
            player.face("down" if dir.y > 0 else "up")
        player.set_moving(moved)
        if not moved and _walk_target != "":
            # blocked on the way: talk from here if close enough
            var target := _walk_target
            _walk_to = Vector2.INF
            _walk_target = ""
            if _distance_to(target) <= REACH * 1.6:
                _interact(target)
    else:
        player.set_moving(false)
    _update_near()
    _animate_people(delta, busy)

# Everyone else lives on while you walk around; you look around when idle.
func _animate_people(delta: float, busy: bool) -> void:
    var task_open := _task != null and is_instance_valid(_task)
    for id in actors:
        var engaged: bool = (_dialog.visible and (id == _talk_actor or actors[id].talking)) or (id == _task_helper and task_open)
        actors[id].think(delta, player.position, engaged, _can_stand)
    if busy or player.moving:
        _idle_time = 0.0
    else:
        _idle_time += delta
        if _idle_time > 6.5:
            _idle_time = -4.0
            player.look_around()

func _hits_actor(point: Vector2) -> bool:
    for id in actors:
        if (actors[id].position - point).length() < 40.0:
            return true
    return false

func _target_pos(target_id: String) -> Vector2:
    for target in data.get("targets", []):
        if str(target.get("id", "")) != target_id:
            continue
        if actors.has(str(target.get("actor", ""))):
            return actors[str(target.get("actor", ""))].position
        var prop := room.prop_by_id(str(target.get("prop", "")))
        if not prop.is_empty():
            var r := room.prop_rect(prop)
            return Vector2(r.get_center().x, r.end.y + 20.0)
    return Vector2.INF

func _distance_to(target_id: String) -> float:
    var p := _target_pos(target_id)
    return (p - player.position).length() if p != Vector2.INF else INF

func _update_near() -> void:
    var best := ""
    var best_d := REACH
    for target in data.get("targets", []):
        var d := _distance_to(str(target.get("id", "")))
        if d < best_d:
            best_d = d
            best = str(target.get("id", ""))
    if best != _near:
        _near = best
        for id in actors:
            actors[id].highlight = false
        if _near != "":
            var target := _target(_near)
            if actors.has(str(target.get("actor", ""))):
                actors[str(target.get("actor", ""))].highlight = true
    var show := _near != "" and not _dialog.visible and (_task == null or not is_instance_valid(_task))
    _prompt.visible = show
    if show:
        var target := _target(_near)
        var verb := "살펴보기" if str(target.get("prop", "")) != "" else "말 걸기"
        _prompt.text = "E  %s · %s" % [verb, str(target.get("label", ""))]
        var world := _target_pos(_near) + Vector2(0, -150 if str(target.get("actor", "")) != "" else -40)
        var beside := world.y < 12.0
        if beside:
            # no room above (someone by the top wall): beside their head
            world = _target_pos(_near) + Vector2(46, -84)
        var screen_pos := room.get_global_transform() * world
        _prompt.position = screen_pos - get_global_rect().position - (Vector2.ZERO if beside else Vector2(_prompt.size.x * 0.5, 0))
        # people by the top wall: keep the prompt under the top bar
        _prompt.position.y = maxf(_prompt.position.y, 56.0)

func _target(target_id: String) -> Dictionary:
    for target in data.get("targets", []):
        if str(target.get("id", "")) == target_id:
            return target
    return {}

func _on_stage_input(event: InputEvent) -> void:
    if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
        return
    if _closing:
        return
    if _dialog.visible:
        _advance_lines()
        return
    var local: Vector2 = room.get_global_transform().affine_inverse() * event.global_position
    # a person or a thing under the cursor: walk over and talk
    for target in data.get("targets", []):
        var p := _target_pos(str(target.get("id", "")))
        var hit := Rect2(p - Vector2(40, 130), Vector2(80, 140)) if str(target.get("actor", "")) != "" else Rect2(p - Vector2(50, 70), Vector2(100, 80))
        if hit.has_point(local):
            if _distance_to(str(target.get("id", ""))) <= REACH:
                _interact(str(target.get("id", "")))
            else:
                _walk_to = p + (player.position - p).normalized() * 60.0
                _walk_target = str(target.get("id", ""))
            return
    _walk_to = local
    _walk_target = ""

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        if _closing:
            get_viewport().set_input_as_handled()
            return
        if _dialog.visible:
            _advance_lines()
        elif _near != "":
            _interact(_near)
        get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- story

func _interact(target_id: String) -> void:
    if _closing or _dialog.visible:
        return
    var target := _target(target_id)
    if target.is_empty():
        return
    if actors.has(str(target.get("actor", ""))):
        player.look_at_point(actors[str(target.get("actor", ""))].position)
        _talk_actor = str(target.get("actor", ""))
    else:
        _talk_actor = ""
        # a thing: turn to it and bend over it while the lines run
        var prop := room.prop_by_id(str(target.get("prop", "")))
        if not prop.is_empty():
            player.look_at_point(room.prop_rect(prop).get_center())
            player.working = true
    var task := str(target.get("task", ""))
    if task != "" and _result == "":
        _say(target.get("lines", []), func(): _open_task(task))
        return
    if task != "" and _result != "":
        _say([[str(target.get("actor", "")), "…이제 사람들한테 가 봐요. 저도 곧 갈게요."]], func(): _close(_result))
        return
    _talked[target_id] = true
    # Some scenes end on what you choose to look at (the documents, the one
    # alarm you see with your own eyes); the others are there to be noticed.
    var complete := str(target.get("complete", ""))
    if complete != "" and _result == "":
        _say(target.get("lines", []), func(): _finish_task(complete))
        return
    _say(target.get("lines", []))

func _open_task(kind: String) -> void:
    var task: Dictionary = data.get("task", {})
    var helper := ""
    for target in data.get("targets", []):
        if str(target.get("task", "")) == kind:
            helper = str(target.get("actor", ""))
    # Both of you get to work: the helper at their own station.
    _task_helper = helper
    player.working = true
    if actors.has(helper):
        var who: AstraPixelActor = actors[helper]
        who.talking = false
        if who.style == "work":
            who.face(who.home_facing)
        who.working = true
    match kind:
        "signal_trace":
            var trace := AstraSignalTrace.new()
            add_child(trace)
            trace.setup(session.seed_value, task.get("pieces", []), float(task.get("tolerance", 0.045)), session.name_of(helper))
            trace.finished.connect(_finish_task)
            _task = trace
        "power_route":
            var route := AstraPowerRoute.new()
            add_child(route)
            route.setup(session.seed_value, session.name_of(helper))
            route.finished.connect(_finish_task)
            _task = route
        "order":
            var order := AstraOrderTask.new()
            add_child(order)
            order.setup(session.seed_value, task, session.name_of(helper))
            order.finished.connect(_finish_task)
            _task = order
        _:
            _finish_task("partial")

func _finish_task(result: String) -> void:
    if _task != null and is_instance_valid(_task):
        _task.queue_free()
    _task = null
    _result = result
    _react(result)
    var key := "success" if result.begins_with("choice:") else result
    var outcome: Dictionary = Dictionary(data.get("results", {})).get(key, {})
    _say(outcome.get("lines", []), func(): _close(result))

# A task that works out gets a jump and a note from whoever helped; a partial
# one a sigh and a nod. Seeing it with your own eyes (a thing, a choice) makes
# the room look at you.
func _react(result: String) -> void:
    var helper := _task_helper
    _task_helper = ""
    player.working = false
    if actors.has(helper):
        actors[helper].working = false
    if result == "partial":
        player.emote("…", 1.6, true)
        player.gesture("sigh", true)
        if actors.has(helper):
            actors[helper].gesture("nod", true)
        return
    player.emote("!", 1.3, true)
    player.gesture("hop", true)
    if actors.has(helper):
        actors[helper].look_at_point(player.position)
        actors[helper].emote("♪", 1.6, true)
        actors[helper].gesture("joy", true)
        return
    for id in actors:
        if actors[id].position.distance_to(player.position) < 420.0:
            actors[id].glance(player.position, 1.6)

func _close(result: String) -> void:
    if _closing:
        return
    if result == "skipped" and _result == "":
        _result = "skipped"
    _closing = true
    var final := _result if _result != "" else result
    if result == "skipped" or AstraUI.reduce_motion or not is_inside_tree():
        done.emit(final)
        return
    # A few steps toward the door while the room watches you go.
    _exiting = true
    _exit_left = 0.8
    _exit_result = final
    _prompt.visible = false
    player.working = false
    for id in actors:
        actors[id].talking = false
        actors[id].glance(player.position, 2.0)
    var fade := create_tween()
    fade.tween_interval(0.45)
    fade.tween_property(self, "modulate:a", 0.0, 0.35)

func _exit_step(delta: float) -> void:
    _exit_left -= delta
    var to := room.door_rect().get_center() - player.position
    if to.length() > 8.0:
        var dir := to.normalized()
        var next := player.position + dir * SPEED * 0.8 * delta
        if not room.blocked(next):
            player.position = next
        if absf(dir.x) > absf(dir.y):
            player.face("right" if dir.x > 0 else "left")
        else:
            player.face("down" if dir.y > 0 else "up")
        player.set_moving(true)
    else:
        player.set_moving(false)
    if _exit_left <= 0.0:
        _exiting = false
        done.emit(_exit_result)
