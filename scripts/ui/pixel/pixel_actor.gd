class_name AstraPixelActor
extends Node2D

# A walking chibi in the deck interludes. Portraits carry feeling in the
# conversation screens; these carry space and movement. Sheets come from
# tools/import_pixel_090.gd (AstraPixelManifest): 128x128 walking frames,
# 3 (crew) or 4 (explorers) per direction, rows down / up / left / right, feet
# at the bottom centre, plus a sheet of drawn poses (128x144) cut from each
# person's action sheets at the same standing size. Nearest filtering only.
#
# Two layers of motion:
#  * MOTION_SHADER moves whole-pixel bands of the standing / walking frame —
#    the head (and hair) above the neck row, the upper body above the waist
#    row, the legs planted — for breathing, nods, a head shake, bending over a
#    console. Nothing is redrawn or stretched.
#  * Drawn poses (greet, talk, listen, think, happy, surprised, cheer, sigh,
#    work, crouch, sit, point, ready, carry) replace the frame for gestures a
#    band cannot make: a raised hand, a start of surprise, sitting down. A
#    drawn gesture has a one-pixel dip before and after it (anticipation and
#    recovery), so standing -> pose -> standing is never a bare cut.
# Transitions: a walk starts with a push-off dip and ends with a settle dip;
# turning round in place passes through a side (or front) frame.

const FRAME := AstraPixelManifest.FRAME_SIZE
const POSE_FRAME := AstraPixelManifest.POSE_SIZE
const DIRECTIONS := ["down", "up", "left", "right"]
const WALK_FPS := 7.0
# Sheets are normalised to feet on row 126 and a median height of 112, so one
# waist row fits everyone. The neck row sits under the chin of the front frame
# (a split through a face would show); side frames stand ~4 rows lower. Crew
# values were checked by eye in 0.8.0, explorer values in 0.9.0.
const WAIST_ROW := 88
const SIDE_ROWS := 4
const DEFAULT_NECK := 70
const NECK_ROWS := {"mira": 69, "rho": 69, "eli": 71, "sena": 70, "vale": 71, "noa": 70, "lyra": 70, "dax": 68,
    "p1": 72, "p2": 72, "p3": 74, "p4": 70, "p5": 72, "p6": 72,
    "serin_a": 76, "mika_a": 72, "jace_a": 72, "rael_a": 74, "logan_a": 75, "sia_a": 72}
# Sitting behind a table: the table in front hides the legs. A drawn sitting
# pose is already low, so it only settles a little.
const SIT_DROP := 24
const SIT_DROP_DRAWN := 4
const NOTICE_RANGE := 170.0
const PACE_SPEED := 58.0
const STRIDE_PIXELS := 80.0
# 3-frame sheets (step, stand, step, stand): the steps are held a little longer.
const WALK_PHASES_3 := [0.0, 0.30, 0.50, 0.80, 1.0]
const WALK_PHASES_4 := [0.0, 0.25, 0.50, 0.75, 1.0]
const TURN_SECONDS := 0.07
const DIP_SECONDS := 0.07

const MOTION_SHADER := """
shader_type canvas_item;
uniform vec2 head_off = vec2(0.0);
uniform vec2 body_off = vec2(0.0);
uniform float neck_row = 70.0;
uniform float waist_row = 88.0;
uniform vec2 frame_px = vec2(128.0, 128.0);
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
# Which drawn pose stands in for a gesture when the person has one, and how
# long it is held. Nods, shakes and shivers stay band motions.
# The drawn "sigh" is a whole-body slump (sitting down hard), so it is only
# played on purpose (a task that did not work out), never as an idle sigh.
const GESTURE_POSE := {"startle": "surprised", "hop": "cheer", "joy": "cheer", "tilt": "think"}
const POSE_HOLD := {"greet": 1.0, "talk": 0.75, "listen": 1.4, "think": 1.1, "happy": 0.9, "surprised": 0.8,
    "cheer": 1.0, "sigh": 1.2, "crouch": 1.3, "point": 1.0, "ready": 1.2, "carry": 1.2}
# Poses big enough to turn a side-facing person to the front for a moment.
const TURNING_POSES := ["surprised", "cheer", "greet"]

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
# Match gait to distance, so the slow pacing crew and the explorer do not
# share an unrelated timer (no foot sliding). Previews keep the timed walk.
var distance_driven: bool = false
var _walk_distance: float = 0.0
var _last_walk_position: Vector2 = Vector2.INF
var highlight: bool = false:
    set(value):
        highlight = value
        queue_redraw()
# A line of theirs is on screen.
var talking: bool = false:
    set(value):
        if talking != value:
            talking = value
            _talk_beat_at = _t + _rng.randf_range(0.9, 1.8)
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
        if value:
            _pose = ""
        _apply_animation()
        queue_redraw()
# Explorers only: walking with their tool in hand (tablet, drone, helmet...).
var carrying: bool = false:
    set(value):
        if carrying != value:
            carrying = value and _has_carry
            _apply_animation()

var _sprite: AnimatedSprite2D
var _material: ShaderMaterial
var _sheet_key: String = ""
var _walk_frames: int = 3
var _poses: Dictionary = {}
var _has_carry: bool = false
var _rng := RandomNumberGenerator.new()
var _t: float = 0.0
var _breath_period: float = 3.4
var _breath_shift: float = 0.0
var _gesture: String = ""
var _gesture_start: float = 0.0
var _gesture_sign: int = 1
var _frame_override: int = -1
# A drawn pose in progress: name, variant, start, hold, mirrored.
var _pose: String = ""
var _pose_variant: int = 0
var _pose_start: float = 0.0
var _pose_len: float = 0.0
var _pose_flip: bool = false
var _talk_beat_at: float = 0.0
var _listen_at: float = 0.0
var _settle_until: float = -1.0
var _push_until: float = -1.0
var _turn_show: String = ""
var _turn_until: float = -1.0
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

static func player_sheet(art_id: String) -> String:
    return "res://assets/pixel080/player/%s.png" % art_id

static func motion_shader() -> Shader:
    if _shader == null:
        _shader = Shader.new()
        _shader.code = MOTION_SHADER
    return _shader

func setup(sheet_path: String, id: String, name_text: String, color: Color) -> void:
    actor_id = id
    display_name = name_text
    accent = color
    _sheet_key = sheet_path.get_file().get_basename()
    var info := AstraPixelManifest.sheet(_sheet_key)
    _walk_frames = clampi(int(info.get("frames", 3)), 3, 4)
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
    _sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _material = ShaderMaterial.new()
    _material.shader = motion_shader()
    _sprite.material = _material
    var frames := SpriteFrames.new()
    var sheet: Texture2D = load(sheet_path) if ResourceLoader.exists(sheet_path) else null
    _add_walk(frames, sheet, "", info.get("stand", []))
    var carry_path := str(info.get("carry", ""))
    if carry_path != "" and ResourceLoader.exists(carry_path):
        _has_carry = true
        _add_walk(frames, load(carry_path), "carry_", info.get("carry_stand", []))
    var pose_path := str(info.get("poses_sheet", ""))
    if pose_path != "" and ResourceLoader.exists(pose_path):
        var pose_sheet: Texture2D = load(pose_path)
        var cols := int(info.get("pose_cols", 8))
        var poses: Dictionary = info.get("poses", {})
        for pose in poses:
            var cells: Array = poses[pose]
            for v in range(cells.size()):
                var anim := "pose_%s_%d" % [pose, v]
                frames.add_animation(anim)
                frames.set_animation_loop(anim, false)
                var atlas := AtlasTexture.new()
                atlas.atlas = pose_sheet
                atlas.region = Rect2((int(cells[v]) % cols) * POSE_FRAME.x, (int(cells[v]) / cols) * POSE_FRAME.y, POSE_FRAME.x, POSE_FRAME.y)
                atlas.filter_clip = true
                frames.add_frame(anim, atlas)
            _poses[str(pose)] = cells.size()
    if frames.has_animation("default"):
        frames.remove_animation("default")
    _sprite.sprite_frames = frames
    add_child(_sprite)
    face(facing)

func _add_walk(frames: SpriteFrames, sheet: Texture2D, prefix: String, stand: Array) -> void:
    for row in range(DIRECTIONS.size()):
        var dir: String = DIRECTIONS[row]
        var walk := prefix + "walk_" + dir
        var idle := prefix + "idle_" + dir
        frames.add_animation(walk)
        frames.set_animation_speed(walk, WALK_FPS)
        frames.set_animation_loop(walk, true)
        frames.add_animation(idle)
        frames.set_animation_loop(idle, false)
        if sheet == null:
            continue
        # 3 frames: left step, stand, right step, stand. 4 frames: as drawn.
        var order: Array = [0, 1, 2, 1] if _walk_frames == 3 else [0, 1, 2, 3]
        for column in order:
            frames.add_frame(walk, _frame(sheet, int(column), row))
        var stand_col := int(stand[row]) if row < stand.size() else 1
        frames.add_frame(idle, _frame(sheet, clampi(stand_col, 0, _walk_frames - 1), row))

func _frame(sheet: Texture2D, column: int, row: int) -> AtlasTexture:
    var atlas := AtlasTexture.new()
    atlas.atlas = sheet
    atlas.region = Rect2(column * FRAME.x, row * FRAME.y, FRAME.x, FRAME.y)
    atlas.filter_clip = true
    return atlas

func has_pose(name: String) -> bool:
    return _poses.has(name)

func pose_names() -> Array:
    return _poses.keys()

# Kept for the 0.8.x call sites: "has drawn poses".
func has_action_sheet() -> bool:
    return not _poses.is_empty()

func walk_frame_count() -> int:
    return _walk_frames

func face(dir: String) -> void:
    if dir not in DIRECTIONS:
        return
    # Turning round in place passes through the side (or the front).
    if not moving and dir != facing and _sprite != null and not AstraUI.reduce_motion and _opposite(dir) == facing:
        _turn_show = "down" if dir in ["left", "right"] else ("left" if _rng.randf() < 0.5 else "right")
        _turn_until = _t + TURN_SECONDS
    facing = dir
    _apply_bands_for(_shown_facing())
    _apply_animation()

func _opposite(dir: String) -> String:
    return {"left": "right", "right": "left", "up": "down", "down": "up"}[dir]

func _shown_facing() -> String:
    return _turn_show if _t < _turn_until and _turn_show != "" else facing

func _apply_bands_for(dir: String) -> void:
    if _material == null:
        return
    var side := SIDE_ROWS if dir in ["left", "right"] else 0
    _material.set_shader_parameter("neck_row", float(int(NECK_ROWS.get(_sheet_key, AstraPixelManifest.sheet(_sheet_key).get("neck", DEFAULT_NECK))) + side))
    _material.set_shader_parameter("waist_row", float(WAIST_ROW + side))

func set_moving(value: bool) -> void:
    if moving == value:
        return
    moving = value
    if value:
        _gesture = ""
        _pose = ""
        _look_plan.clear()
        _walk_distance = STRIDE_PIXELS * (0.30 if _walk_frames == 3 else 0.0)
        _last_walk_position = position
        _push_until = _t + DIP_SECONDS
        _turn_until = -1.0
    else:
        _settle_until = _t + DIP_SECONDS + 0.03
    _apply_animation()
    if value:
        _sprite.frame = 1 if _walk_frames == 3 else 0

# Which frame fits right now.
func current_animation() -> String:
    var prefix := "carry_" if carrying else ""
    if moving:
        return prefix + "walk_" + facing
    var shown := _shown_facing()
    if _pose != "" and _pose_phase() == "hold":
        return "pose_%s_%d" % [_pose, _pose_variant]
    if seated and shown == "down" and has_pose("sit"):
        return "pose_sit_%d" % _stable_variant("sit")
    if working and shown == "down" and has_pose("work") and _pose == "":
        return "pose_work_%d" % _stable_variant("work")
    return prefix + "idle_" + shown

func _stable_variant(name: String) -> int:
    return absi(hash(actor_id + name)) % maxi(1, int(_poses.get(name, 1)))

func _apply_animation() -> void:
    if _sprite == null:
        return
    _frame_override = -1
    var anim := current_animation()
    var old_frame := _sprite.frame
    var old_progress := _sprite.frame_progress
    var turning := str(_sprite.animation).contains("walk_") and anim.contains("walk_")
    if _sprite.animation != anim or (not _sprite.is_playing() and not (distance_driven and moving)):
        _sprite.play(anim)
        if turning:
            _sprite.set_frame_and_progress(old_frame, old_progress)
    if distance_driven and moving:
        _sprite.pause()
    var drawn := anim.begins_with("pose_")
    var size: Vector2i = POSE_FRAME if drawn else FRAME
    _sprite.offset = Vector2(-size.x / 2.0, -size.y + 4.0)
    _sprite.flip_h = drawn and _pose_flip and anim == "pose_%s_%d" % [_pose, _pose_variant]
    _material.set_shader_parameter("frame_px", Vector2(size))
    queue_redraw()

func _drawn_pose() -> bool:
    return str(_sprite.animation).begins_with("pose_")

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

# A band gesture, or its drawn pose when the person has one (§3-5: every drawn
# pose has a dip in and a dip out).
func gesture(name: String, force: bool = false) -> void:
    if not GESTURES.has(name):
        return
    if (_gesture != "" or _pose != "") and not force:
        return
    var drawn := str(GESTURE_POSE.get(name, ""))
    if drawn != "" and pose(drawn, -1.0, force):
        _gesture = ""
        return
    _gesture = name
    _pose = ""
    _gesture_start = _t
    _gesture_sign = -1 if _rng.randf() < 0.5 else 1
    _apply_animation()

# Plays a drawn pose for `seconds` (<= 0: its usual hold). Front-facing poses
# only play facing the room; big reactions turn the person to it for a moment.
func pose(name: String, seconds: float = -1.0, force: bool = false) -> bool:
    if not has_pose(name) or moving or seated:
        return false
    if (_pose != "" or _gesture != "") and not force:
        return false
    var shown := _shown_facing()
    if shown != "down" and name not in TURNING_POSES:
        return false
    _pose = name
    _pose_variant = _rng.randi_range(0, int(_poses[name]) - 1)
    _pose_start = _t
    _pose_len = seconds if seconds > 0.0 else float(POSE_HOLD.get(name, 1.0))
    _pose_flip = shown == "left" or (shown == "down" and _rng.randf() < 0.35 and name in ["point", "talk", "greet"])
    _gesture = ""
    _apply_animation()
    return true

func pose_active() -> String:
    return _pose

func _pose_phase() -> String:
    if _pose == "":
        return ""
    var t := _t - _pose_start
    if AstraUI.reduce_motion:
        return "hold" if t < _pose_len else "done"
    if t < DIP_SECONDS:
        return "in"
    if t < DIP_SECONDS + _pose_len:
        return "hold"
    if t < DIP_SECONDS * 2.0 + _pose_len:
        return "out"
    return "done"

func gesture_active() -> String:
    return _gesture if _gesture != "" else _pose

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
        # Listening: now and then a drawn listening pose while the other talks.
        if not talking and not working and _t >= _listen_at:
            _listen_at = _t + _rng.randf_range(3.0, 5.5)
            if _rng.randf() < 0.45 and not pose("listen"):
                pose("think")
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
                elif _rng.randf() < 0.35 + social * 0.5 and pose("greet"):
                    pass
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
            if roll < 0.35:
                look_around()
            elif roll < 0.5:
                glance(position + Vector2(0.0, -240.0), 1.2)
            elif roll < 0.62 and facing == "down" and pose("ready"):
                pass
            elif roll < 0.78:
                gesture("shiver")
            else:
                glance(player_pos, 1.0)
        _:
            if roll < 0.24:
                look_around()
            elif roll < 0.24 + social * 0.28:
                glance(player_pos, 1.2)
            elif roll < 0.62:
                gesture("shift")
            elif roll < 0.72 and facing == "down" and (pose("think") or pose("listen")):
                pass
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
    if distance_driven and moving and delta > 0.0:
        if _last_walk_position != Vector2.INF:
            _walk_distance += minf(position.distance_to(_last_walk_position), STRIDE_PIXELS)
        var phase := fmod(_walk_distance / STRIDE_PIXELS, 1.0)
        var phases: Array = WALK_PHASES_3 if _walk_frames == 3 else WALK_PHASES_4
        for index in range(4):
            if phase >= phases[index] and phase < phases[index + 1]:
                _sprite.frame = index
                break
    _last_walk_position = position
    while not _look_plan.is_empty() and _t >= float(_look_plan[0][0]):
        var step: Array = _look_plan.pop_front()
        face(str(step[1]))
    if _turn_show != "" and _t >= _turn_until:
        _turn_show = ""
        _apply_bands_for(facing)
        _apply_animation()
    # Drawn poses: enter the hold, leave it, end.
    if _pose != "":
        var phase_now := _pose_phase()
        var want_drawn := phase_now == "hold"
        if want_drawn != _drawn_pose() or (want_drawn and _sprite.animation != StringName("pose_%s_%d" % [_pose, _pose_variant])):
            _apply_animation()
        if phase_now == "done":
            _pose = ""
            _apply_animation()
    # Talking facing the room: a drawn gesture every few seconds.
    if talking and not moving and not seated and _pose == "" and _gesture == "" and has_pose("talk") and _t >= _talk_beat_at:
        _talk_beat_at = _t + _rng.randf_range(1.9, 3.4)
        if _shown_facing() == "down" and _rng.randf() < 0.7:
            pose("talk")
    var head := Vector2i.ZERO
    var body := Vector2i.ZERO
    var hop := 0
    var still := AstraUI.reduce_motion
    if not still and not _drawn_pose():
        if moving:
            if _walk_frames == 3:
                # contact frames (feet apart) sit a pixel lower
                var f := _sprite.frame
                body.y = 1 if f == 0 or f == 2 else 0
                head.y = body.y * 2
            if _t < _push_until:
                body.y = 1
                head.y = 1
            if facing == "left":
                head.x = -1
            elif facing == "right":
                head.x = 1
        else:
            if fmod(_t + _breath_shift, _breath_period) > _breath_period * 0.55:
                body.y = 1
            head.y = body.y
            if _t < _settle_until:
                body.y = 1
                head.y = 2
            if _pose != "" and _pose_phase() in ["in", "out"]:
                # anticipation / recovery around a drawn pose
                body.y = 1
                head.y = 2
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
    var gesture_pose := _gesture_pose()
    if not gesture_pose.is_empty() and not moving:
        if not still and not _drawn_pose():
            head = gesture_pose[0]
            body = gesture_pose[1]
            hop = int(gesture_pose[2])
        var frame := int(gesture_pose[3])
        if frame != _frame_override:
            _frame_override = frame
            if frame >= 0 and not _drawn_pose():
                _sprite.play(("carry_" if carrying else "") + "walk_" + facing)
                _sprite.pause()
                _sprite.frame = frame
            elif frame < 0:
                var anim := current_animation()
                if _sprite.animation != anim or not _sprite.is_playing():
                    _sprite.play(anim)
    elif _frame_override >= 0:
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
        drop = SIT_DROP_DRAWN if _drawn_pose() else SIT_DROP
    # Keep fractional simulation positions for collision/movement, snap the
    # displayed actor only (whole pixels, no sub-pixel blur).
    var snapped := position.round() - position
    var visual_position := Vector2(snapped.x, float(drop - hop) + snapped.y)
    if _sprite.position != visual_position or hop != _hop:
        _sprite.position = visual_position
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
        drop = float(SIT_DROP_DRAWN if _drawn_pose() else SIT_DROP)
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
