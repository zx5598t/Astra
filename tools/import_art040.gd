extends SceneTree

# 0.4.0 asset pipeline (run once; output is committed).
#
#   godot --headless --path . --script res://tools/import_art040.gd
#
# Three jobs:
#   1. the text-free key art becomes opening / title / meeting backdrops
#   2. the SD sprite row on the supplied style sheet becomes eight 1:1 icons
#      with the white background keyed out
#   3. index -> crew id follows the verified mapping, not the names printed on
#      the sheet (those are shuffled and are not canon)
#
# The ship key art on the other sheets has Korean UI text baked into it, so it
# is reference only: painting live text over baked text is worse than not using
# the image at all.

const SOURCE := "C:/Users/songsorosong/Desktop/claude/Astra/참고 이미지 파일/"
const ORDER := ["mira", "sena", "noa", "lyra", "rho", "eli", "vale", "dax"]

# Text-free key art -> where it is used.
const SCENES := {
    "crew_deck": "ChatGPT Image 2026년 9월 18일 오후 08_23_37 (1).png",
    "crew_console": "ChatGPT Image 2026년 9월 18일 오후 08_23_38 (2).png",
    "faces_glitch": "ChatGPT Image 2026년 9월 18일 오후 08_23_38 (3).png"
}

# The SD row on the style bible: eight sprites on a white field.
const DOT_SHEET := "ChatGPT Image 2026년 9월 18일 오후 06_01_30.png"
const DOT_FIRST_CENTER_X := 580.0
const DOT_STEP_X := 66.1
const DOT_TOP := 328
const DOT_BOTTOM := 424
const DOT_HALF_W := 31
const DOT_OUT := 96

func _init() -> void:
    var ok := _scenes()
    ok = _dots() and ok
    print("ART 0.4.0 IMPORT %s" % ("OK" if ok else "INCOMPLETE"))
    quit(0 if ok else 1)

func _scenes() -> bool:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/art040/scenes/"))
    var ok := true
    for key in SCENES:
        var image := Image.load_from_file(SOURCE + str(SCENES[key]))
        if image == null:
            printerr("MISSING " + str(SCENES[key]))
            ok = false
            continue
        # 1672x941 is already close to 16:9; only the long edge is reduced so the
        # framing the artist chose is preserved.
        if image.get_width() > 1600:
            var scale := 1600.0 / float(image.get_width())
            image.resize(1600, int(round(image.get_height() * scale)), Image.INTERPOLATE_LANCZOS)
        var path := "res://assets/art040/scenes/%s.webp" % key
        if image.save_webp(ProjectSettings.globalize_path(path), true, 0.9) != OK:
            printerr("SAVE FAILED " + path)
            ok = false
            continue
        print("%s  (%dx%d)" % [path, image.get_width(), image.get_height()])
    return ok

func _dots() -> bool:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/art040/dots/"))
    var sheet := Image.load_from_file(SOURCE + DOT_SHEET)
    if sheet == null:
        printerr("MISSING dot sheet")
        return false
    var ok := true
    for index in range(ORDER.size()):
        var center := int(round(DOT_FIRST_CENTER_X + DOT_STEP_X * float(index)))
        var region := Rect2i(center - DOT_HALF_W, DOT_TOP, DOT_HALF_W * 2, DOT_BOTTOM - DOT_TOP)
        var crop := sheet.get_region(region)
        _key_out_white(crop)
        crop = _square(crop)
        crop.resize(DOT_OUT, DOT_OUT, Image.INTERPOLATE_LANCZOS)
        var path := "res://assets/art040/dots/%s.webp" % str(ORDER[index])
        if crop.save_webp(ProjectSettings.globalize_path(path), true, 0.95) != OK:
            printerr("SAVE FAILED " + path)
            ok = false
            continue
        print("%s  <- x %d" % [path, center])
    return ok

# The sheet prints the sprites on paper white. Anything close to white becomes
# transparent so the icon sits on the game's dark panels.
func _key_out_white(image: Image) -> void:
    image.convert(Image.FORMAT_RGBA8)
    for y in range(image.get_height()):
        for x in range(image.get_width()):
            var pixel := image.get_pixel(x, y)
            var brightness := (pixel.r + pixel.g + pixel.b) / 3.0
            var spread := maxf(pixel.r, maxf(pixel.g, pixel.b)) - minf(pixel.r, minf(pixel.g, pixel.b))
            if brightness > 0.93 and spread < 0.05:
                image.set_pixel(x, y, Color(pixel.r, pixel.g, pixel.b, 0.0))
            elif brightness > 0.86 and spread < 0.05:
                # Feather the edge so the cut-out does not look stamped.
                image.set_pixel(x, y, Color(pixel.r, pixel.g, pixel.b, (brightness - 0.86) / 0.07 * -1.0 + 1.0))

# Pads to a square so every icon scales identically in a row of names.
func _square(image: Image) -> Image:
    var side := maxi(image.get_width(), image.get_height())
    var out := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
    out.fill(Color(0, 0, 0, 0))
    out.blit_rect(image, Rect2i(0, 0, image.get_width(), image.get_height()),
        Vector2i(int((side - image.get_width()) / 2.0), side - image.get_height()))
    return out
