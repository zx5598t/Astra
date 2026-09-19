extends SceneTree
# Reproducible mechanical crops. Source originals remain untouched.
const NAMES := {"mira":"미라", "jun":"준", "daren":"다렌", "noa":"노아", "sena":"세나", "soren":"소렌", "lucan":"루칸", "maren":"마렌"}
const SHEETS := {"mira":[48,49,3,2], "jun":[82,83,3,2], "daren":[28,29,4,2], "noa":[4,5,3,2], "sena":[72,73,3,2], "soren":[79,80,4,2], "lucan":[32,33,3,2], "maren":[45,46,6,5]}
const MOODS := ["neutral","smile","happy","suspicious","annoyed","embarrassed","shocked","sad","angry","determined","afraid","tired"]
func _initialize() -> void:
    var source := ProjectSettings.globalize_path("res://../0.5.0 수정 인물 이미지/Astra/")
    var index: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tools/art050_sources.json"))
    var manifest := {}
    for id in NAMES:
        var path: String = source + NAMES[id] + "/" + NAMES[id] + ".png"
        var original := Image.load_from_file(path)
        _save(original, "cast/" + id, Vector2i(683,1024))
        _save(original.get_region(Rect2i(120,0,804,960)), "portraits/" + id, Vector2i(536,640))
        var head_rect := Rect2i(365,0,330,330)
        if id == "noa": head_rect = Rect2i(370,0,320,320)
        if id == "jun": head_rect = Rect2i(355,0,330,330)
        _save(original.get_region(head_rect), "heads/" + id, Vector2i(256,256))
        manifest[id] = {"source":path, "head_rect":[head_rect.position.x,head_rect.position.y,head_rect.size.x,head_rect.size.y], "expressions":{}}
        var spec: Array = SHEETS[id]
        for n in range(MOODS.size()):
            var file_index: int = spec[0] if n < 6 else spec[1]
            var filename := source + str(index[file_index])
            var sheet := Image.load_from_file(filename)
            var cols: int = spec[2]
            var rows: int = spec[3]
            var cell_index := n % 6
            if id == "maren":
                cell_index = [5,1,2,7,10,15,27,11,16,18,14,20][n]
                filename = source + str(index[45])
                sheet = Image.load_from_file(filename)
            var w: int = sheet.get_width() / cols
            var h: int = sheet.get_height() / rows
            var rect := Rect2i((cell_index % cols)*w+10, (cell_index/cols)*h+10, w-20, h-48)
            var crop := sheet.get_region(rect)
            _clear_sheet_border(crop)
            _save(crop, "expressions/"+id+"/"+MOODS[n], crop.get_size())
            manifest[id]["expressions"][MOODS[n]] = {"source":filename,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y]}
    var file := FileAccess.open("res://assets/art050/manifest.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(manifest,"  "))
    print("ASTRA 050 ART OK")
    quit()
func _save(img: Image, id: String, dimensions: Vector2i) -> void:
    var path := "res://assets/art050/" + id + ".webp"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
    img = img.duplicate()
    img.resize(dimensions.x,dimensions.y,Image.INTERPOLATE_LANCZOS)
    img.save_webp(path, true, 0.92)

# Remove only near-white pixels connected to the sheet edge. Enclosed white
# clothing and eyes are preserved. Original source files are never modified.
func _clear_sheet_border(img: Image) -> void:
    img.convert(Image.FORMAT_RGBA8)
    var w := img.get_width()
    var h := img.get_height()
    var queue: Array[Vector2i] = []
    for x in range(w):
        queue.append(Vector2i(x,0))
        queue.append(Vector2i(x,h-1))
    for y in range(h):
        queue.append(Vector2i(0,y))
        queue.append(Vector2i(w-1,y))
    var cursor := 0
    var seen := PackedByteArray()
    seen.resize(w*h)
    while cursor < queue.size():
        var p := queue[cursor]
        cursor += 1
        if p.x < 0 or p.x >= w or p.y < 0 or p.y >= h: continue
        var offset := p.y*w+p.x
        if seen[offset] == 1: continue
        seen[offset] = 1
        var c := img.get_pixelv(p)
        if c.a > 0.01 and minf(c.r,minf(c.g,c.b)) < 0.95: continue
        img.set_pixelv(p,Color(c.r,c.g,c.b,0))
        for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]: queue.append(p+d)

