extends SceneTree

# Explorer artwork (0.9.0), built from the user's drawings only. Sources are
# never modified; images are cropped and uniformly scaled, never stretched.
#
#   godot --headless --path . --script res://tools/import_explorers_090.gd
#
# Sources (<art root> = ../인물 이미지/Astra, or --art=<dir>):
#   플레이어/<이름>.png     one full-body drawing per explorer
#   플레이어/ChatGPT 이미지 ... 05_41_43-1..46-4.png
#                           four expression sheets, 3 x 2 busts each, always in
#                           the order 라엘 로건 미카 / 세린 시아 제이스
# Output: assets/explorers/<id>/full.webp, head.webp, bust_1..bust_4.webp
#         assets/explorers/manifest.json

const ORDER_ON_SHEETS := ["rael", "logan", "mika", "serin", "sia", "jace"]
const NAMES := {"serin": "세린", "mika": "미카", "jace": "제이스", "rael": "라엘", "logan": "로건", "sia": "시아"}
const SHEETS := [
    "ChatGPT 이미지 2026년 9월 25일 오후 05_41_43-1.png",
    "ChatGPT 이미지 2026년 9월 25일 오후 05_41_44-2.png",
    "ChatGPT 이미지 2026년 9월 25일 오후 05_41_45-3.png",
    "ChatGPT 이미지 2026년 9월 25일 오후 05_41_46-4.png",
]
const FULL_HEIGHT := 1024
const BUST_ASPECT := 0.78
const BUST_WIDTH := 420
const HEAD_SIZE := 256

var out_root := "res://assets/explorers/"
var manifest := {}

func _initialize() -> void:
    var root := ProjectSettings.globalize_path("res://")
    var art_root := root.path_join("../인물 이미지/Astra")
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--art="):
            art_root = arg.substr(6)
        elif arg.begins_with("--out="):
            out_root = arg.substr(6).trim_suffix("/") + "/"
    var players := art_root.path_join("플레이어")
    for id in NAMES:
        var src := _load(players.path_join(NAMES[id] + ".png"))
        if src == null:
            push_error("missing full-body drawing for " + id)
            continue
        var full := _figure(src, 0.02)
        var scale := float(FULL_HEIGHT) / float(full.get_height())
        full.resize(maxi(1, int(round(full.get_width() * scale))), FULL_HEIGHT, Image.INTERPOLATE_LANCZOS)
        full = _defringe(full)
        _save(full, id + "/full")
        manifest[id] = {"full": NAMES[id] + ".png", "full_size": [full.get_width(), full.get_height()], "busts": []}
    for s in range(SHEETS.size()):
        var sheet := _load(players.path_join(SHEETS[s]))
        if sheet == null:
            push_error("missing expression sheet " + SHEETS[s])
            continue
        var cw := sheet.get_width() / 3
        var ch := sheet.get_height() / 2
        for i in range(6):
            var id: String = ORDER_ON_SHEETS[i]
            var cell := sheet.get_region(Rect2i((i % 3) * cw, (i / 3) * ch, cw, ch))
            var bust := _defringe(_figure(cell, 0.05, true))
            var framed := _frame_bust(bust)
            framed.resize(BUST_WIDTH, int(round(BUST_WIDTH / BUST_ASPECT)), Image.INTERPOLATE_LANCZOS)
            _save(framed, "%s/bust_%d" % [id, s + 1])
            if manifest.has(id):
                manifest[id]["busts"].append(SHEETS[s])
            if s == 0:
                _save(_head(bust), id + "/head")
    var file := FileAccess.open(ProjectSettings.globalize_path(out_root) + "manifest.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(manifest, "  "))
    file.close()
    print("ASTRA EXPLORER ART OK · %d explorers" % manifest.size())
    quit()

func _load(path: String) -> Image:
    if not FileAccess.file_exists(path):
        return null
    var img := Image.load_from_file(path)
    if img == null or img.is_empty():
        return null
    img.convert(Image.FORMAT_RGBA8)
    return img

# The figure on a transparent image: the largest solid region plus pieces that
# belong to it (a drone, a hologram cube, a helmet) — anything at least
# `min_share` of the figure. The soft background glow and stray specks go.
func _figure(img: Image, min_share: float, cell_edges: bool = false) -> Image:
    var w := img.get_width()
    var h := img.get_height()
    var data := img.get_data()
    var solid := PackedByteArray()
    solid.resize(w * h)
    for i in range(w * h):
        solid[i] = 1 if data[i * 4 + 3] >= 110 else 0
    var labels := PackedInt32Array()
    labels.resize(w * h)
    var sizes: Array = [0]
    var boxes: Array = [Rect2i()]
    var next := 1
    for start in range(w * h):
        if labels[start] != 0 or solid[start] == 0:
            continue
        var stack := PackedInt32Array([start])
        labels[start] = next
        var size := 0
        var x0 := w
        var y0 := h
        var x1 := 0
        var y1 := 0
        while stack.size() > 0:
            var p := stack[stack.size() - 1]
            stack.resize(stack.size() - 1)
            size += 1
            var px := p % w
            var py := p / w
            x0 = mini(x0, px)
            y0 = mini(y0, py)
            x1 = maxi(x1, px)
            y1 = maxi(y1, py)
            for d in [-1, 1, -w, w]:
                var q: int = p + d
                if q < 0 or q >= w * h or (absi(d) == 1 and q / w != py):
                    continue
                if labels[q] == 0 and solid[q] == 1:
                    labels[q] = next
                    stack.append(q)
        sizes.append(size)
        boxes.append(Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1))
        next += 1
    var largest := 1
    for i in range(1, sizes.size()):
        if int(sizes[i]) > int(sizes[largest]):
            largest = i
    var keep := {}
    var box: Rect2i = boxes[largest]
    for i in range(1, sizes.size()):
        var b: Rect2i = boxes[i]
        # On an expression sheet a piece touching the left or right edge of the
        # cell belongs to the neighbouring bust (a hologram, a raised hand).
        var neighbour := cell_edges and (b.position.x <= 1 or b.end.x >= w - 1)
        if i == largest or (not neighbour and int(sizes[i]) >= int(float(sizes[largest]) * min_share)):
            keep[i] = true
            box = box.merge(boxes[i])
    # Soft edge pixels (below the solid threshold) stay when they touch a kept
    # region, so anti-aliased outlines are not cut.
    var out := PackedByteArray()
    out.resize(data.size())
    for i in range(w * h):
        var lab := labels[i]
        var ok := lab != 0 and keep.has(lab)
        if not ok and lab == 0 and data[i * 4 + 3] > 0:
            var x := i % w
            var y := i / w
            for d in [[1, 0], [-1, 0], [0, 1], [0, -1], [2, 0], [-2, 0], [0, 2], [0, -2]]:
                var nx: int = x + d[0]
                var ny: int = y + d[1]
                if nx >= 0 and ny >= 0 and nx < w and ny < h and keep.has(labels[ny * w + nx]):
                    ok = true
                    break
        if ok:
            for k in range(4):
                out[i * 4 + k] = data[i * 4 + k]
    var cleaned := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, out)
    return cleaned.get_region(box.grow(2).intersection(Rect2i(0, 0, w, h)))

# Busts are cut flat at the bottom of the sheet cell. Keep that edge on the
# frame bottom and pad to the shared bust aspect.
func _frame_bust(img: Image) -> Image:
    var w := img.get_width()
    var h := img.get_height()
    var target_w := maxi(w, int(round(h * BUST_ASPECT)))
    var target_h := maxi(h, int(round(target_w / BUST_ASPECT)))
    var canvas := Image.create(target_w, target_h, false, Image.FORMAT_RGBA8)
    canvas.fill(Color(0, 0, 0, 0))
    canvas.blit_rect(img, Rect2i(0, 0, w, h), Vector2i((target_w - w) / 2, target_h - h))
    return canvas

# A square around the head: centred on the figure's upper part, from just
# above the top of the hair.
func _head(img: Image) -> Image:
    var w := img.get_width()
    var h := img.get_height()
    var top := 0
    var found := false
    for y in range(h):
        for x in range(0, w, 2):
            if img.get_pixel(x, y).a > 0.5:
                top = y
                found = true
                break
        if found:
            break
    var side := int(h * 0.62)
    var sx := 0.0
    var n := 0
    for y in range(top, mini(h, top + side * 3 / 4), 3):
        for x in range(0, w, 3):
            if img.get_pixel(x, y).a > 0.5:
                sx += x
                n += 1
    var cx := int(sx / n) if n > 0 else w / 2
    var region := Rect2i(cx - side / 2, maxi(0, top - side / 16), side, side)
    var canvas := Image.create(side, side, false, Image.FORMAT_RGBA8)
    canvas.fill(Color(0, 0, 0, 0))
    var clip := region.intersection(Rect2i(0, 0, w, h))
    canvas.blit_rect(img, clip, clip.position - region.position)
    canvas.resize(HEAD_SIZE, HEAD_SIZE, Image.INTERPOLATE_LANCZOS)
    return canvas

# Semi-transparent edge pixels take the colour of the nearest solid pixel, so
# the dark or coloured glow of the background removal does not ring the figure.
func _defringe(src: Image) -> Image:
    var img: Image = src.duplicate()
    var w := img.get_width()
    var h := img.get_height()
    var data := img.get_data()
    var n := w * h
    var has := PackedByteArray()
    has.resize(n)
    var col := PackedFloat32Array()
    col.resize(n * 3)
    for i in range(n):
        if data[i * 4 + 3] >= 240:
            has[i] = 1
            col[i * 3] = data[i * 4]
            col[i * 3 + 1] = data[i * 4 + 1]
            col[i * 3 + 2] = data[i * 4 + 2]
    for _pass in range(4):
        var grown := PackedInt32Array()
        var values := PackedFloat32Array()
        for i in range(n):
            if has[i] == 1 or data[i * 4 + 3] == 0:
                continue
            var x := i % w
            var y := i / w
            var t := [0.0, 0.0, 0.0]
            var count := 0
            for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
                var nx: int = x + d[0]
                var ny: int = y + d[1]
                if nx < 0 or ny < 0 or nx >= w or ny >= h:
                    continue
                var q := ny * w + nx
                if has[q] == 1:
                    t[0] += col[q * 3]
                    t[1] += col[q * 3 + 1]
                    t[2] += col[q * 3 + 2]
                    count += 1
            if count > 0:
                grown.append(i)
                values.append(t[0] / count)
                values.append(t[1] / count)
                values.append(t[2] / count)
        if grown.is_empty():
            break
        for k in range(grown.size()):
            var i := grown[k]
            has[i] = 1
            col[i * 3] = values[k * 3]
            col[i * 3 + 1] = values[k * 3 + 1]
            col[i * 3 + 2] = values[k * 3 + 2]
    for i in range(n):
        var a := data[i * 4 + 3]
        if a == 0 or a >= 240:
            continue
        if has[i] == 0 or a < 40:
            data[i * 4 + 3] = 0
            continue
        data[i * 4] = int(col[i * 3])
        data[i * 4 + 1] = int(col[i * 3 + 1])
        data[i * 4 + 2] = int(col[i * 3 + 2])
    return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)

func _save(img: Image, rel: String) -> void:
    var path := ProjectSettings.globalize_path(out_root + rel + ".webp")
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    img.save_webp(path, true, 0.9)
