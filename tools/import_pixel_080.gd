extends SceneTree

# Normalises the walking sheets (3 frames x 4 directions: down, up, left, right)
# into runtime sprite sheets. The sources are never modified.
#
#   godot --headless --path . --script res://tools/import_pixel_080.gd
#
# Sources
#   crew   : ../0.5.0 수정 인물 이미지/Astra/미니 도트 캐릭/<한글 이름>.png
#   player : assets/player_src/<preset>.png (project, preferred) or
#            ../0.5.0 수정 인물 이미지/Astra/임시/*.png (temporary sheets, in name order)
#   actions (optional, drawn poses; layout in docs/PIXEL_ACTIONS_080.md):
#            ../0.5.0 수정 인물 이미지/Astra/미니 도트 캐릭/액션/<한글 이름>.png
#            <player source>_action.png (next to the player sheet)
# Output
#   assets/pixel080/crew/<id>.png, assets/pixel080/player/<preset>.png,
#   assets/pixel080/player/<preset>_face.png, assets/pixel080/manifest.json
#   <sheet>_action.png when an action source exists (same frame size, and the
#   walking sheet's scale, so a person is the same size in every pose)
#
# The sheets are 1254x1254 with uneven margins and frames that sometimes touch,
# so they are not cut into a uniform 3x4 grid. Rows and columns are cut at the
# emptiest line near where the grid expects a gap; inside each cell only the
# character's own connected pixels are kept. Every frame of a character uses
# one scale (by overall visual height), and is anchored by its feet.
# Edges: soft background-removal halo is dropped, alpha is made hard, and the
# outermost ring of pixels is re-coloured from the character's own interior
# (darkened), which removes red/magenta fringes without touching the inside.

const FRAME_W := 96
const FRAME_H := 128
const TARGET_HEIGHT := 112.0
const CREW := {"노아": "noa", "다렌": "dax", "루칸": "eli", "마렌": "lyra", "미라": "mira", "세나": "sena", "소렌": "vale", "준": "rho"}
const DIRECTIONS := ["down", "up", "left", "right"]

var manifest := {"frame_w": FRAME_W, "frame_h": FRAME_H, "directions": DIRECTIONS, "frames_per_direction": 3, "crew": {}, "player": {}}

func _initialize() -> void:
    var root := ProjectSettings.globalize_path("res://")
    var art_root := root.path_join("../0.5.0 수정 인물 이미지/Astra")
    var out_root := root.path_join("assets/pixel080")
    var player_src := root.path_join("assets/player_src")
    # --art=<dir> --out=<dir> --players=<dir>: convert elsewhere (tests)
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--art="):
            art_root = arg.substr(6)
        elif arg.begins_with("--out="):
            out_root = arg.substr(6)
        elif arg.begins_with("--players="):
            player_src = arg.substr(10)
    DirAccess.make_dir_recursive_absolute(out_root.path_join("crew"))
    DirAccess.make_dir_recursive_absolute(out_root.path_join("player"))
    for name in CREW:
        var src := art_root.path_join("미니 도트 캐릭/%s.png" % name)
        var info := _convert(src, out_root.path_join("crew/%s.png" % CREW[name]), "")
        if not info.is_empty():
            manifest["crew"][CREW[name]] = info
            var action_src := art_root.path_join("미니 도트 캐릭/액션/%s.png" % name)
            if FileAccess.file_exists(action_src):
                var action := _convert(action_src, out_root.path_join("crew/%s_action.png" % CREW[name]), "", float(info["scale"]))
                if not action.is_empty():
                    info["action"] = action
    var player_sources := _player_sources(player_src, art_root)
    for index in range(player_sources.size()):
        var preset := "p%d" % (index + 1)
        var info := _convert(str(player_sources[index]), out_root.path_join("player/%s.png" % preset), out_root.path_join("player/%s_face.png" % preset))
        if not info.is_empty():
            manifest["player"][preset] = info
            var action_src := str(player_sources[index]).get_basename() + "_action.png"
            if FileAccess.file_exists(action_src):
                var action := _convert(action_src, out_root.path_join("player/%s_action.png" % preset), "", float(info["scale"]))
                if not action.is_empty():
                    info["action"] = action
    var file := FileAccess.open(out_root.path_join("manifest.json"), FileAccess.WRITE)
    file.store_string(JSON.stringify(manifest, "  "))
    file.close()
    print("ASTRA PIXEL IMPORT OK · crew %d · player %d" % [manifest["crew"].size(), manifest["player"].size()])
    quit()

func _player_sources(player_src: String, art_root: String) -> Array:
    var result: Array = []
    for dir_path in [player_src, art_root.path_join("임시")]:
        var dir := DirAccess.open(dir_path)
        if dir == null:
            continue
        var names: Array = []
        for file_name in dir.get_files():
            var lower := file_name.to_lower()
            if lower.ends_with(".png") and not lower.ends_with("_face.png") and not lower.ends_with("_action.png"):
                names.append(file_name)
        names.sort()
        for file_name in names:
            result.append(dir_path.path_join(str(file_name)))
        if not result.is_empty():
            break
    return result

func _convert(src: String, out_path: String, face_path: String, fixed_scale: float = 0.0) -> Dictionary:
    var img := Image.load_from_file(src)
    if img == null or img.is_empty():
        push_warning("pixel import: cannot read " + src)
        return {}
    img.convert(Image.FORMAT_RGBA8)
    var w := img.get_width()
    var h := img.get_height()
    var data := img.get_data()
    # 1. drop the soft halo left by background removal
    for i in range(3, data.size(), 4):
        if data[i] < 150:
            data[i] = 0
    var clean := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)
    # 2. rows: emptiest line near each expected gap
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
    for k in range(1, 4):
        var expected := top + (bottom - top) * k / 4
        row_cuts.append(_min_near(row_hist, expected, 70, 5))
    row_cuts.append(bottom + 1)
    var frames: Array = []
    var heights: Array = []
    for r in range(4):
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
        for k in range(1, 3):
            col_cuts.append(_min_near(col_hist, left + (right - left) * k / 3, 60, 4))
        col_cuts.append(right + 1)
        for c in range(3):
            var cell := Rect2i(int(col_cuts[c]), y0, int(col_cuts[c + 1]) - int(col_cuts[c]), y1 - y0)
            var frame := _extract(clean, cell)
            frames.append(frame)
            if not frame.is_empty():
                heights.append(float(Rect2i(frame["rect"]).size.y))
    if frames.size() != 12 or heights.size() != 12:
        push_warning("pixel import: %s gave %d frames" % [src, heights.size()])
        return {}
    heights.sort()
    var median := (float(heights[5]) + float(heights[6])) * 0.5
    var scale := fixed_scale if fixed_scale > 0.0 else TARGET_HEIGHT / maxf(1.0, median)
    var sheet := Image.create(FRAME_W * 3, FRAME_H * 4, false, Image.FORMAT_RGBA8)
    var rects: Array = []
    for index in range(12):
        var frame: Dictionary = frames[index]
        var small := _shrink(frame["image"], scale)
        _harden_and_outline(small)
        var feet_x := _feet_center(small)
        var dest := Vector2i(FRAME_W / 2 - feet_x + (index % 3) * FRAME_W, FRAME_H - 2 - small.get_height() + (index / 3) * FRAME_H)
        var clip := Rect2i(dest, small.get_size()).intersection(Rect2i((index % 3) * FRAME_W, (index / 3) * FRAME_H, FRAME_W, FRAME_H))
        sheet.blend_rect(small, Rect2i(clip.position - dest, clip.size), clip.position)
        rects.append([Rect2i(frame["rect"]).position.x, Rect2i(frame["rect"]).position.y, Rect2i(frame["rect"]).size.x, Rect2i(frame["rect"]).size.y])
    sheet.save_png(out_path)
    if face_path != "":
        var idle := sheet.get_region(Rect2i(FRAME_W, 0, FRAME_W, FRAME_H))
        var used := idle.get_used_rect()
        var head_h := int(used.size.y * 0.5)
        var side := maxi(head_h, int(used.size.x * 0.9))
        var face := idle.get_region(Rect2i(used.position.x + used.size.x / 2 - side / 2, used.position.y, side, head_h))
        face.resize(face.get_width() * 2, face.get_height() * 2, Image.INTERPOLATE_NEAREST)
        face.save_png(face_path)
    return {"source": src.get_file(), "scale": snappedf(scale, 0.0001), "median_height": median, "frames": rects}

func _min_near(hist: PackedInt32Array, expected: int, radius: int, smooth: int) -> int:
    var best := expected
    var best_value := 1 << 30
    for y in range(maxi(0, expected - radius), mini(hist.size(), expected + radius)):
        var total := 0
        for d in range(-smooth, smooth + 1):
            total += hist[clampi(y + d, 0, hist.size() - 1)]
        if total < best_value:
            best_value = total
            best = y
    return best

# The character's own pixels inside a cell: the largest connected region plus
# any other sizeable piece (a hand, a strand of hair); specks are dropped.
func _extract(img: Image, cell: Rect2i) -> Dictionary:
    var region := img.get_region(cell)
    var w := region.get_width()
    var h := region.get_height()
    var data := region.get_data()
    var labels := PackedInt32Array()
    labels.resize(w * h)
    var sizes: Array = [0]
    var next := 1
    for start in range(w * h):
        if labels[start] != 0 or data[start * 4 + 3] == 0:
            continue
        var stack: Array = [start]
        labels[start] = next
        var size := 0
        while not stack.is_empty():
            var p: int = stack.pop_back()
            size += 1
            var px := p % w
            var py := p / w
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
        next += 1
    if next == 1:
        return {}
    var largest := 1
    for i in range(1, sizes.size()):
        if int(sizes[i]) > int(sizes[largest]):
            largest = i
    var keep := {}
    for i in range(1, sizes.size()):
        if i == largest or int(sizes[i]) >= maxi(150, int(sizes[largest]) / 60):
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
            # the average of the interior pixels around it, darkened
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
