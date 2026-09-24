class_name AstraPixelActor
extends Node2D

# A walking chibi in the deck interludes. Portraits carry feeling in the
# conversation screens; these carry space and movement (§8). Sheets come from
# tools/import_pixel_080.gd: 96x128 frames, 3 per direction, rows down / up /
# left / right, feet at the bottom centre. Nearest filtering, no smoothing.
#
# The sheets draw walking only. Everything else a person does in a room —
# breathing, nodding while they talk, bending over a console, a start of
# surprise, a head shake, sitting behind a table — is made from those same
# frames by moving whole-pixel bands of the body in MOTION_SHADER: the head
# (and hair) above the neck row, the upper body above the waist row, the legs
# planted. Nothing is redrawn or stretched. When an action sheet exists
# (<sheet>_action.png, layout in docs/PIXEL_ACTIONS_080.md), its drawn poses take
# over from the made-up ones for working, talking, sitting and reacting.

const FRAME := Vector2i(96, 128)
const DIRECTIONS := ["down", "up", "left", "right"]
const WALK_FPS := 7.0
# Every sheet is normalised to feet on row 126 and a median height of 112, so
# a waist row fits everyone. The neck row sits two rows under the chin of the
# front frame (a split through a face would show); side frames stand ~4 rows
# lower. A new sheet without an entry uses DEFAULT_NECK.
const WAIST_ROW := 88
const SIDE_ROWS := 4
const DEFAULT_NECK := 70
const NECK_ROWS := {"mira": 69, "rho": 69, "eli": 71, "sena": 70, "vale": 71, "noa": 70, "lyra": 70, "dax": 68,
    "p1": 72, "p2": 72, "p3": 74, "p4": 70, "p5": 72, "p6": 72}
# Sitting behind a table: the table in front hides the legs.
const SIT_DROP := 24
const SIT_DROP_DRAWN := 8
const NOTICE_RANGE := 170.0
const PACE_SPEED := 58.0

const MOTION_SHADER := """
shader_type canvas_item;
uniform vec2 head_off = vec2(0.0);
uniform vec2 body_off = vec2(0.0);
uniform float neck_row = 70.0;
uniform float waist_row = 88.0;
uniform vec2 frame_px = vec2(96.0, 128.0);
varying vec4 tint;
void vertex() {
    tint = COLOR;
}
void fragment() {
    // The band a pixel lands in decides how far it moved, so a band that
    // moves up leaves no gap and one that moves down covers one row.
    vec2 px = floor(UV / TEXTURE_PIXEL_SIZE);
    vec2 local = mod(px, frame_px);
    vec2 origin = px - local;
    vec2 off = local.y < neck_row ? head_off : (local.y < waist_row ? body_off : vec2(0.0));
    vec2 src = local - off;
    vec4 c = vec4(0.0);
    if (src.x >= 0.0 && src.y >= 0.0 && src.x < frame_px.x && src.y < frame_px.y) {
        c = texture(TEXTURE, (origin + src + 0.5) * TEXTURE_PIXEL_SIZE);
    }
    COLOR = c * tint;
}
"""

# Gesture tracks, one step per row:
#   [seconds, head x, head y, body x, body y, hop px, walk frame (-1 = stand)]
# x values are mirrored at random per gesture, so a tilt goes either way.
const GESTURES := {
    "nod": [[0.07, 0, 1, 0, 0, 0, -1], [0.16, 0, 3, 0, 1, 0, -1], [0.08, 0, 1, 0, 0, 0, -1]],
    "nod2": [[0.07, 0, 1, 0, 0, 0, -1], [0.13, 0, 3, 0, 1, 0, -1], [0.08, 0, 0, 0, 0, 0, -1],
        [0.07, 0, 1, 0, 0, 0, -1], [0.13, 0, 3, 0, 1, 0, -1], [0.08, 0, 1, 0, 0, 0, -1]],
    "shake": [[0.07, -2, 0, 0, 0, 0, -1], [0.07, 2, 0, 0, 0, 0, -1], [0.07, -2, 0, 0, 0, 0, -1],
        [0.07, 2, 0, 0, 0, 0, -1], [0.05, 0, 0, 0, 0, 0, -1]],
    "bow": [[0.07, 0, 2, 0, 1, 0, -1], [0.07, 0, 4, 0, 2, 0, -1], [0.5, 0, 5, 0, 2, 0, -1],
        [0.08, 0, 3, 0, 1, 0, -1], [0.08, 0, 1, 0, 0, 0, -1]],
    "hop": [[0.05, 0, 2, 0, 1, 0, -1], [0.05, 0, -1, 0, 0, 4, -1], [0.08, 0, -1, 0, 0, 8, -1],
        [0.05, 0, 0, 0, 0, 4, -1], [0.07, 0, 2, 0, 1, 0, -1]],
    "joy": [[0.05, 0, 2, 0, 1, 0, -1], [0.05, 0, -1, 0, 0, 4, -1], [0.07, 0, -1, 0, 0, 7, -1],
        [0.05, 0, 0, 0, 0, 3, -1], [0.06, 0, 2, 0, 1, 0, -1], [0.05, 0, -1, 0, 0, 4, -1],
        [0.07, 0, -1, 0, 0, 7, -1], [0.05, 0, 0, 0, 0, 3, -1], [0.07, 0, 2, 0, 1, 0, -1]],
    "startle": [[0.05, 0, -2, 0, -1, 3, -1], [0.1, 0, -2, 0, -1, 5, -1], [0.06, 0, 0, 0, 0, 2, -1],
        [0.12, 0, 2, 0, 1, 0, -1]],
    "tilt": [[0.06, 1, 0, 0, 0, 0, -1], [0.8, 2, 1, 0, 0, 0, -1], [0.06, 1, 0, 0, 0, 0, -1]],
    "sigh": [[0.22, 0, -1, 0, 0, 0, -1], [0.12, 0, 1, 0, 0, 0, -1], [0.9, 0, 3, 0, 1, 0, -1],
        [0.15, 0, 1, 0, 0, 0, -1]],
    "shiver": [[0.05, 1, 0, 1, 0, 0, -1], [0.05, -1, 0, 0, 0, 0, -1], [0.05, 1, 0, 1, 0, 0, -1],
        [0.05, -1, 0, 0, 0, 0, -1], [0.05, 1, 0, 1, 0, 0, -1], [0.05, -1, 0, 0, 0, 0, -1],
        [0.05, 1, 0, 1, 0, 0, -1], [0.05, 0, 0, 0, 0, 0, -1]],
    # weight moves to one foot and back
    "shift": [[0.2, 0, 0, 0, 0, 0, 0], [0.12, 0, 1, 0, 1, 0, -1]],
}
# Drawn reaction frames (action sheet, row 4, facing down) for some gestures.
const GESTURE_DRAWN := {"startle": 0, "hop": 0, "joy": 0, "nod": 1, "nod2": 1, "bow": 1, "sigh": 2}

const EMOTE_GLYPHS := {
    "!": [".###.", ".###.", ".###.", ".###.", "..#..", ".....", ".###."],
    "?": [".###.", "#...#", "....#", "..##.", "..#..", ".....", "..#.."],
    "…": [".....", ".....", ".....", "#.#.#", ".....", ".....", "....."],
    "♪": ["..###", "..#.#", "..#..", "..#..", "###..", "###..", "....."],
    "sweat": ["..#..", ".###.", "#####", "#####", ".###."],
}
const EMOTE_COLORS := {"!": Color("e2574c"), "?": Color("3a9ad9"), "…": Color("56657a"), "♪": Color("2b9d62"), "sweat": Color("78c4ff")}
const EMOTE_DOT := 4.0

static var _shader: Shader

var actor_id: String = ""
var display_name: String = ""
var accent: Color = Color.WHITE
var facing: String = "down"
# Where they turn back to when nobody needs them (their work, the door).
var home_facing: String = "down"
# Idle life in a room: watch | work | sit | alert | pace.
var style: String = "watch"
var home: Vector2 = Vector2.INF
var pace_offset: Vector2 = Vector2.ZERO
var social: float = 0.5
var calm: float = 0.7
var moving: bool = false
var highlight: bool = false:
    set(value):
        highlight = value
        queue_redraw()
# A line of theirs is on screen.
var talking: bool = false:
    set(value):
        if talking != value:
            talking = value
            _apply_animation()
# Hands on something: a console, a table, a task.
var working: bool = false:
    set(value):
        if working != value:
            working = value
            _apply_animation()
var seated: bool = false:
    set(value):
        seated = value
        _apply_animation()
        queue_redraw()

var _sprite: AnimatedSprite2D
var _material: ShaderMaterial
var _sheet_key: String = ""
var _has_action: bool = false
var _rng := RandomNumberGenerator.new()
var _t: float = 0.0
var _breath_period: float = 3.4
var _breath_shift: float = 0.0
var _gesture: String = ""
var _gesture_start: float = 0.0
var _gesture_sign: int = 1
var _frame_override: int = -1
var _emote: String = ""
var _emote_start: float = 0.0
var _emote_len: float = 1.5
var _look_plan: Array = []
var _nod_next: float = 0.0
var _nod_until: float = 0.0
var _burst_until: float = 0.0
var _rest_until: float = 0.0
var _head := Vector2i.ZERO
var _body := Vector2i.ZERO
var _hop: int = 0
var _noticed: bool = false
var _watching: bool = false
var _release_at: float = 0.0
var _track_at: float = 0.0
var _next_idle: float = 0.0
var _pace_target: Vector2 = Vector2.INF
var _pace_wait: float = 0.0

static func crew_sheet(npc_id: String) -> String:
    return "res://assets/pixel080/crew/%s.png" % npc_id

static func player_sheet(preset: String) -> String:
    return "res://assets/pixel080/player/%s.png" % preset

static func action_sheet(sheet_path: String) -> String:
    return sheet_path.get_basename() + "_action.png"

static func motion_shader() -> Shader:
    if _shader == null:
        _shader = Shader.new()
        _shader.code = MOTION_SHADER
    return _shader

func setup(sheet_path: String, id: String, name_text: String, color: Color, action_path: String = "") -> void:
    actor_id = id
    display_name = name_text
    accent = color
    _sheet_key = sheet_path.get_file().get_basename()
    _rng.seed = hash(id + ":" + _sheet_key)
    _breath_period = _rng.randf_range(3.0, 3.9)
    _breath_shift = _rng.randf_range(0.0, _breath_period)
    _next_idle = _rng.randf_range(1.5, 4.0)
    var personality: Dictionary = AstraCrewCatalog.CREW.get(id, {}).get("personality", {})
    social = float(personality.get("social", 0.5))
    calm = float(personality.get("calm", 0.7))
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _sprite = AnimatedSprite2D.new()
    _sprite.centered = false
    _sprite.offset = Vector2(-FRAME.x / 2.0, -FRAME.y + 4.0)
    _sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _material = ShaderMaterial.new()
    _material.shader = motion_shader()
    _material.set_shader_parameter("frame_px", Vector2(FRAME))
    _sprite.material = _material
    var frames := SpriteFrames.new()
    var sheet: Texture2D = load(sheet_path) if ResourceLoader.exists(sheet_path) else null
    for row in range(DIRECTIONS.size()):
        var dir: String = DIRECTIONS[row]
        frames.add_animation("walk_" + dir)
        frames.set_animation_speed("walk_" + dir, WALK_FPS)
        frames.set_animation_loop("walk_" + dir, true)
        frames.add_animation("idle_" + dir)
        frames.set_animation_loop("idle_" + dir, false)
        if sheet == null:
            continue
        # left step, stand, right step, stand
        for column in [0, 1, 2, 1]:
            frames.add_frame("walk_" + dir, _frame(sheet, column, row))
        frames.add_frame("idle_" + dir, _frame(sheet, 1, row))
    var action_file := action_path if action_path != "" else action_sheet(sheet_path)
    var action: Texture2D = load(action_file) if ResourceLoader.exists(action_file) else null
    if action != null:
        _has_action = true
        # rows: work (back), talk (front), sit (front), reactions (front)
        _add_loop(frames, "work_up", action, 0, [0, 1, 2, 1], 5.0)
        _add_loop(frames, "talk_down", action, 1, [0, 1, 2, 1], 6.0)
        _add_loop(frames, "sit_down", action, 2, [0], 1.0)
        _add_loop(frames, "sit_talk", action, 2, [0, 1], 4.0)
        for column in range(3):
            _add_loop(frames, "react_%d" % column, action, 3, [column], 1.0)
    if frames.has_animation("default"):
        frames.remove_animation("default")
    _sprite.sprite_frames = frames
    add_child(_sprite)
    face(facing)

func _add_loop(frames: SpriteFrames, anim: String, sheet: Texture2D, row: int, columns: Array, fps: float) -> void:
    frames.add_animation(anim)
    frames.set_animation_speed(anim, fps)
    frames.set_animation_loop(anim, columns.size() > 1)
    for column in columns:
        frames.add_frame(anim, _frame(sheet, int(column), row))

func _frame(sheet: Texture2D, column: int, row: int) -> AtlasTexture:
    var atlas := AtlasTexture.new()
    atlas.atlas = sheet
    atlas.region = Rect2(column * FRAME.x, row * FRAME.y, FRAME.x, FRAME.y)
    atlas.filter_clip = true
    return atlas

func has_action_sheet() -> bool:
    return _has_action

func face(dir: String) -> void:
    if dir not in DIRECTIONS:
        return
    facing = dir
    if _material != null:
        var side := SIDE_ROWS if dir in ["left", "right"] else 0
        _material.set_shader_parameter("neck_row", float(int(NECK_ROWS.get(_sheet_key, DEFAULT_NECK)) + side))
        _material.set_shader_parameter("waist_row", float(WAIST_ROW + side))
    _apply_animation()

func set_moving(value: bool) -> void:
    if moving == value:
        return
    moving = value
    _apply_animation()

# Which drawn loop fits right now. Without an action sheet it is always the
# walking sheet (the made-up poses happen in the shader).
func current_animation() -> String:
    if moving:
        return "walk_" + facing
    if _has_action and facing == "down" and _gesture != "" and GESTURE_DRAWN.has(_gesture) and not seated:
        return "react_%d" % int(GESTURE_DRAWN[_gesture])
    if _has_action and seated and facing == "down":
        return "sit_talk" if talking else "sit_down"
    if _has_action and working and facing == "up":
        return "work_up"
    if _has_action and talking and facing == "down":
        return "talk_down"
    return "idle_" + facing

func _apply_animation() -> void:
    if _sprite == null:
        return
    _frame_override = -1
    var anim := current_animation()
    if _sprite.animation != anim or not _sprite.is_playing():
        _sprite.play(anim)
    queue_redraw()

func _drawn_pose() -> bool:
    return not str(_sprite.animation).begins_with("idle_") and not str(_sprite.animation).begins_with("walk_")

# Turn toward a point (used when someone is spoken to). An explicit turn
# cancels a planned look-around.
func look_at_point(point: Vector2) -> void:
    _look_plan.clear()
    var delta := point - position
    if absf(delta.x) > absf(delta.y):
        face("right" if delta.x > 0.0 else "left")
    else:
        face("down" if delta.y > 0.0 else "up")

# ---------------------------------------------------------------- gestures

func gesture(name: String, force: bool = false) -> void:
    if not GESTURES.has(name):
        return
    if _gesture != "" and not force:
        return
    _gesture = name
    _gesture_start = _t
    _gesture_sign = -1 if _rng.randf() < 0.5 else 1
    _apply_animation()

func gesture_active() -> String:
    return _gesture

func emote(kind: String, seconds: float = 1.5, force: bool = false) -> void:
    if not EMOTE_GLYPHS.has(kind):
        return
    if _emote != "" and _t - _emote_start < 0.7 and not force:
        return
    _emote = kind
    _emote_start = _t
    _emote_len = seconds
    queue_redraw()

func emote_active() -> String:
    return _emote

# A look to one side, the other, and back.
func look_around() -> void:
    var back := facing
    var sides: Array = ["left", "right"] if facing in ["down", "up"] else ["down", "up"]
    if _rng.randf() < 0.5:
        sides.reverse()
    face(str(sides[0]))
    _look_plan = [[_t + 0.75, str(sides[1])], [_t + 1.5, back]]

# Turn to something for a moment, then back.
func glance(point: Vector2, seconds: float = 1.2) -> void:
    var back := facing
    look_at_point(point)
    if facing != back:
        _look_plan = [[_t + seconds, back]]

func band_offsets() -> Array:
    return [_head, _body, _hop]

# ---------------------------------------------------------------- life in a room

# Called every frame for the people in an interlude. `engaged`: the explorer is
# talking to them or working with them right now.
func think(delta: float, player_pos: Vector2, engaged: bool, can_stand: Callable = Callable()) -> void:
    if engaged:
        _watching = true
        _release_at = _t + 1.4
        if moving:
            set_moving(false)
        return
    var d := position.distance_to(player_pos)
    if d < NOTICE_RANGE:
        if moving:
            set_moving(false)
            _pace_wait = 1.0
        if not _watching:
            _watching = true
            look_at_point(player_pos)
            working = false
            if not _noticed:
                _noticed = true
                if style == "work":
                    emote("!", 1.1)
                    gesture("startle")
                else:
                    gesture("nod")
        elif _t >= _track_at:
            _track_at = _t + 0.3
            look_at_point(player_pos)
        _release_at = _t + _rng.randf_range(0.8, 1.5)
        return
    if _watching:
        if _t < _release_at:
            return
        _watching = false
        face(home_facing)
        working = style == "work"
        _next_idle = _t + _rng.randf_range(1.5, 3.0)
        return
    if style == "pace" and can_stand.is_valid() and _pace(delta, player_pos, can_stand):
        return
    if _t >= _next_idle and _look_plan.is_empty():
        _next_idle = _t + _rng.randf_range(2.6, 5.4) * lerpf(0.85, 1.35, calm)
        _idle_act(player_pos)

func _idle_act(player_pos: Vector2) -> void:
    var roll := _rng.randf()
    match style:
        "work":
            if roll < 0.15 + social * 0.15:
                glance(player_pos, 1.0)
            elif roll < 0.45:
                gesture("nod")
            elif roll < 0.55:
                emote("…", 1.3)
        "sit":
            if roll < 0.3:
                glance(player_pos, 1.3)
            elif roll < 0.5:
                glance(position + Vector2(-120.0 if _rng.randf() < 0.5 else 120.0, 0.0), 1.5)
            elif roll < 0.68:
                gesture("nod")
            elif roll < 0.76:
                gesture("sigh")
        "alert":
            if roll < 0.4:
                look_around()
            elif roll < 0.6:
                glance(position + Vector2(0.0, -240.0), 1.2)
            elif roll < 0.78:
                gesture("shiver")
            else:
                glance(player_pos, 1.0)
        _:
            if roll < 0.26:
                look_around()
            elif roll < 0.26 + social * 0.3:
                glance(player_pos, 1.2)
            elif roll < 0.72:
                gesture("shift")
            elif roll < 0.84:
                gesture("nod")
            else:
                gesture("sigh")

# Walks between home and home + pace_offset with a pause at each end. Returns
# false while paused so the ordinary idle acts can play.
func _pace(delta: float, player_pos: Vector2, can_stand: Callable) -> bool:
    if home == Vector2.INF:
        home = position
    if _pace_wait > 0.0:
        _pace_wait -= delta
        if moving:
            set_moving(false)
        if _pace_wait <= 0.0:
            _pace_target = home + pace_offset if position.distance_to(home) < 4.0 else home
        return false
    if _pace_target == Vector2.INF:
        _pace_target = home + pace_offset
    var to := _pace_target - position
    if to.length() < 3.0:
        position = _pace_target
        set_moving(false)
        face(home_facing)
        _pace_wait = _rng.randf_range(1.6, 3.2)
        return false
    var next := position + to.normalized() * minf(PACE_SPEED * delta, to.length())
    if next.distance_to(player_pos) < 52.0 or not bool(can_stand.call(next)):
        set_moving(false)
        _pace_wait = 0.8
        return false
    position = next
    if absf(to.x) > absf(to.y):
        face("right" if to.x > 0.0 else "left")
    else:
        face("down" if to.y > 0.0 else "up")
    set_moving(true)
    return true

# ---------------------------------------------------------------- per frame

func _process(delta: float) -> void:
    if _sprite == null:
        return
    _t += delta
    while not _look_plan.is_empty() and _t >= float(_look_plan[0][0]):
        var step: Array = _look_plan.pop_front()
        face(str(step[1]))
    var head := Vector2i.ZERO
    var body := Vector2i.ZERO
    var hop := 0
    var still := AstraUI.reduce_motion
    if not still and not _drawn_pose():
        if moving:
            # contact frames (feet apart) sit a pixel lower; lean into the walk
            var f := _sprite.frame
            body.y = 1 if f == 0 or f == 2 else 0
            head.y = body.y * 2
            if facing == "left":
                head.x = -1
            elif facing == "right":
                head.x = 1
        else:
            if fmod(_t + _breath_shift, _breath_period) > _breath_period * 0.55:
                body.y = 1
            head.y = body.y
            if working:
                var bent := _work_pose(head, body)
                head = bent[0]
                body = bent[1]
            if talking:
                if _t >= _nod_next:
                    _nod_until = _t + 0.14
                    _nod_next = _t + _rng.randf_range(0.4, 0.95)
                if _t < _nod_until:
                    head.y += 2
    var pose := _gesture_pose()
    if not pose.is_empty() and not moving:
        if not still and not _drawn_pose():
            head = pose[0]
            body = pose[1]
            hop = int(pose[2])
        var frame := int(pose[3])
        if frame != _frame_override:
            _frame_override = frame
            if frame >= 0 and not _drawn_pose():
                _sprite.play("walk_" + facing)
                _sprite.pause()
                _sprite.frame = frame
            elif frame < 0:
                var anim := current_animation()
                if _sprite.animation != anim or not _sprite.is_playing():
                    _sprite.play(anim)
    elif _frame_override >= 0 or (_gesture == "" and str(_sprite.animation).begins_with("react_")):
        _apply_animation()
    if still:
        hop = 0
    if head != _head or body != _body:
        _head = head
        _body = body
        _material.set_shader_parameter("head_off", Vector2(head))
        _material.set_shader_parameter("body_off", Vector2(body))
    var drop := 0
    if seated:
        drop = SIT_DROP_DRAWN if _has_action else SIT_DROP
    var y := float(drop - hop)
    if _sprite.position.y != y or hop != _hop:
        _sprite.position.y = y
        _hop = hop
        queue_redraw()
    if _emote != "":
        if _t - _emote_start > _emote_len:
            _emote = ""
        queue_redraw()

func _gesture_pose() -> Array:
    if _gesture == "":
        return []
    var track: Array = GESTURES.get(_gesture, [])
    var t := _t - _gesture_start
    for step in track:
        if t < float(step[0]):
            return [Vector2i(int(step[1]) * _gesture_sign, int(step[2])), Vector2i(int(step[3]) * _gesture_sign, int(step[4])), int(step[5]), int(step[6])]
        t -= float(step[0])
    _gesture = ""
    return []

# Bent over whatever they work on; now and then a burst of small movements
# (typing, turning a page), then a pause.
func _work_pose(head: Vector2i, body: Vector2i) -> Array:
    if _t >= _burst_until and _t >= _rest_until:
        _burst_until = _t + _rng.randf_range(0.8, 1.7)
        _rest_until = _burst_until + _rng.randf_range(0.5, 1.3)
    var busy := _t < _burst_until and int(_t / 0.16) % 2 == 0
    match facing:
        "up":
            head.y += 2
            if busy:
                body.x += 1
                head.x += 1
        "down":
            head.y += 2
            if busy:
                head.y += 1
        _:
            var s := -1 if facing == "left" else 1
            head.x += 2 * s
            body.x += s
            if busy:
                body.x += s
    return [head, body]

# ---------------------------------------------------------------- drawing

func _draw() -> void:
    var drop := 0.0
    if seated:
        drop = float(SIT_DROP_DRAWN if _has_action else SIT_DROP)
    else:
        # A soft ground shadow keeps the feet on the floor (smaller mid-hop).
        draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.36))
        draw_circle(Vector2(0, 0), 26.0 - _hop * 1.2, Color(0, 0, 0, 0.32 - _hop * 0.02))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    var head_top := -FRAME.y + 18.0 + drop - _hop
    if highlight:
        # beside a speech bubble, not under it
        var ring := Vector2(-14.0 if _emote != "" else 0.0, head_top - 16.0)
        draw_arc(ring, 7.0, 0.0, TAU, 20, accent, 3.0)
        draw_circle(ring, 3.0, accent)
    if _emote != "":
        _draw_emote(Vector2(14.0, head_top - 2.0))

func _draw_emote(anchor: Vector2) -> void:
    var age := _t - _emote_start
    var alpha := clampf((_emote_len - age) / 0.25, 0.0, 1.0)
    var rise := 0.0 if age > 0.1 or AstraUI.reduce_motion else roundf((0.1 - age) * 40.0)
    var glyph: Array = EMOTE_GLYPHS[_emote]
    var ink: Color = EMOTE_COLORS.get(_emote, Color.BLACK)
    ink.a = alpha
    if _emote == "sweat":
        # a drop beside the head that slides a little
        var at := anchor + Vector2(6.0, 14.0 + minf(6.0, floorf(age * 6.0)))
        _draw_glyph(glyph, at, Color(1, 1, 1, alpha * 0.9), 1.0)
        _draw_glyph(glyph, at, ink, 0.0)
        return
    var size := Vector2(5 * EMOTE_DOT + 8.0, 7 * EMOTE_DOT + 8.0)
    var box := Rect2(anchor + Vector2(0.0, -size.y + rise), size)
    var paper := Color(0.96, 0.97, 0.98, alpha)
    var line := Color(0.08, 0.11, 0.16, alpha)
    var tail := PackedVector2Array([box.position + Vector2(3.0, size.y - 1.0), box.position + Vector2(11.0, size.y - 1.0), box.position + Vector2(1.0, size.y + 7.0)])
    var tail_line := PackedVector2Array([box.position + Vector2(1.0, size.y - 1.0), box.position + Vector2(13.0, size.y - 1.0), box.position + Vector2(-1.0, size.y + 10.0)])
    draw_rect(box.grow(2.0), line)
    draw_colored_polygon(tail_line, line)
    draw_rect(box, paper)
    draw_colored_polygon(tail, paper)
    _draw_glyph(glyph, box.position + Vector2(4.0, 4.0), ink, 0.0)

func _draw_glyph(glyph: Array, at: Vector2, color: Color, grow: float) -> void:
    for row in range(glyph.size()):
        var text: String = glyph[row]
        for col in range(text.length()):
            if text[col] == "#":
                draw_rect(Rect2(at + Vector2(col * EMOTE_DOT, row * EMOTE_DOT), Vector2(EMOTE_DOT, EMOTE_DOT)).grow(grow), color)
