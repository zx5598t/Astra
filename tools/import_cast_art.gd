extends SceneTree

# One-off asset pipeline for 0.4.0.
#
# Converts the supplied transparent half-body cutouts into the WebP files the
# game ships. Index -> crew id was verified against the 0.3.1 portraits: the
# labels printed on the supplied style sheets (Kai / Jin / Sera / Dante and the
# shuffled job titles) are NOT canon and are ignored, per the art policy.

const SOURCE_DIR := "C:/Users/songsorosong/Desktop/claude/Astra/참고 이미지 파일/"
const ORDER := ["mira", "sena", "noa", "lyra", "rho", "eli", "vale", "dax"]
const SET_A := [
    "ChatGPT Image 2026년 9월 18일 오후 06_00_11 (1).png",
    "ChatGPT Image 2026년 9월 18일 오후 06_00_12 (2).png",
    "ChatGPT Image 2026년 9월 18일 오후 06_00_13 (3).png",
    "ChatGPT Image 2026년 9월 18일 오후 06_00_14 (4).png",
    "ChatGPT Image 2026년 9월 18일 오후 06_00_14 (5).png",
    "ChatGPT Image 2026년 9월 18일 오후 06_00_15 (6).png",
    "ChatGPT Image 2026년 9월 18일 오후 06_00_16 (7).png",
    "ChatGPT Image 2026년 9월 18일 오후 06_00_18 (8).png"
]
const SET_B := [
    "ChatGPT Image 2026년 9월 18일 오후 06_00_41 (1).png",
    "ChatGPT Image 2026년 9월 18일 오후 06_00_42 (2).png",
    "ChatGPT Image 2026년 9월 18일 오후 06_00_43 (3).png",
    "ChatGPT Image 2026년 9월 18일 오후 06_00_43 (4).png",
    "ChatGPT Image 2026년 9월 18일 오후 06_00_44 (5).png",
    "ChatGPT Image 2026년 9월 18일 오후 06_00_45 (6).png",
    "ChatGPT Image 2026년 9월 18일 오후 06_00_45 (7).png",
    "ChatGPT Image 2026년 9월 18일 오후 06_00_46 (8).png"
]
const TARGET_HEIGHT := 1200

func _init() -> void:
    var written := 0
    written += _convert(SET_A, "res://assets/art040/cast/")
    written += _convert(SET_B, "res://assets/art040/cast_alt/")
    print("CAST ART WRITTEN: %d" % written)
    quit(0 if written == 16 else 1)

func _convert(files: Array, out_dir: String) -> int:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
    var count := 0
    for index in range(files.size()):
        var source := SOURCE_DIR + str(files[index])
        var image := Image.load_from_file(source)
        if image == null:
            printerr("MISSING: " + source)
            continue
        # The source keeps its 3:4 framing; only the long edge is reduced.
        if image.get_height() > TARGET_HEIGHT:
            var scale := float(TARGET_HEIGHT) / float(image.get_height())
            image.resize(int(round(image.get_width() * scale)), TARGET_HEIGHT, Image.INTERPOLATE_LANCZOS)
        var out_path := out_dir + str(ORDER[index]) + ".webp"
        if image.save_webp(ProjectSettings.globalize_path(out_path), true, 0.92) != OK:
            printerr("SAVE FAILED: " + out_path)
            continue
        count += 1
        print("%s  <-  %s  (%dx%d)" % [out_path, files[index], image.get_width(), image.get_height()])
    return count
