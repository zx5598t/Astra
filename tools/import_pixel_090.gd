extends SceneTree

# Builds every runtime pixel sheet from the drawn sources. Sources are never
# modified.
#
#   godot --headless --path . --script res://tools/import_pixel_090.gd
#
# Sources: <art root>/미니 도트 캐릭/ (art root = ../인물 이미지/Astra, or the
# older ../0.5.0 수정 인물 이미지/Astra, or --art=<dir>). Temporary legacy looks
# p1-p6 come from <art root>/임시 (old saves keep them).
#
# Output (assets/pixel080/):
#   crew/<id>.png           walking (128x128 frames), 3 frames x 4 directions (down, up, left, right)
#   crew/<id>_poses.png     drawn poses from the two action sheets, POSE cells
#   player/<art>.png        explorer walking, 4 frames x 4 directions
#   player/<art>_carry.png  explorer walking with their tool (tablet, drone, helmet...)
#   player/<art>_poses.png, player/<art>_face.png
#   player/p1..p6(.png, _face.png)  legacy looks
#   manifest.json           audit data
# and scripts/ui/pixel/pixel_manifest.gd (what the game reads at runtime).
#
# Every picture of one person is scaled so their standing figure has the same
# height in every sheet: the walking sheet sets the scale (median frame height
# -> TARGET_HEIGHT), each action sheet is matched by its front idle cell, the
# carry sheet by its median. Nothing is stretched; frames are anchored by the
# feet. The drawn action sheets were produced at a larger canvas scale than the
# walking sheets, so matching the standing height (not the canvas) is what keeps
# a person the same size and proportion between walking and gesturing.
#
# Two crew action sheets are filed under each other's name in the source folder
# (루칸1.png shows Soren with his headset, 소렌2.png shows Lucan with his
# ponytail); the mapping below follows the drawing, not the file name.

const FRAME_W := 128
const FRAME_H := 128
const POSE_W := 128
const POSE_H := 144
const POSE_COLS := 8
const TARGET_HEIGHT := 112.0
const DIRECTIONS := ["down", "up", "left", "right"]

# Walk rows as drawn: which direction each source row faces. A direction that
# is missing is the mirror of the other side; when both side rows face the same
# way, the second becomes the mirrored opposite side.
const WALK_CREW_ROWS := ["down", "up", "left", "right"]
const WALK_4 := ["down", "up", "left", "right"]
const WALK_4_RR := ["down", "up", "right", "right"]
const CARRY_ROWS := ["down", "up", "right", "left"]

# Pose names the game understands (scripts/ui/pixel/pixel_actor.gd):
#   greet talk listen think happy surprised cheer sigh work crouch sit point ready carry
const CREW := {
    "mira": {"name": "미라", "walk": "미라.png",
        "actions": [["미라1.png", 3, 4], ["미라2.png", 3, 4]],
        "poses": {"greet": [[0, 2], [1, 2]], "talk": [[0, 1]], "listen": [[1, 1]], "think": [[0, 7]], "happy": [[0, 1], [1, 1]],
            "surprised": [[0, 9], [1, 9]], "cheer": [[0, 10], [1, 10]], "work": [[1, 7]], "crouch": [[0, 8], [1, 8]], "sit": [[0, 6], [1, 6]]}},
    "dax": {"name": "다렌", "walk": "다렌.png",
        "actions": [["다렌1.png", 3, 4], ["다렌2.png", 3, 4]],
        "poses": {"greet": [[0, 2]], "talk": [[0, 2], [1, 2]], "listen": [[0, 1]], "think": [[0, 6], [1, 1]], "happy": [[1, 9]],
            "surprised": [[0, 9], [1, 8]], "cheer": [[0, 10], [1, 9]], "work": [[0, 7], [1, 7]], "crouch": [[1, 11]], "sit": [[1, 6]]}},
    "eli": {"name": "루칸", "walk": "루칸.png",
        "actions": [["루칸2.png", 4, 3], ["소렌2.png", 3, 4]],
        "poses": {"greet": [[0, 2], [1, 2]], "talk": [[0, 8], [1, 8]], "listen": [[0, 1], [1, 1]], "think": [[0, 1]],
            "surprised": [[0, 9], [1, 9]], "cheer": [[0, 10], [1, 10]], "crouch": [[0, 6], [1, 6]], "sit": [[0, 11], [1, 11]],
            "ready": [[0, 7], [1, 7]], "point": [[0, 8], [1, 8]]}},
    "vale": {"name": "소렌", "walk": "소렌.png",
        "actions": [["소렌1.png", 4, 3], ["루칸1.png", 3, 4]],
        "poses": {"greet": [[0, 2], [1, 2]], "talk": [[0, 1], [1, 1]], "listen": [[0, 7], [1, 7]], "think": [[0, 7]], "happy": [[0, 1], [1, 1]],
            "surprised": [[0, 9], [1, 9]], "cheer": [[0, 10], [1, 10]], "work": [[0, 8], [1, 8]], "sit": [[0, 6], [1, 6]]}},
    "lyra": {"name": "마렌", "walk": "마렌.png",
        "actions": [["마렌1.png", 3, 4], ["마렌2.png", 4, 3]],
        "poses": {"greet": [[0, 2], [1, 2]], "talk": [[0, 7], [1, 7]], "happy": [[0, 1], [1, 1]],
            "surprised": [[0, 9], [1, 9]], "cheer": [[0, 10], [1, 10]], "work": [[0, 8], [1, 8]], "sit": [[0, 6], [1, 6]], "point": [[0, 7]]}},
    "rho": {"name": "준", "walk": "준.png",
        "actions": [["준1.png", 3, 4], ["준2.png", 3, 4]],
        "poses": {"greet": [[0, 2], [1, 2]], "talk": [[0, 1], [1, 1]], "happy": [[0, 1], [1, 1]],
            "surprised": [[0, 9], [1, 9]], "cheer": [[0, 10], [1, 10]], "work": [[0, 8], [1, 8]], "crouch": [[0, 7], [1, 7]]}},
    "sena": {"name": "세나", "walk": "세나.png",
        "actions": [["세나1.png", 3, 4], ["세나2.png", 3, 4]],
        "poses": {"greet": [[0, 2], [1, 2]], "talk": [[0, 1], [1, 1]], "happy": [[1, 1]],
            "surprised": [[0, 9], [1, 9]], "cheer": [[0, 10], [1, 10]], "crouch": [[0, 6], [1, 6]], "ready": [[0, 7], [1, 7]]}},
    "noa": {"name": "노아", "walk": "노아.png",
        "actions": [["노아2.png", 3, 4], ["노아3.png", 4, 3]],
        "poses": {"greet": [[0, 2], [1, 2]], "talk": [[0, 1], [1, 1]], "think": [[0, 7], [1, 7]], "happy": [[0, 1], [1, 1]],
            "surprised": [[0, 9], [1, 8]], "cheer": [[0, 10], [1, 9]], "sit": [[0, 6], [1, 6]]}},
}

const EXPLORERS := {
    "serin_a": {"name": "세린", "walk": "세린.png", "rows": WALK_4, "carry": "세린1.png",
        "actions": [["세린2.png", 4, 4]],
        "poses": {"greet": [[0, 3]], "talk": [[0, 6], [0, 5]], "listen": [[0, 1]], "think": [[0, 1]], "happy": [[0, 14]],
            "surprised": [[0, 7]], "cheer": [[0, 9]], "sigh": [[0, 10]], "work": [[0, 2], [0, 13]], "sit": [[0, 8]], "point": [[0, 6]]}},
    "mika_a": {"name": "미카", "walk": "미카.png", "rows": WALK_4_RR, "carry": "미카1.png",
        "actions": [["미카2.png", 4, 4]],
        "poses": {"greet": [[0, 1]], "talk": [[0, 9], [0, 13]], "happy": [[0, 15]], "surprised": [[0, 7]], "cheer": [[0, 10], [0, 15]],
            "sigh": [[0, 11]], "work": [[0, 2]], "crouch": [[0, 3], [0, 12]], "sit": [[0, 8]], "point": [[0, 9]], "carry": [[0, 6]]}},
    "jace_a": {"name": "제이스", "walk": "제이스.png", "rows": WALK_4, "carry": "제이스1.png",
        "actions": [["제이스2.png", 4, 4]],
        "poses": {"greet": [[0, 1]], "talk": [[0, 3], [0, 6]], "listen": [[0, 2]], "happy": [[0, 3]], "surprised": [[0, 7]],
            "cheer": [[0, 10], [0, 11]], "sigh": [[0, 13]], "sit": [[0, 12]], "point": [[0, 6]], "ready": [[0, 8]]}},
    "rael_a": {"name": "라엘", "walk": "라엘.png", "rows": WALK_4_RR, "carry": "라엘1.png",
        "actions": [["라엘2.png", 4, 4]],
        "poses": {"greet": [[0, 2]], "talk": [[0, 3], [0, 10]], "listen": [[0, 1]], "think": [[0, 6]], "happy": [[0, 15]],
            "surprised": [[0, 7]], "cheer": [[0, 11]], "sigh": [[0, 13]], "work": [[0, 1], [0, 5]], "crouch": [[0, 4], [0, 8]],
            "sit": [[0, 12]], "point": [[0, 10]]}},
    "logan_a": {"name": "로건", "walk": "로건.png", "rows": WALK_4, "carry": "로건1.png",
        "actions": [["로건2.png", 4, 4]],
        "poses": {"greet": [[0, 1]], "talk": [[0, 3], [0, 8]], "listen": [[0, 1]], "think": [[0, 1]], "cheer": [[0, 13]],
            "surprised": [[0, 7]], "sigh": [[0, 14]], "work": [[0, 8]], "crouch": [[0, 4]], "sit": [[0, 12]], "ready": [[0, 2]],
            "point": [[0, 3]], "carry": [[0, 6]]}},
    "sia_a": {"name": "시아", "walk": "시아.png", "rows": WALK_4_RR, "carry": "시아1.png",
        "actions": [["시아2.png", 4, 4]],
        "poses": {"greet": [[0, 1]], "talk": [[0, 2], [0, 3]], "happy": [[0, 2], [0, 14]], "surprised": [[0, 7]],
            "cheer": [[0, 10], [0, 12]], "sigh": [[0, 15]], "work": [[0, 5]], "crouch": [[0, 4], [0, 5]], "sit": [[0, 8], [0, 9]],
            "point": [[0, 3]], "carry": [[0, 6]]}},
}

var manifest := {"frame": [FRAME_W, FRAME_H], "pose_frame": [POSE_W, POSE_H], "directions": DIRECTIONS, "crew": {}, "player": {}}
var runtime := {}
var warnings: Array = []
var _who := ""

func _initialize() -> void:
    var root := ProjectSettings.globalize_path("res://")
    var art_root := ""
    for candidate in [root.path_join("../인물 이미지/Astra"), root.path_join("../0.5.0 수정 인물 이미지/Astra")]:
        if DirAccess.dir_exists_absolute(candidate.path_join("미니 도트 캐릭")):
            art_root = candidate
            break
    var out_root := root.path_join("assets/pixel080")
    var manifest_script := root.path_join("scripts/ui/pixel/pixel_manifest.gd")
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--art="):
            art_root = arg.substr(6)
        elif arg.begins_with("--out="):
            out_root = arg.substr(6)
            manifest_script = out_root.path_join("pixel_manifest.gd")
    if art_root == "":
        push_error("pixel import: art folder not found")
        quit(1)
        return
    var dots := art_root.path_join("미니 도트 캐릭")
    DirAccess.make_dir_recursive_absolute(out_root.path_join("crew"))
    DirAccess.make_dir_recursive_absolute(out_root.path_join("player"))
    for id in CREW:
        _build(id, CREW[id], dots, out_root.path_join("crew"), false)
    for id in EXPLORERS:
        _build(id, EXPLORERS[id], dots, out_root.path_join("player"), true)
    _legacy(art_root.path_join("임시"), out_root.path_join("player"))
    manifest["warnings"] = warnings
    var file := FileAccess.open(out_root.path_join("manifest.json"), FileAccess.WRITE)
    file.store_string(JSON.stringify(manifest, "  "))
    file.close()
    _write_runtime(manifest_script)
    print("ASTRA PIXEL IMPORT OK · crew %d · explorers %d · legacy %d · warnings %d" % [manifest["crew"].size(), EXPLORERS.size(), manifest["player"].size() - EXPLORERS.size(), warnings.size()])
    for w in warnings:
        print("  warning: " + str(w))
    quit()

# ---------------------------------------------------------------- per person

func _build(id: String, spec: Dictionary, dots: String, out_dir: String, explorer: bool) -> void:
    _who = id
    var walk_src := _load(dots.path_join(str(spec["walk"])))
    if walk_src == null:
        return
    var cols := 4 if explorer else 3
    var rows: Array = spec.get("rows", WALK_CREW_ROWS)
    var cells := _cut_grid(walk_src, cols, 4, false)
    var walk := _walk_sheet(cells, cols, rows, 0.0)
    walk["image"].save_png(out_dir.path_join(id + ".png"))
    var entry := {"source": str(spec["walk"]), "scale": walk["scale"], "frames": cols, "stride": walk["stride"], "contact": walk["contact"], "stand": walk["stand"],
        "neck": walk["neck"], "rows": rows, "audit": walk["audit"]}
    var rt := {"walk": _res(out_dir, id + ".png"), "frames": cols, "contact": walk["contact"], "stand": walk["stand"], "neck": walk["neck"], "stride": walk["stride"]}
    if explorer:
        _face(walk["image"], int(walk["stand"][0]), cols).save_png(out_dir.path_join(id + "_face.png"))
        var carry_src := _load(dots.path_join(str(spec["carry"])))
        if carry_src != null:
            var carry_cells := _cut_grid(carry_src, 4, 4, false)
            var scale := float(walk["scale"]) * float(walk["median_src"]) / maxf(1.0, _median_height(carry_cells))
            var carry := _walk_sheet(carry_cells, 4, CARRY_ROWS, scale)
            carry["image"].save_png(out_dir.path_join(id + "_carry.png"))
            entry["carry"] = {"source": str(spec["carry"]), "scale": carry["scale"], "contact": carry["contact"], "stand": carry["stand"], "audit": carry["audit"]}
            rt["carry"] = _res(out_dir, id + "_carry.png")
            rt["carry_contact"] = carry["contact"]
            rt["carry_stand"] = carry["stand"]
            rt["carry_stride"] = carry["stride"]
    # Drawn poses. The front standing height of the walking sheet is what the
    # idle cell of every action sheet is matched to.
    var stand_src_h := float(walk["stand_src_height"])
    var sheets: Array = []
    for action in spec.get("actions", []):
        var img := _load(dots.path_join(str(action[0])))
        if img == null:
            sheets.append([])
            continue
        var action_cells := _cut_grid(img, int(action[1]), int(action[2]), true)
        var ref: Dictionary = action_cells[0]
        var scale := float(walk["scale"])
        var fit := {}
        if not ref.is_empty():
            # Mostly the standing height; the head width (with its hair) pulls a
            # little, so a sheet drawn with longer legs or fuller hair does not
            # come out with a visibly smaller or larger head. Body proportions
            # match between the sheets; hair volume is what differs most.
            var h_ratio := stand_src_h / maxf(1.0, float(Rect2i(ref["rect"]).size.y))
            var w_ratio := float(walk["stand_src_head"]) / maxf(1.0, float(_head_width(ref["image"])))
            scale *= pow(h_ratio, 0.75) * pow(w_ratio, 0.25)
            fit = {"height_ratio": snappedf(h_ratio, 0.001), "head_ratio": snappedf(w_ratio, 0.001)}
            if absf(h_ratio / w_ratio - 1.0) > 0.30:
                warnings.append("%s: %s drawn with different proportions (height x%.2f, head x%.2f)" % [id, str(action[0]), h_ratio, w_ratio])
        sheets.append({"cells": action_cells, "scale": scale, "source": str(action[0]), "fit": fit})
    var fits: Array = []
    for sheet in sheets:
        fits.append(sheet.get("fit", {}) if sheet is Dictionary else {})
    entry["action_fit"] = fits
    var pose_list: Array = []
    var pose_index := {}
    var poses := {}
    for pose in spec.get("poses", {}):
        var picks: Array = []
        for ref in spec["poses"][pose]:
            var key := "%d:%d" % [int(ref[0]), int(ref[1])]
            if not pose_index.has(key):
                var sheet = sheets[int(ref[0])] if int(ref[0]) < sheets.size() else []
                if sheet is Array or int(ref[1]) >= sheet["cells"].size() or Dictionary(sheet["cells"][int(ref[1])]).is_empty():
                    warnings.append("%s: pose %s cell %s missing" % [id, pose, key])
                    continue
                pose_index[key] = pose_list.size()
                pose_list.append({"cell": sheet["cells"][int(ref[1])], "scale": sheet["scale"], "key": key, "source": sheet["source"]})
            picks.append(int(pose_index[key]))
        if not picks.is_empty():
            poses[pose] = picks
    if not pose_list.is_empty():
        var atlas_rows := int(ceil(pose_list.size() / float(POSE_COLS)))
        var atlas := Image.create(POSE_W * POSE_COLS, POSE_H * atlas_rows, false, Image.FORMAT_RGBA8)
        var pose_audit: Array = []
        for i in range(pose_list.size()):
            var item: Dictionary = pose_list[i]
            var small := _shrink(item["cell"]["image"], float(item["scale"]))
            _harden_and_outline(small)
            var feet_x := _feet_center(small)
            var origin := Vector2i((i % POSE_COLS) * POSE_W, (i / POSE_COLS) * POSE_H)
            var dest := origin + Vector2i(POSE_W / 2 - feet_x, POSE_H - 2 - small.get_height())
            var box := Rect2i(origin, Vector2i(POSE_W, POSE_H))
            var clip := Rect2i(dest, small.get_size()).intersection(box)
            atlas.blend_rect(small, Rect2i(clip.position - dest, clip.size), clip.position)
            var clipped := clip.size != small.get_size()
            if clipped:
                warnings.append("%s: pose cell %s clipped (%dx%d)" % [id, item["key"], small.get_width(), small.get_height()])
            pose_audit.append({"cell": item["key"], "source": item["source"], "size": [small.get_width(), small.get_height()], "clipped": clipped})
        atlas.save_png(out_dir.path_join(id + "_poses.png"))
        entry["poses"] = poses
        entry["pose_cells"] = pose_audit
        rt["poses_sheet"] = _res(out_dir, id + "_poses.png")
        rt["poses"] = poses
        rt["pose_cols"] = POSE_COLS
    manifest["player" if explorer else "crew"][id] = entry
    runtime[id] = rt

func _legacy(dir_path: String, out_dir: String) -> void:
    var dir := DirAccess.open(dir_path)
    if dir == null:
        return
    var names: Array = []
    for file_name in dir.get_files():
        if file_name.to_lower().ends_with(".png"):
            names.append(file_name)
    names.sort()
    for index in range(mini(6, names.size())):
        var preset := "p%d" % (index + 1)
        _who = preset
        var img := _load(dir_path.path_join(str(names[index])))
        if img == null:
            continue
        var walk := _walk_sheet(_cut_grid(img, 3, 4, false), 3, WALK_CREW_ROWS, 0.0)
        walk["image"].save_png(out_dir.path_join(preset + ".png"))
        _face(walk["image"], 1, 3).save_png(out_dir.path_join(preset + "_face.png"))
        manifest["player"][preset] = {"source": str(names[index]), "scale": walk["scale"], "frames": 3, "legacy": true, "audit": walk["audit"]}
        runtime[preset] = {"walk": _res(out_dir, preset + ".png"), "frames": 3, "contact": walk["contact"], "stand": walk["stand"], "neck": walk["neck"], "stride": walk["stride"]}

func _res(dir_path: String, file_name: String) -> String:
    var root := ProjectSettings.globalize_path("res://")
    var full := dir_path.path_join(file_name)
    return "res://" + full.trim_prefix(root) if full.begins_with(root) else full

# ---------------------------------------------------------------- walking

# cells: rows x cols in reading order. Output: one 96x128 frame per cell with
# the source rows re-ordered into down/up/left/right; a missing side is
# mirrored from the other. Returns image, scale and per-direction data.
func _walk_sheet(cells: Array, cols: int, rows: Array, fixed_scale: float) -> Dictionary:
    var median := _median_height(cells)
    var scale := fixed_scale if fixed_scale > 0.0 else TARGET_HEIGHT / maxf(1.0, median)
    var source_row := {}
    var mirrored := {}
    for r in range(rows.size()):
        var dir := str(rows[r])
        if source_row.has(dir):
            # a duplicate side becomes the mirrored other side
            var other := "left" if dir == "right" else ("right" if dir == "left" else dir)
            if not source_row.has(other):
                source_row[other] = r
                mirrored[other] = true
            continue
        source_row[dir] = r
    for pair in [["left", "right"], ["right", "left"]]:
        if not source_row.has(pair[0]) and source_row.has(pair[1]):
            source_row[pair[0]] = source_row[pair[1]]
            mirrored[pair[0]] = true
    var sheet := Image.create(FRAME_W * cols, FRAME_H * 4, false, Image.FORMAT_RGBA8)
    var contact: Array = []
    var stand: Array = []
    var audit: Array = []
    var stand_src_height := 0.0
    var stand_src_head := 1
    var side_spread: Array = []
    var neck := 70
    for d in range(4):
        var dir: String = DIRECTIONS[d]
        var r := int(source_row.get(dir, d))
        var spreads: Array = []
        var tops: Array = []
        var frames: Array = []
        for c in range(cols):
            var cell: Dictionary = cells[r * cols + c]
            if cell.is_empty():
                warnings.append(_who + ": empty walk cell row %d col %d" % [r, c])
                frames.append(null)
                spreads.append(0)
                tops.append(0)
                continue
            var small := _shrink(cell["image"], scale)
            if mirrored.get(dir, false):
                small.flip_x()
            _harden_and_outline(small)
            frames.append(small)
            spreads.append(_leg_spread(small))
            tops.append(FRAME_H - 2 - small.get_height())
        # For a mirrored side the frame order is kept (left foot / right foot
        # swap sides, which is what a mirror does).
        var order: Array = range(cols)
        for c in order:
            var small: Image = frames[c]
            if small == null:
                continue
            var feet_x := _torso_center(small)
            var dest := Vector2i(FRAME_W / 2 - feet_x + c * FRAME_W, FRAME_H - 2 - small.get_height() + d * FRAME_H)
            var clip := Rect2i(dest, small.get_size()).intersection(Rect2i(c * FRAME_W, d * FRAME_H, FRAME_W, FRAME_H))
            sheet.blend_rect(small, Rect2i(clip.position - dest, clip.size), clip.position)
            if clip.size != small.get_size():
                warnings.append(_who + ": walk frame %s/%d clipped (%dx%d)" % [dir, c, small.get_width(), small.get_height()])
        # contact = the frames whose feet are furthest apart; stand = narrowest
        var sorted_spreads := spreads.duplicate()
        sorted_spreads.sort()
        var threshold: float = (float(sorted_spreads[0]) + float(sorted_spreads[sorted_spreads.size() - 1])) * 0.5
        var flags: Array = []
        var narrowest := 0
        for c in range(cols):
            flags.append(1 if float(spreads[c]) > threshold and float(spreads[c]) - float(sorted_spreads[0]) >= 3.0 else 0)
            if int(spreads[c]) < int(spreads[narrowest]):
                narrowest = c
        if cols == 3:
            # left step, stand, right step: the drawn order is the gait
            narrowest = 1
            flags = [1, 0, 1]
        if dir in ["left", "right"]:
            side_spread.append(float(sorted_spreads[sorted_spreads.size() - 1]))
        contact.append(flags)
        stand.append(narrowest)
        if d == 0:
            var stand_cell: Dictionary = cells[r * cols + narrowest]
            stand_src_height = float(Rect2i(stand_cell["rect"]).size.y) if not stand_cell.is_empty() else median
            stand_src_head = _head_width(stand_cell["image"]) if not stand_cell.is_empty() else 1
            if frames[narrowest] != null:
                neck = _neck_row(frames[narrowest])
        var top_min := 999
        var top_max := -999
        for t in tops:
            top_min = mini(top_min, int(t))
            top_max = maxi(top_max, int(t))
        audit.append({"dir": dir, "source_row": r, "mirrored": mirrored.get(dir, false), "spread": spreads, "top_rows": tops, "head_jitter": top_max - top_min})
        if top_max - top_min > 8:
            warnings.append(_who + ": walk %s: head top moves %d px between frames" % [dir, top_max - top_min])
    return {"image": sheet, "scale": snappedf(scale, 0.0001), "median_src": median, "contact": contact, "stand": stand, "audit": audit,
        "stand_src_height": stand_src_height, "stand_src_head": stand_src_head, "neck": neck, "stride": _stride(side_spread)}

# Widest opaque run over the top third (the head with its hair).
func _head_width(img: Image) -> int:
    var w := img.get_width()
    var best := 0
    for y in range(0, maxi(1, img.get_height() / 3), 2):
        var lo := w
        var hi := -1
        for x in range(w):
            if img.get_pixel(x, y).a > 0.5:
                lo = mini(lo, x)
                hi = maxi(hi, x)
        if hi >= lo:
            best = maxi(best, hi - lo + 1)
    return best

# Screen distance of one full gait cycle (two steps). A step is about the
# distance between the feet at contact in the side view, minus a foot. The
# actor advances its frames by this distance, so feet do not skate.
func _stride(side_spread: Array) -> int:
    if side_spread.is_empty():
        return 80
    var total := 0.0
    for v in side_spread:
        total += float(v)
    return clampi(int(round(2.0 * (total / side_spread.size() - 16.0))), 56, 112)

func _median_height(cells: Array) -> float:
    var heights: Array = []
    for cell in cells:
        if not Dictionary(cell).is_empty():
            heights.append(float(Rect2i(cell["rect"]).size.y))
    if heights.is_empty():
        return 1.0
    heights.sort()
    var n := heights.size()
    return (float(heights[(n - 1) / 2]) + float(heights[n / 2])) * 0.5

# Width of the feet: the widest opaque run over the bottom 10 rows.
func _leg_spread(img: Image) -> int:
    var w := img.get_width()
    var h := img.get_height()
    var best := 0
    for y in range(maxi(0, h - 10), h):
        var lo := w
        var hi := -1
        for x in range(w):
            if img.get_pixel(x, y).a > 0.5:
                lo = mini(lo, x)
                hi = maxi(hi, x)
        if hi >= lo:
            best = maxi(best, hi - lo + 1)
    return best

# The neck: the narrowest row between 45% and 70% of the figure's height on
# the front standing frame (under the chin, above the shoulders), in frame rows.
func _neck_row(img: Image) -> int:
    var w := img.get_width()
    var h := img.get_height()
    var best_y := int(h * 0.55)
    var best_w := 1 << 20
    for y in range(int(h * 0.42), int(h * 0.62)):
        var count := 0
        for x in range(w):
            if img.get_pixel(x, y).a > 0.5:
                count += 1
        if count < best_w:
            best_w = count
            best_y = y
    return FRAME_H - 2 - h + best_y + 1

func _face(sheet: Image, column: int, _cols: int) -> Image:
    var idle := sheet.get_region(Rect2i(column * FRAME_W, 0, FRAME_W, FRAME_H))
    var used := idle.get_used_rect()
    var head_h := int(used.size.y * 0.5)
    var side := maxi(head_h, int(used.size.x * 0.9))
    var face := idle.get_region(Rect2i(used.position.x + used.size.x / 2 - side / 2, used.position.y, side, head_h))
    face.resize(face.get_width() * 2, face.get_height() * 2, Image.INTERPOLATE_NEAREST)
    return face

# ---------------------------------------------------------------- slicing

func _load(path: String) -> Image:
    if not FileAccess.file_exists(path):
        warnings.append("missing source " + path.get_file())
        return null
    var img := Image.load_from_file(path)
    if img == null or img.is_empty():
        warnings.append("unreadable source " + path.get_file())
        return null
    img.convert(Image.FORMAT_RGBA8)
    var data := img.get_data()
    # drop the soft halo left by background removal
    for i in range(3, data.size(), 4):
        if data[i] < 150:
            data[i] = 0
    return Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, data)

# Rows and columns are cut at the emptiest line near where the grid expects a
# gap (the sheets have uneven margins and frames that sometimes touch).
func _cut_grid(img: Image, cols: int, rows: int, drop_effects: bool) -> Array:
    var w := img.get_width()
    var h := img.get_height()
    var data := img.get_data()
    var row_hist := PackedInt32Array()
    row_hist.resize(h)
    for y in range(h):
        var count := 0
        var base := y * w * 4
        for x in range(0, w, 2):
            if data[base + x * 4 + 3] > 0:
                count += 1
        row_hist[y] = count
    var top := 0
    while top < h - 1 and row_hist[top] == 0:
        top += 1
    var bottom := h - 1
    while bottom > 0 and row_hist[bottom] == 0:
        bottom -= 1
    var row_cuts: Array = [top]
    for k in range(1, rows):
        row_cuts.append(_min_near(row_hist, top + (bottom - top) * k / rows, int((bottom - top) / rows * 0.22), 5))
    row_cuts.append(bottom + 1)
    var result: Array = []
    for r in range(rows):
        var y0 := int(row_cuts[r])
        var y1 := int(row_cuts[r + 1])
        var col_hist := PackedInt32Array()
        col_hist.resize(w)
        for x in range(w):
            var count := 0
            for y in range(y0, y1, 2):
                if data[(y * w + x) * 4 + 3] > 0:
                    count += 1
            col_hist[x] = count
        var left := 0
        while left < w - 1 and col_hist[left] == 0:
            left += 1
        var right := w - 1
        while right > 0 and col_hist[right] == 0:
            right -= 1
        var col_cuts: Array = [left]
        for k in range(1, cols):
            col_cuts.append(_min_near(col_hist, left + (right - left) * k / cols, int((right - left) / cols * 0.22), 4))
        col_cuts.append(right + 1)
        for c in range(cols):
            var cell := Rect2i(int(col_cuts[c]), y0, int(col_cuts[c + 1]) - int(col_cuts[c]), y1 - y0)
            result.append(_extract(img, cell, drop_effects))
    return result

func _min_near(hist: PackedInt32Array, expected: int, radius: int, smooth: int) -> int:
    var best := expected
    var best_value := 1 << 30
    for y in range(maxi(0, expected - radius), mini(hist.size(), expected + radius)):
        var total := 0
        for d in range(-smooth, smooth + 1):
            total += hist[clampi(y + d, 0, hist.size() - 1)]
        if total < best_value or (total == best_value and absi(y - expected) < absi(best - expected)):
            best_value = total
            best = y
    return best

# The character's own pixels inside a cell: the largest connected region plus
# other sizeable pieces (a hand, a strand of hair). For drawn action cells,
# pieces outside the figure's own box (a "!" mark, sparkles, speed lines, a
# floating hologram) are dropped: the game draws its own speech marks.
func _extract(img: Image, cell: Rect2i, drop_effects: bool) -> Dictionary:
    var region := img.get_region(cell)
    var w := region.get_width()
    var h := region.get_height()
    var data := region.get_data()
    var labels := PackedInt32Array()
    labels.resize(w * h)
    var sizes: Array = [0]
    var boxes: Array = [Rect2i()]
    var next := 1
    for start in range(w * h):
        if labels[start] != 0 or data[start * 4 + 3] == 0:
            continue
        var stack: Array = [start]
        labels[start] = next
        var size := 0
        var min_x := w
        var min_y := h
        var max_x := 0
        var max_y := 0
        while not stack.is_empty():
            var p: int = stack.pop_back()
            size += 1
            var px := p % w
            var py := p / w
            min_x = mini(min_x, px)
            min_y = mini(min_y, py)
            max_x = maxi(max_x, px)
            max_y = maxi(max_y, py)
            for d in [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [-1, -1], [1, -1], [-1, 1]]:
                var nx: int = px + d[0]
                var ny: int = py + d[1]
                if nx < 0 or ny < 0 or nx >= w or ny >= h:
                    continue
                var q := ny * w + nx
                if labels[q] == 0 and data[q * 4 + 3] > 0:
                    labels[q] = next
                    stack.append(q)
        sizes.append(size)
        boxes.append(Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1))
        next += 1
    if next == 1:
        return {}
    var largest := 1
    for i in range(1, sizes.size()):
        if int(sizes[i]) > int(sizes[largest]):
            largest = i
    var main_box: Rect2i = boxes[largest]
    var keep := {}
    for i in range(1, sizes.size()):
        if i == largest:
            keep[i] = true
        elif drop_effects:
            var b: Rect2i = boxes[i]
            if int(sizes[i]) >= 60 and main_box.encloses(b):
                keep[i] = true
        elif int(sizes[i]) >= maxi(150, int(sizes[largest]) / 60):
            keep[i] = true
    var min_x := w
    var min_y := h
    var max_x := -1
    var max_y := -1
    for p in range(w * h):
        if labels[p] == 0:
            continue
        if not keep.has(labels[p]):
            data[p * 4 + 3] = 0
            continue
        var px := p % w
        var py := p / w
        min_x = mini(min_x, px)
        min_y = mini(min_y, py)
        max_x = maxi(max_x, px)
        max_y = maxi(max_y, py)
    var cleaned := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)
    var rect := Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
    return {"image": cleaned.get_region(rect), "rect": Rect2i(cell.position + rect.position, rect.size)}

# Premultiplied Lanczos shrink, so transparent pixels do not bleed dark or
# white into the edge.
func _shrink(img: Image, scale: float) -> Image:
    var w := img.get_width()
    var h := img.get_height()
    var data := img.get_data()
    for i in range(0, data.size(), 4):
        var a := data[i + 3]
        data[i] = data[i] * a / 255
        data[i + 1] = data[i + 1] * a / 255
        data[i + 2] = data[i + 2] * a / 255
    var pre := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)
    pre.resize(maxi(1, int(round(w * scale))), maxi(1, int(round(h * scale))), Image.INTERPOLATE_LANCZOS)
    var out := pre.get_data()
    for i in range(0, out.size(), 4):
        var a := out[i + 3]
        if a > 0:
            out[i] = mini(255, out[i] * 255 / a)
            out[i + 1] = mini(255, out[i + 1] * 255 / a)
            out[i + 2] = mini(255, out[i + 2] * 255 / a)
    return Image.create_from_data(pre.get_width(), pre.get_height(), false, Image.FORMAT_RGBA8, out)

# Hard alpha; the outermost ring is re-coloured from the figure's own interior
# (darkened), which removes red/magenta background-removal fringes.
func _harden_and_outline(img: Image) -> void:
    var w := img.get_width()
    var h := img.get_height()
    var data := img.get_data()
    for i in range(3, data.size(), 4):
        data[i] = 255 if data[i] >= 128 else 0
    var source := data.duplicate()
    for y in range(h):
        for x in range(w):
            var p := (y * w + x) * 4
            if source[p + 3] == 0:
                continue
            var edge := false
            for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
                var nx: int = x + d[0]
                var ny: int = y + d[1]
                if nx < 0 or ny < 0 or nx >= w or ny >= h or source[(ny * w + nx) * 4 + 3] == 0:
                    edge = true
                    break
            if not edge:
                continue
            var r := 0
            var g := 0
            var b := 0
            var n := 0
            for dy in range(-2, 3):
                for dx in range(-2, 3):
                    var nx := x + dx
                    var ny := y + dy
                    if nx < 0 or ny < 0 or nx >= w or ny >= h:
                        continue
                    var q := (ny * w + nx) * 4
                    if source[q + 3] == 0:
                        continue
                    var interior := true
                    for d2 in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
                        var mx: int = nx + d2[0]
                        var my: int = ny + d2[1]
                        if mx < 0 or my < 0 or mx >= w or my >= h or source[(my * w + mx) * 4 + 3] == 0:
                            interior = false
                            break
                    if interior:
                        r += source[q]
                        g += source[q + 1]
                        b += source[q + 2]
                        n += 1
            if n == 0:
                r = source[p]
                g = source[p + 1]
                b = source[p + 2]
                n = 1
            data[p] = int(r / n * 0.45)
            data[p + 1] = int(g / n * 0.45)
            data[p + 2] = int(b / n * 0.5)
    img.set_data(w, h, false, Image.FORMAT_RGBA8, data)

# Horizontal anchor: the middle of the lower third (legs and feet), not the
# whole frame, so flaring hair or a coat tail does not make a walk jitter.
func _feet_center(img: Image) -> int:
    var w := img.get_width()
    var h := img.get_height()
    var total := 0
    var count := 0
    for y in range(h * 2 / 3, h):
        for x in range(w):
            if img.get_pixel(x, y).a > 0.5:
                total += x
                count += 1
    return total / count if count > 0 else w / 2

# ---------------------------------------------------------------- runtime data

func _write_runtime(path: String) -> void:
    var keys := runtime.keys()
    keys.sort()
    var text := "class_name AstraPixelManifest\nextends RefCounted\n\n# Generated by tools/import_pixel_090.gd - do not edit by hand.\n"
    text += "# walk: sheet (frames x 4 rows: down, up, left, right); contact: frames with the\n"
    text += "# feet apart per direction; stand: the frame used for standing per direction;\n"
    text += "# neck: head band row for the motion shader; poses: drawn pose cells (%dx%d).\n\n" % [POSE_W, POSE_H]
    text += "const FRAME_SIZE := Vector2i(%d, %d)\n" % [FRAME_W, FRAME_H]
    text += "const POSE_SIZE := Vector2i(%d, %d)\n" % [POSE_W, POSE_H]
    text += "const SHEETS := {\n"
    for i in range(keys.size()):
        text += "    \"%s\": %s%s\n" % [keys[i], JSON.stringify(runtime[keys[i]]), "," if i < keys.size() - 1 else ""]
    text += "}\n\nstatic func sheet(key: String) -> Dictionary:\n    return SHEETS.get(key, {})\n"
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string(text)
    file.close()

# Horizontal anchor for walking frames: the torso and hips (50-78% of the
# figure's height). In a walk the body travels steadily while the feet swing
# and plant around it, so anchoring the feet makes the body jump sideways;
# the head is left out because hair flares.
func _torso_center(img: Image) -> int:
    var w := img.get_width()
    var h := img.get_height()
    var total := 0
    var count := 0
    for y in range(int(h * 0.5), int(h * 0.78)):
        for x in range(w):
            if img.get_pixel(x, y).a > 0.5:
                total += x
                count += 1
    return total / count if count > 0 else w / 2
