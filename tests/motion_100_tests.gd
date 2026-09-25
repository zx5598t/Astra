extends SceneTree

# 1.0.0 locomotion gate (headless). Walking must be carried by the drawn
# frames: the legs change between consecutive frames of the cycle, the feet
# stay on one floor line, the figure keeps its height and axis, frames advance
# with the distance actually walked (per-sheet stride, no skating), the upper
# body is never moved against the legs while walking, turning keeps the gait
# phase, reduced motion still walks, and no transition shows an empty frame.
#   godot --headless --path . --script res://tests/motion_100_tests.gd

const LEG_ROWS := Vector2i(92, 128)
const MIN_LEG_CHANGE := 40

var checks := 0
var failures: Array = []

func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)
        print("FAIL · " + label)

func _initialize() -> void:
    var keys: Array = AstraCrewCatalog.ORDER.duplicate()
    keys.append_array(AstraExplorerCatalog.ART_IDS)
    check(keys.size() == 14, "fourteen active characters")
    for key in keys:
        _sheet_audit(str(key))
        _gait(str(key))
    _turns_and_stops()
    _reduce_motion_walks()
    _transitions()
    if failures.is_empty():
        print("ASTRA MOTION 100 TESTS OK · %d checks" % checks)
        quit()
    else:
        print("ASTRA MOTION 100 TESTS FAILED · %d/%d" % [failures.size(), checks])
        quit(1)

func _image(path: String) -> Image:
    var img: Image = load(path).get_image()
    if img.is_compressed():
        img.decompress()
    return img

func _leg_change(a: Image, b: Image) -> int:
    var changed := 0
    for y in range(LEG_ROWS.x, LEG_ROWS.y):
        for x in range(a.get_width()):
            if (a.get_pixel(x, y).a > 0.5) != (b.get_pixel(x, y).a > 0.5):
                changed += 1
    return changed

# Horizontal centre of the torso and hips (50-78% of the figure). The feet
# legitimately shift when one foot is lifted and hair flares; the body must not.
func _body_x(img: Image) -> float:
    var used := img.get_used_rect()
    var total := 0.0
    var count := 0
    for y in range(used.position.y + int(used.size.y * 0.5), used.position.y + int(used.size.y * 0.78)):
        for x in range(img.get_width()):
            if img.get_pixel(x, y).a > 0.5:
                total += x
                count += 1
    return total / maxf(1.0, count)

# Every walking sheet (and tool walk): real leg change between consecutive
# frames, one floor, stable height and axis.
func _sheet_audit(key: String) -> void:
    var info := AstraPixelManifest.sheet(key)
    var sheets: Array = [["walk", str(info.get("walk", ""))]]
    if info.has("carry"):
        sheets.append(["carry", str(info["carry"])])
    for pair in sheets:
        var img := _image(str(pair[1]))
        var cols := int(info.get("frames", 3))
        var order: Array = [0, 1, 2, 1] if cols == 3 else [0, 1, 2, 3]
        for row in range(4):
            var frames: Array = []
            for c in range(cols):
                frames.append(img.get_region(Rect2i(c * 128, row * 128, 128, 128)))
            var label := "%s %s %s" % [key, pair[0], AstraPixelActor.DIRECTIONS[row]]
            var heights: Array = []
            var bottoms: Array = []
            var axes: Array = []
            for f in frames:
                var used: Rect2i = f.get_used_rect()
                check(used.size.y > 60, label + ": frame drawn")
                heights.append(used.size.y)
                bottoms.append(used.end.y)
                axes.append(_body_x(f))
            for i in range(order.size()):
                var change := _leg_change(frames[order[i]], frames[order[(i + 1) % order.size()]])
                check(change >= MIN_LEG_CHANGE, "%s: legs move between frames %d and %d (%d px)" % [label, order[i], order[(i + 1) % order.size()], change])
            check(int(bottoms.max()) - int(bottoms.min()) <= 2, label + ": feet on one floor line")
            check(int(heights.max()) - int(heights.min()) <= 12, label + ": height stays the same through the cycle (%d..%d)" % [heights.min(), heights.max()])
            check(float(axes.max()) - float(axes.min()) <= 3.0, label + ": no sideways jump of the body axis")
        var stride := float(info.get("carry_stride" if pair[0] == "carry" else "stride", 0))
        check(stride >= 56.0 and stride <= 112.0, key + ": stride measured from the sheet")

# Walking a straight line: the frames advance with distance, every frame of
# the cycle is shown once per stride, the upper body is not moved by bands.
func _gait(key: String) -> void:
    var path := AstraPixelActor.crew_sheet(key) if key in AstraCrewCatalog.ORDER else AstraPixelActor.player_sheet(key)
    var a := AstraPixelActor.new()
    a.setup(path, key, "", Color.WHITE)
    a.distance_driven = true
    a.face("right")
    a._process(0.2)
    var start_idle := a._sprite.sprite_frames.get_frame_texture(a._sprite.animation, a._sprite.frame)
    a.set_moving(true)
    var first_walk := a._sprite.sprite_frames.get_frame_texture(a._sprite.animation, a._sprite.frame)
    check(start_idle is AtlasTexture and first_walk is AtlasTexture and (start_idle as AtlasTexture).region == (first_walk as AtlasTexture).region, key + ": the walk starts on the frame they stood on")
    var stride := a._stride()
    var seen := {}
    var sequence: Array = []
    var steps := 32
    for i in range(steps):
        a.position.x += stride / float(steps)
        a._process(1.0 / 60.0)
        seen[a._sprite.frame] = true
        if sequence.is_empty() or int(sequence.back()) != a._sprite.frame:
            sequence.append(a._sprite.frame)
        check(a.band_offsets()[0] == Vector2i.ZERO and a.band_offsets()[1] == Vector2i.ZERO, key + ": no band motion while walking")
    check(seen.size() == 4, key + ": one stride shows the whole cycle (%s)" % str(sequence))
    check(sequence.size() == 4 or sequence.size() == 5, key + ": each frame once per stride, in order (%s)" % str(sequence))
    # Standing still while "moving" (blocked): the feet do not cycle.
    var frame := a._sprite.frame
    for i in range(10):
        a._process(1.0 / 60.0)
    check(a._sprite.frame == frame, key + ": no walking in place when blocked")
    a.free()

func _turns_and_stops() -> void:
    var a := AstraPixelActor.new()
    a.setup(AstraPixelActor.player_sheet("mika_a"), "player", "", Color.WHITE)
    a.distance_driven = true
    a.face("right")
    a.set_moving(true)
    for i in range(7):
        a.position.x += 6.0
        a._process(1.0 / 60.0)
    var frame := a._sprite.frame
    a.face("up")
    check(a._sprite.frame == frame, "a 90-degree turn while walking keeps the gait phase")
    a.face("down")
    check(a.current_animation() in ["walk_left", "walk_right"], "a 180-degree turn while walking passes through a side frame")
    check(a._sprite.frame == frame, "and keeps the gait phase")
    a._process(0.12)
    check(a.current_animation() == "walk_down", "then walks the new way")
    a.set_moving(false)
    var tex := a._sprite.sprite_frames.get_frame_texture(a._sprite.animation, a._sprite.frame)
    check(tex != null and a.current_animation() == "idle_down", "walk -> idle lands on the standing frame, never an empty one")
    a.face("up")
    check(a.current_animation() in ["idle_left", "idle_right"], "turning round in place passes through a side frame")
    a._process(0.12)
    check(a.current_animation() == "idle_up", "and ends facing the new way")
    a.free()

func _reduce_motion_walks() -> void:
    AstraUI.reduce_motion = true
    var a := AstraPixelActor.new()
    a.setup(AstraPixelActor.crew_sheet("sena"), "sena", "", Color.WHITE)
    a.distance_driven = true
    a.face("left")
    a.set_moving(true)
    var seen := {}
    for i in range(30):
        a.position.x -= 4.0
        a._process(1.0 / 60.0)
        seen[a._sprite.frame] = true
        check(int(a.band_offsets()[2]) == 0, "reduced motion: no rise on passing frames")
    check(seen.size() >= 3, "reduced motion still walks: the legs keep moving")
    a.free()
    AstraUI.reduce_motion = false

# idle -> talk -> listen -> walk -> sit -> stand: never an empty frame, the
# figure never jumps off its feet.
func _transitions() -> void:
    for key in ["mira", "logan_a"]:
        var a := AstraPixelActor.new()
        a.setup(AstraPixelActor.crew_sheet(key) if key == "mira" else AstraPixelActor.player_sheet(key), key, "", Color.WHITE)
        a.distance_driven = true
        var steps := [
            func(): a.talking = true,
            func(): a.talking = false,
            func(): a.pose("listen", 0.4, true),
            func(): a.set_moving(true),
            func(): a.position.y += 12.0,
            func(): a.set_moving(false),
            func(): a.seated = true,
            func(): a.seated = false,
            func(): a.gesture("startle", true),
        ]
        for step in steps:
            step.call()
            for i in range(8):
                a._process(0.03)
                var tex := a._sprite.sprite_frames.get_frame_texture(a._sprite.animation, a._sprite.frame)
                check(tex != null, "%s: no empty frame in transitions (%s)" % [key, a._sprite.animation])
                check(absf(a._sprite.position.y) <= 26.0, "%s: the figure stays on its spot" % key)
        a.free()
