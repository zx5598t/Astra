class_name AstraArt
extends RefCounted

const ROOT := "res://assets/art031/"
const ROOT_040 := "res://assets/art040/"
const ROOT_071 := "res://assets/art071/"
const ROOM_ART := {
    "comms": "bridge", "bridge": "bridge", "navigation": "bridge", "antenna": "bridge", "deck": "bridge", "observatory": "bridge",
    "engine": "engine", "reactor": "engine", "core": "engine", "power": "engine", "coolant": "engine",
    "security": "security", "hub": "security", "shield": "security",
    "archive": "archive", "records": "archive", "storage": "archive", "vault": "archive",
    "garden": "garden", "hydroponics": "garden", "medical": "medical", "medbay": "medical", "clinic": "medical", "cryo": "medical",
    "lounge": "lounge", "quarters": "lounge", "corridor": "breach", "airlock": "breach", "water": "engine", "relay": "bridge", "beacon": "security", "galley": "lounge",
    "service": "breach"
}
const CHAPTER_ART := {"DEAD_AIR": "bridge", "ECHO_WARD": "medical", "GLASS_GARDEN": "garden", "SILENT_ORBIT": "engine", "RED_SHIFT": "archive", "LAST_LIGHT": "breach",
    "SECOND_WATCH": "archive", "BORROWED_DAYS": "lounge", "BLIND_DECK": "breach", "THREE_MINUTES_DARK": "engine", "CONTINUITY": "garden", "THRESHOLD": "bridge"}
const STORY_ART_071 := {
    "SECOND_WATCH": "second_watch",
    "BLIND_DECK": "blind_deck",
    "THREE_MINUTES_DARK": "three_minutes_dark",
    "CONTINUITY": "continuity",
    "THRESHOLD": "threshold"
}
static func background(id: String) -> String:
    return ROOT + "backgrounds/" + id + ".webp"
static func room(id: String) -> String:
    return background(str(ROOM_ART.get(id, "bridge")))
static func chapter(id: String) -> String:
    return background(str(CHAPTER_ART.get(id, "bridge")))
static func story_scene(id: String) -> String:
    var key := str(STORY_ART_071.get(id, ""))
    if key == "":
        return ""
    var path := ROOT_071 + key + ".svg"
    return path if ResourceLoader.exists(path) else ""
static func item(id: String) -> String:
    return ROOT + "items/" + id + ".webp"
static func clue(clue_data: Dictionary) -> String:
    # Appearance derives exclusively from visible evidence type, never culprit/decoy/role.
    match str(clue_data.get("kind", "")):
        "access_log": return item("evidence_11")
        "op_record": return item("evidence_02")
        "context": return item("medical_16")
        "sighting", "planted": return item("comms_09")
        "night": return item("comms_07")
        "slip": return item("evidence_09")
        "trace":
            match str(clue_data.get("category", "")):
                "fiber": return item("evidence_03")
                "clearance", "shift": return item("evidence_04")
                "hand": return item("evidence_11")
                "terminal": return item("evidence_01")
    return item("archive_07")
static func icon(id: String, dimensions: Vector2 = Vector2(56, 56)) -> TextureRect:
    var rect := AstraUI.thumb(id if id.begins_with("res://") else item(id), dimensions)
    rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    return rect
static func shade(horizontal: bool = false) -> TextureRect:
    var gradient := Gradient.new()
    gradient.colors = PackedColorArray([Color(0.02,0.035,0.065,0.96), Color(0.02,0.035,0.065,0.58), Color(0.02,0.035,0.065,0.06)])
    gradient.offsets = PackedFloat32Array([0.0,0.43,1.0])
    var tex := GradientTexture2D.new()
    tex.gradient = gradient
    tex.fill_from = Vector2(0,0) if horizontal else Vector2(0,1)
    tex.fill_to = Vector2(1,0) if horizontal else Vector2(0,0)
    var rect := TextureRect.new()
    rect.texture = tex
    rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return rect

# 0.4.0 key art with no text baked into it. The ship mock-ups supplied alongside
# these have Korean UI text painted on, so they stay reference-only: live text
# over baked text is worse than no art at all.
static func scene(id: String) -> String:
    var path := ROOT_040 + "scenes/" + id + ".webp"
    return path if ResourceLoader.exists(path) else background("bridge")
