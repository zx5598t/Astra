extends SceneTree

# Head-only icons, cut from the transparent half-body cast art.
#
# The 96px SD sprites were a whole body squeezed into a 30px row beside a name,
# which made them decoration rather than identification — you could not tell who
# was who at that size. A head fills the same box with the one part of the
# figure people actually recognise.
#
# The crop is found from the alpha channel rather than hand-tuned per character:
#   1. find the silhouette's bounding box
#   2. take the horizontal centre of the topmost rows (that is the head)
#   3. cut a square whose side is a fixed share of the figure's height
#
# Hair that sticks out sideways is why the centre is measured over a band of
# rows rather than a single row.

const ORDER := ["mira", "sena", "noa", "lyra", "rho", "eli", "vale", "dax"]
const OUT_SIZE := 192
# Share of the whole figure's height that the head occupies in this art style.
const HEAD_SHARE := 0.38
# A little room above the hairline so the crop does not shave the top.
const TOP_PAD := 0.02

func _init() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/art040/heads/"))
    var written := 0
    for npc_id in ORDER:
        var source := ProjectSettings.globalize_path("res://assets/art040/cast/%s.webp" % npc_id)
        var image := Image.load_from_file(source)
        if image == null:
            printerr("MISSING " + source)
            continue
        image.convert(Image.FORMAT_RGBA8)
        var box := _alpha_bounds(image)
        if box.size.x <= 0 or box.size.y <= 0:
            printerr("EMPTY ALPHA " + npc_id)
            continue
        var side := int(round(float(box.size.y) * HEAD_SHARE))
        var top := maxi(0, box.position.y - int(round(float(box.size.y) * TOP_PAD)))
        var centre := _head_centre(image, box, side)
        var left := clampi(centre - int(side / 2.0), 0, maxi(0, image.get_width() - side))
        top = clampi(top, 0, maxi(0, image.get_height() - side))
        var head := image.get_region(Rect2i(left, top, mini(side, image.get_width() - left), mini(side, image.get_height() - top)))
        head = _square(head)
        head.resize(OUT_SIZE, OUT_SIZE, Image.INTERPOLATE_LANCZOS)
        var out := "res://assets/art040/heads/%s.webp" % npc_id
        if head.save_webp(ProjectSettings.globalize_path(out), true, 0.95) != OK:
            printerr("SAVE FAILED " + out)
            continue
        written += 1
        print("%s  side %d  at (%d, %d)" % [out, side, left, top])
    print("HEAD ICONS: %d" % written)
    quit(0 if written == ORDER.size() else 1)

func _alpha_bounds(image: Image) -> Rect2i:
    var min_x := image.get_width()
    var min_y := image.get_height()
    var max_x := -1
    var max_y := -1
    for y in range(image.get_height()):
        for x in range(image.get_width()):
            if image.get_pixel(x, y).a <= 0.18:
                continue
            min_x = mini(min_x, x)
            min_y = mini(min_y, y)
            max_x = maxi(max_x, x)
            max_y = maxi(max_y, y)
    if max_x < 0:
        return Rect2i(0, 0, 0, 0)
    return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

# Horizontal centre of the opaque pixels across the head band, so a side-swept
# fringe does not pull the crop off the face.
func _head_centre(image: Image, box: Rect2i, side: int) -> int:
    var total := 0
    var weighted := 0
    var bottom := mini(image.get_height(), box.position.y + side)
    for y in range(box.position.y, bottom):
        for x in range(box.position.x, mini(image.get_width(), box.position.x + box.size.x)):
            if image.get_pixel(x, y).a <= 0.35:
                continue
            total += 1
            weighted += x
    if total == 0:
        return box.position.x + int(box.size.x / 2.0)
    return int(float(weighted) / float(total))

func _square(image: Image) -> Image:
    var side := maxi(image.get_width(), image.get_height())
    var out := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
    out.fill(Color(0, 0, 0, 0))
    out.blit_rect(image, Rect2i(0, 0, image.get_width(), image.get_height()),
        Vector2i(int((side - image.get_width()) / 2.0), int((side - image.get_height()) / 2.0)))
    return out
