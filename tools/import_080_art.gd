extends SceneTree
# ASTRA 0.8.0 character art rebuild. Reproducible; source originals are never
# modified. Run from the project root:
#   godot --headless --path . --script res://tools/import_080_art.gd
#
# What it does and why:
#   * Sena and Maren were redesigned. Their cast / portrait / head / expression
#     set is rebuilt from the new single-pose, background-removed renders.
#   * Soren, Lucan and Daren expression crops are re-cut. The 0.5.0 importer
#     (tools/import_050.gd) cut every sheet on a fixed grid and then flood-filled
#     near-white pixels from the crop border. The sheets were already
#     transparent, so the flood fill ate white jackets (holes), Soren's 3x2
#     sheet was cut on a 4x2 grid (sliced faces), and Daren's labelled sheet
#     leaked caption plates into the crops. 0.8.0 slices sheets by alpha
#     connected components instead, so caption plates and "!" marks (separate
#     components) are dropped and clothing is never erased.
#   * Mira's head icon was off-centre; heads are now cut around the detected
#     face for every rebuilt character.
#   * Every rebuilt image goes through defringe(): semi-transparent edge pixels
#     take the colour of the nearest solid pixel and lose alpha in proportion to
#     how much of the old light background they still carry. This removes the
#     white halo / residue left between hair strands by the background removal.
# Images are only cropped and uniformly scaled. Aspect ratios are never changed.

const SRC := "res://../0.5.0 수정 인물 이미지/Astra/"
const OUT := "res://assets/art050/"
const MOODS := ["neutral","smile","happy","suspicious","annoyed","embarrassed","shocked","sad","angry","determined","afraid","tired"]

# New single-pose renders. The "ChatGPT ... -Photoroom" cut of each Sena pose is
# used; the sena_transparent_* cut of the same pose keeps a white residue in the
# gaps between hair strands (measured ~10x more light semi-transparent pixels).
const SENA := {
    "main": "세나/ChatGPT Image 2026년 9월 24일 오전 12_17_18 (3)-Photoroom.png",
    "moods": {
        "neutral": "세나/ChatGPT Image 2026년 9월 24일 오전 12_17_18 (3)-Photoroom.png",
        "smile": "세나/ChatGPT Image 2026년 9월 24일 오전 12_17_08 (1)-Photoroom.png",
        "happy": "세나/ChatGPT Image 2026년 9월 24일 오전 12_17_09 (2)-Photoroom.png",
        "suspicious": "세나/ChatGPT Image 2026년 9월 24일 오전 12_17_23 (8)-Photoroom.png",
        "annoyed": "세나/ChatGPT Image 2026년 9월 24일 오전 12_17_21 (5)-Photoroom.png",
        "embarrassed": "세나/ChatGPT Image 2026년 9월 24일 오전 12_17_25 (10)-Photoroom.png",
        "shocked": "세나/ChatGPT Image 2026년 9월 24일 오전 12_17_22 (7)-Photoroom.png",
        "sad": "세나/ChatGPT Image 2026년 9월 24일 오전 12_17_24 (9)-Photoroom.png",
        "angry": "세나/ChatGPT Image 2026년 9월 24일 오전 12_17_21 (5)-Photoroom.png",
        "determined": "세나/ChatGPT Image 2026년 9월 24일 오전 12_17_20 (4)-Photoroom.png",
        "afraid": "세나/ChatGPT Image 2026년 9월 24일 오전 12_17_21 (6)-Photoroom.png",
        "tired": "세나/ChatGPT Image 2026년 9월 24일 오전 12_17_24 (9)-Photoroom.png"
    }
}
const MAREN := {
    "main": "마렌/ChatGPT Image 2026년 9월 24일 오전 12_07_51 (2).png",
    "moods": {
        "neutral": "마렌/ChatGPT Image 2026년 9월 24일 오전 12_07_51 (2).png",
        "smile": "마렌/ChatGPT Image 2026년 9월 23일 오후 11_47_59 (3).png",
        "happy": "마렌/ChatGPT Image 2026년 9월 23일 오후 11_48_01 (5).png",
        "suspicious": "마렌/ChatGPT Image 2026년 9월 23일 오후 11_48_00 (4).png",
        "annoyed": "마렌/ChatGPT Image 2026년 9월 24일 오전 12_07_52 (3).png",
        "embarrassed": "마렌/ChatGPT Image 2026년 9월 23일 오후 11_47_58 (1).png",
        "shocked": "마렌/ChatGPT Image 2026년 9월 23일 오후 11_48_02 (6).png",
        "sad": "마렌/ChatGPT Image 2026년 9월 23일 오후 11_48_03 (7).png",
        "angry": "마렌/ChatGPT Image 2026년 9월 23일 오후 11_48_03 (7).png",
        "determined": "마렌/ChatGPT Image 2026년 9월 23일 오후 11_48_03 (7).png",
        "afraid": "마렌/ChatGPT Image 2026년 9월 24일 오전 12_07_56 (5).png",
        "tired": "마렌/ChatGPT Image 2026년 9월 23일 오후 11_48_03 (7).png"
    }
}

# Expression sheets sliced by connected component. Each entry is
# [sheet file, component index in reading order].
const SHEET_MOODS := {
    "soren": {
        "A": "소렌/ChatGPT Image 2026년 9월 19일 오후 06_10_44 (2).png", "A_grid": [4, 4],
        "B": "소렌/ChatGPT Image 2026년 9월 19일 오후 06_17_43.png", "B_grid": [3, 3],
        "moods": {"neutral":["B",0], "smile":["B",1], "happy":["A",1], "suspicious":["A",3], "annoyed":["A",2],
            "embarrassed":["A",4], "shocked":["B",3], "sad":["A",6], "angry":["B",5], "determined":["A",7],
            "afraid":["A",5], "tired":["B",4]}
    },
    "lucan": {
        "A": "루칸/ChatGPT Image 2026년 9월 19일 오후 06_22_41.png", "A_grid": [3, 3],
        "B": "루칸/ChatGPT Image 2026년 9월 19일 오후 06_26_27.png", "B_grid": [3, 3],
        "moods": {"neutral":["A",0], "smile":["B",0], "happy":["B",1], "suspicious":["A",3], "annoyed":["A",2],
            "embarrassed":["B",2], "shocked":["A",4], "sad":["B",4], "angry":["A",3], "determined":["B",5],
            "afraid":["B",3], "tired":["A",5]}
    },
    "daren": {
        "A": "다렌/ChatGPT Image 2026년 9월 19일 오후 06_04_30 (1).png", "A_grid": [4, 4],
        "B": "다렌/ChatGPT Image 2026년 9월 19일 오후 06_04_30 (2).png", "B_grid": [4, 5], "B_trim": 0.16,
        "moods": {"neutral":["A",0], "smile":["B",7], "happy":["A",6], "suspicious":["B",0], "annoyed":["B",1],
            "embarrassed":["B",2], "shocked":["A",3], "sad":["B",4], "angry":["B",5], "determined":["B",6],
            "afraid":["B",2], "tired":["A",4]}
    }
}

# Full-body mains whose head icon is re-cut around the detected face.
const HEAD_ONLY := {"mira":"미라/미라.png"}

const BUST_ASPECT := 0.78
var manifest := {}

func _initialize() -> void:
    _build_full("sena", SENA)
    _build_full("maren", MAREN)
    for id in SHEET_MOODS:
        _build_sheet_moods(id, SHEET_MOODS[id])
    for id in HEAD_ONLY:
        var img := _load(str(HEAD_ONLY[id]))
        _save(_head_crop(img), "heads/" + id, Vector2i(256,256))
        manifest[id] = {"head_source": str(HEAD_ONLY[id])}
    var file := FileAccess.open(OUT + "manifest_080.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(manifest, "  "))
    print("ASTRA 080 ART OK")
    quit()

func _load(relative: String) -> Image:
    var path := ProjectSettings.globalize_path(SRC + relative)
    var img := Image.load_from_file(path)
    if img == null:
        push_error("missing art source " + path)
        return Image.create(8, 8, false, Image.FORMAT_RGBA8)
    img.convert(Image.FORMAT_RGBA8)
    return img

func _build_full(id: String, spec: Dictionary) -> void:
    var main := _defringe(_load(str(spec["main"])))
    _save(main, "cast/" + id, Vector2i(683,1024))
    _save(main.get_region(Rect2i(120,0,804,960)), "portraits/" + id, Vector2i(536,640))
    _save(_head_crop(main), "heads/" + id, Vector2i(256,256))
    var entry := {"main": str(spec["main"]), "expressions": {}}
    var cache := {}
    for mood in MOODS:
        var rel := str(spec["moods"][mood])
        if not cache.has(rel):
            cache[rel] = _defringe(_load(rel))
        var img: Image = cache[rel]
        var bust := _bust_crop(img)
        _save(bust, "expressions/%s/%s" % [id, mood], Vector2i(420, int(round(420 / BUST_ASPECT))))
        entry["expressions"][mood] = rel
    manifest[id] = entry

func _build_sheet_moods(id: String, spec: Dictionary) -> void:
    var parts := {}
    for key in ["A","B"]:
        var sheet := _load(str(spec[key]))
        parts[key] = {"sheet": sheet, "busts": _grid_busts(sheet, spec[key + "_grid"], float(spec.get(key + "_trim", 0.0)))}
        print("%s %s busts=%d" % [id, key, parts[key]["busts"].size()])
    var entry := {"sheets": {"A": str(spec["A"]), "B": str(spec["B"])}, "expressions": {}}
    for mood in MOODS:
        var ref: Array = spec["moods"][mood]
        var busts: Array = parts[ref[0]]["busts"]
        var index := int(ref[1])
        if index >= busts.size():
            push_error("%s %s: component %d missing (found %d)" % [id, mood, index, busts.size()])
            continue
        var img: Image = _defringe(busts[index])
        var framed := _frame_bust(img)
        _save(framed, "expressions/%s/%s" % [id, mood], framed.get_size())
        entry["expressions"][mood] = "%s#%d" % [ref[0], index]
    manifest[id] = entry

# ---------------------------------------------------------------- slicing

# One bust per grid cell, in reading order. `row_cols` lists how many cells each
# row has (Daren's labelled sheet is 4 over 5). Inside a cell only the largest
# connected component is kept, so a caption plate, a "!" mark or the shoulder of
# the neighbouring bust never leaks into the crop, and nothing inside the
# figure (white clothing included) is ever erased.
func _grid_busts(sheet: Image, row_cols: Array, trim_bottom: float = 0.0) -> Array:
    var result: Array = []
    var rows := row_cols.size()
    var cell_h := sheet.get_height() / rows
    for r in range(rows):
        var cols := int(row_cols[r])
        var cell_w := sheet.get_width() / cols
        for c in range(cols):
            # Daren's labelled sheet has caption plates overlapping the bust
            # bottom; the caption band is cut off before isolating the figure.
            var cell := sheet.get_region(Rect2i(c * cell_w, r * cell_h, cell_w, int(cell_h * (1.0 - trim_bottom))))
            var comps := _components(cell, 0.0)
            if comps.is_empty():
                continue
            result.append(comps[0])
    return result

# Figures on a transparent image, largest first when min_share is 0, otherwise
# in reading order. Each is isolated on its own transparent canvas (other
# components cleared).
func _components(sheet: Image, min_share: float = 0.012) -> Array:
    var w := sheet.get_width()
    var h := sheet.get_height()
    # Cell mode floods at a firmer alpha so faint semi-transparent pixels cannot
    # bridge two neighbouring busts; soft edges are restored by a 2 px grow below.
    var flood_alpha := 0.3 if min_share <= 0.0 else 0.04
    var label := PackedInt32Array()
    label.resize(w * h)
    var comps: Array = []
    var next := 0
    for start in range(w * h):
        if label[start] != 0 or sheet.get_pixel(start % w, start / w).a <= flood_alpha:
            continue
        next += 1
        label[start] = next
        var stack: Array[int] = [start]
        var pixels := 0
        var minx := w
        var miny := h
        var maxx := 0
        var maxy := 0
        while not stack.is_empty():
            var p: int = stack.pop_back()
            pixels += 1
            var px := p % w
            var py := p / w
            minx = mini(minx, px)
            maxx = maxi(maxx, px)
            miny = mini(miny, py)
            maxy = maxi(maxy, py)
            for dy in [-1, 0, 1]:
                for dx in [-1, 0, 1]:
                    var nx: int = px + dx
                    var ny: int = py + dy
                    if nx < 0 or ny < 0 or nx >= w or ny >= h:
                        continue
                    var q := ny * w + nx
                    if label[q] == 0 and sheet.get_pixel(nx, ny).a > flood_alpha:
                        label[q] = next
                        stack.push_back(q)
        comps.append({"id": next, "pixels": pixels, "rect": Rect2i(minx, miny, maxx - minx + 1, maxy - miny + 1)})
    var threshold := int(w * h * min_share)
    var busts: Array = []
    for comp in comps:
        if int(comp["pixels"]) >= threshold:
            busts.append(comp)
    if min_share <= 0.0:
        busts.sort_custom(func(a, b): return int(a["pixels"]) > int(b["pixels"]))
        busts = busts.slice(0, 1)
    else:
        busts.sort_custom(func(a, b):
            var ra: Rect2i = a["rect"]
            var rb: Rect2i = b["rect"]
            var ya := ra.position.y + ra.size.y / 2
            var yb := rb.position.y + rb.size.y / 2
            if absi(ya - yb) > h / 5:
                return ya < yb
            return ra.position.x < rb.position.x
        )
    var result: Array = []
    for comp in busts:
        var rect: Rect2i = comp["rect"]
        var crop := Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
        crop.fill(Color(0, 0, 0, 0))
        for y in range(rect.size.y):
            for x in range(rect.size.x):
                var sx := rect.position.x + x
                var sy := rect.position.y + y
                var px := sheet.get_pixel(sx, sy)
                if px.a <= 0.0:
                    continue
                if label[sy * w + sx] == int(comp["id"]) or (label[sy * w + sx] == 0 and _near_label(label, w, h, sx, sy, int(comp["id"]), 2)):
                    crop.set_pixel(x, y, px)
        result.append(crop)
    return result

# Sheet busts are cut flat at the bottom. Keep that edge on the frame bottom and
# pad to the shared bust aspect so every expression sits the same way.
func _frame_bust(img: Image) -> Image:
    var w := img.get_width()
    var h := img.get_height()
    var target_w := maxi(w, int(round(h * BUST_ASPECT)))
    var target_h := maxi(h, int(round(target_w / BUST_ASPECT)))
    var canvas := Image.create(target_w, target_h, false, Image.FORMAT_RGBA8)
    canvas.fill(Color(0, 0, 0, 0))
    canvas.blit_rect(img, Rect2i(0, 0, w, h), Vector2i((target_w - w) / 2, target_h - h))
    return canvas

# ---------------------------------------------------------------- faces

func _top_row(img: Image) -> int:
    for y in range(img.get_height()):
        for x in range(0, img.get_width(), 3):
            if img.get_pixel(x, y).a > 0.5:
                return y
    return 0

# Centroid of skin-coloured opaque pixels just under the top of the figure.
# Long hair and raised hands move it a little, never off the face.
func _face_center(img: Image) -> Vector2i:
    var top := _top_row(img)
    var sx := 0.0
    var sy := 0.0
    var n := 0
    # A narrow band under the top of the head: bare shoulders start lower.
    for y in range(top + 70, mini(img.get_height(), top + 250), 2):
        for x in range(0, img.get_width(), 2):
            var c := img.get_pixel(x, y)
            if c.a < 0.9:
                continue
            if c.r > 0.72 and c.g > 0.52 and c.b > 0.42 and c.r > c.g and c.g > c.b and c.r - c.b > 0.08 and c.r - c.b < 0.45:
                sx += x
                sy += y
                n += 1
    if n == 0:
        return Vector2i(img.get_width() / 2, top + 180)
    return Vector2i(int(sx / n), int(sy / n))

func _head_crop(img: Image) -> Image:
    var face := _face_center(img)
    var size := 330
    var x := clampi(face.x - size / 2, 0, img.get_width() - size)
    var y := clampi(face.y - int(size * 0.52), 0, img.get_height() - size)
    return img.get_region(Rect2i(x, y, size, size))

func _bust_crop(img: Image) -> Image:
    var face := _face_center(img)
    var h := 660
    var w := int(round(h * BUST_ASPECT))
    var x := clampi(face.x - w / 2, 0, img.get_width() - w)
    var y := clampi(face.y - 230, 0, img.get_height() - h)
    return img.get_region(Rect2i(x, y, w, h))

# ---------------------------------------------------------------- defringe

func _defringe(src: Image) -> Image:
    var img: Image = src.duplicate()
    img.convert(Image.FORMAT_RGBA8)
    var w := img.get_width()
    var h := img.get_height()
    var n := w * h
    var has := PackedByteArray()
    has.resize(n)
    var cr := PackedFloat32Array()
    var cg := PackedFloat32Array()
    var cb := PackedFloat32Array()
    cr.resize(n)
    cg.resize(n)
    cb.resize(n)
    for i in range(n):
        var c := img.get_pixel(i % w, i / w)
        if c.a >= 0.94:
            has[i] = 1
            cr[i] = c.r
            cg[i] = c.g
            cb[i] = c.b
    # Grow the solid colour field outward a few pixels so every soft edge pixel
    # can borrow the colour of the figure it belongs to.
    for _pass in range(6):
        var grown: Array[int] = []
        var nr: Array[float] = []
        var ng: Array[float] = []
        var nb: Array[float] = []
        for i in range(n):
            if has[i] == 1:
                continue
            var x := i % w
            var y := i / w
            if img.get_pixel(x, y).a <= 0.0:
                continue
            var tr := 0.0
            var tg := 0.0
            var tb := 0.0
            var count := 0
            for dy in [-1, 0, 1]:
                for dx in [-1, 0, 1]:
                    var nx: int = x + dx
                    var ny: int = y + dy
                    if nx < 0 or ny < 0 or nx >= w or ny >= h:
                        continue
                    var q := ny * w + nx
                    if has[q] == 1:
                        tr += cr[q]
                        tg += cg[q]
                        tb += cb[q]
                        count += 1
            if count > 0:
                grown.append(i)
                nr.append(tr / count)
                ng.append(tg / count)
                nb.append(tb / count)
        if grown.is_empty():
            break
        for k in range(grown.size()):
            var i: int = grown[k]
            has[i] = 1
            cr[i] = nr[k]
            cg[i] = ng[k]
            cb[i] = nb[k]
    for i in range(n):
        var x := i % w
        var y := i / w
        var c := img.get_pixel(x, y)
        if c.a <= 0.0 or c.a >= 0.94:
            continue
        if has[i] == 0:
            # Haze far from any solid pixel: background residue if it is pale
            # and colourless, otherwise leave it alone.
            var light := (c.r + c.g + c.b) / 3.0
            var sat := maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b))
            if light > 0.72 and sat < 0.16:
                img.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))
            continue
        var fr := cr[i]
        var fg := cg[i]
        var fb := cb[i]
        var dr := fr - 1.0
        var dg := fg - 1.0
        var db := fb - 1.0
        var len2 := dr * dr + dg * dg + db * db
        var alpha := c.a
        if len2 > 0.03:
            var t := clampf(((c.r - 1.0) * dr + (c.g - 1.0) * dg + (c.b - 1.0) * db) / len2, 0.0, 1.0)
            alpha = c.a * lerpf(1.0, t, 0.85)
        if alpha < 0.03:
            alpha = 0.0
        img.set_pixel(x, y, Color(fr, fg, fb, alpha))
    return img

func _save(img: Image, id: String, dimensions: Vector2i) -> void:
    var path := OUT + id + ".webp"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
    var copy: Image = img.duplicate()
    if copy.get_size() != dimensions:
        # Uniform scale only: callers pass dimensions with the source aspect.
        copy.resize(dimensions.x, dimensions.y, Image.INTERPOLATE_LANCZOS)
    copy.save_webp(ProjectSettings.globalize_path(path), true, 0.92)

func _near_label(label: PackedInt32Array, w: int, h: int, x: int, y: int, id: int, radius: int) -> bool:
    for dy in range(-radius, radius + 1):
        for dx in range(-radius, radius + 1):
            var nx := x + dx
            var ny := y + dy
            if nx < 0 or ny < 0 or nx >= w or ny >= h:
                continue
            if label[ny * w + nx] == id:
                return true
    return false
