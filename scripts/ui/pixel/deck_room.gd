class_name AstraDeckRoom
extends Node2D

# One small room of the ship for an interlude, drawn from AstraInterludes data:
# a floor, walls one tile thick, a door gap in the bottom wall, and a few
# props. Kept plain on purpose (§60): the people are what the eye should find.
#
# A prop marked "front" is drawn a second time on a node that y-sorts with the
# people, so someone sitting behind a table has the table in front of their
# legs (the floor pass alone would always draw it under everybody).

class PropFront extends Node2D:
    var room: AstraDeckRoom
    var prop: Dictionary = {}

    func _draw() -> void:
        draw_set_transform(-position)
        room._draw_prop(self, prop, room.blink_on())

const TILE := AstraInterludes.TILE
const WALL := Color("0c1420")
const WALL_FACE := Color("1c2b3e")
const WALL_EDGE := Color("3b587a")
const FLOOR := Color("15202f")
const FLOOR_LINE := Color("1d2b3f")
const DOOR := Color("e0a84a")

var data: Dictionary = {}
var size_tiles := Vector2i(15, 9)
var door := Vector2i(6, 9)
var props: Array = []
var _time: float = 0.0
var _fronts: Array = []

func setup(interlude: Dictionary) -> void:
    data = interlude
    var size: Array = data.get("size", [15, 9])
    size_tiles = Vector2i(int(size[0]), int(size[1]))
    var gap: Array = data.get("door", [6, 9])
    door = Vector2i(int(gap[0]), int(gap[1]))
    props = data.get("props", [])
    y_sort_enabled = true
    for prop in props:
        if bool(prop.get("front", false)):
            var front := PropFront.new()
            front.room = self
            front.prop = prop
            front.position = Vector2(0.0, prop_rect(prop).end.y)
            add_child(front)
            _fronts.append(front)
    queue_redraw()

func blink_on() -> bool:
    return int(_time * 2.0) % 2 == 0

# The prop (marked "front") whose rect holds `point`: where someone sits.
func front_prop_at(point: Vector2) -> Dictionary:
    for prop in props:
        if bool(prop.get("front", false)) and prop_rect(prop).has_point(point):
            return prop
    return {}

func room_px() -> Vector2:
    return Vector2(size_tiles) * TILE

func tile_to_px(at: Array) -> Vector2:
    return Vector2(float(at[0]), float(at[1])) * TILE

func prop_rect(prop: Dictionary) -> Rect2:
    var r: Array = prop.get("rect", [0, 0, 1, 1])
    return Rect2(float(r[0]) * TILE, float(r[1]) * TILE, float(r[2]) * TILE, float(r[3]) * TILE)

func prop_by_id(id: String) -> Dictionary:
    for prop in props:
        if str(prop.get("id", "")) == id:
            return prop
    return {}

func door_rect() -> Rect2:
    return Rect2(door.x * TILE, (size_tiles.y - 1) * TILE, (door.y - door.x) * TILE, TILE)

# Feet box at `point` hits a wall or a solid prop.
func blocked(point: Vector2, radius: float = 18.0) -> bool:
    var feet := Rect2(point - Vector2(radius, 8.0), Vector2(radius * 2.0, 14.0))
    var inside := Rect2(Vector2(TILE, TILE), Vector2((size_tiles.x - 2) * TILE, (size_tiles.y - 2) * TILE))
    # The door columns reach half a tile into the bottom wall.
    var door_lane := Rect2(door.x * TILE + 4.0, TILE, (door.y - door.x) * TILE - 8.0, (size_tiles.y - 1.5) * TILE)
    if not inside.encloses(feet) and not door_lane.encloses(feet):
        return true
    for prop in props:
        if bool(prop.get("solid", false)) and prop_rect(prop).grow(-4.0).intersects(feet):
            return true
    return false

func _process(delta: float) -> void:
    if AstraUI.reduce_motion:
        return
    _time += delta
    if int(_time * 2.0) != int((_time - delta) * 2.0):
        queue_redraw()
        for front in _fronts:
            front.queue_redraw()

func _draw() -> void:
    var room := room_px()
    draw_rect(Rect2(Vector2.ZERO, room), WALL)
    var inside := Rect2(Vector2(TILE, TILE), Vector2((size_tiles.x - 2) * TILE, (size_tiles.y - 2) * TILE))
    draw_rect(inside, FLOOR)
    draw_rect(door_rect(), FLOOR)
    # floor plates
    for x in range(1, size_tiles.x):
        draw_line(Vector2(x * TILE, TILE), Vector2(x * TILE, room.y - TILE), FLOOR_LINE, 1.0)
    for y in range(1, size_tiles.y):
        draw_line(Vector2(TILE, y * TILE), Vector2(room.x - TILE, y * TILE), FLOOR_LINE, 1.0)
    # walls: the top wall shows its face, the others their edge
    draw_rect(Rect2(TILE * 0.5, TILE * 0.2, room.x - TILE, TILE * 0.8), WALL_FACE)
    draw_line(Vector2(TILE, TILE), Vector2(room.x - TILE, TILE), WALL_EDGE, 3.0)
    draw_line(Vector2(TILE, TILE), Vector2(TILE, room.y - TILE), WALL_EDGE, 2.0)
    draw_line(Vector2(room.x - TILE, TILE), Vector2(room.x - TILE, room.y - TILE), WALL_EDGE, 2.0)
    draw_line(Vector2(TILE, room.y - TILE), Vector2(door.x * TILE, room.y - TILE), WALL_EDGE, 2.0)
    draw_line(Vector2(door.y * TILE, room.y - TILE), Vector2(room.x - TILE, room.y - TILE), WALL_EDGE, 2.0)
    # the door gap, lit amber so the way out is always readable
    var dr := door_rect()
    draw_line(dr.position, dr.position + Vector2(0, TILE), DOOR, 4.0)
    draw_line(dr.position + Vector2(dr.size.x, 0), dr.position + Vector2(dr.size.x, TILE), DOOR, 4.0)
    draw_rect(Rect2(dr.position + Vector2(8, TILE - 10), Vector2(dr.size.x - 16, 4)), Color(DOOR, 0.5))
    var blink := int(_time * 2.0) % 2 == 0
    for prop in props:
        _draw_prop(self, prop, blink)

func _draw_prop(ci: CanvasItem, prop: Dictionary, blink: bool) -> void:
    var r := prop_rect(prop)
    match str(prop.get("kind", "")):
        "console":
            ci.draw_rect(Rect2(r.position + Vector2(0, 10), Vector2(r.size.x, r.size.y - 10)), Color("22334a"))
            ci.draw_rect(Rect2(r.position + Vector2(10, 16), Vector2(r.size.x - 20, r.size.y - 30)), Color("0d3346"))
            ci.draw_rect(Rect2(r.position + Vector2(14, 20), Vector2(r.size.x - 28, r.size.y - 38)), Color(AstraUI.CYAN, 0.35))
            for i in range(int(r.size.x / 22.0)):
                var on := (i % 3 == 0) != blink
                ci.draw_circle(r.position + Vector2(16 + i * 22, r.size.y - 6), 3.0, Color(AstraUI.GREEN if on else AstraUI.DIM, 0.9))
        "rack":
            ci.draw_rect(r.grow(-6), Color("243449"))
            for i in range(3):
                ci.draw_arc(r.position + Vector2(r.size.x * 0.5, 18 + i * 14), 8.0, PI, TAU, 12, AstraUI.MUTED, 3.0)
        "speaker":
            ci.draw_rect(r.grow(-6), Color("1e2c3f"))
            for i in range(6):
                ci.draw_line(r.position + Vector2(14, 14 + i * 16), r.position + Vector2(r.size.x - 14, 14 + i * 16), Color("0b121c"), 3.0)
            if blink:
                ci.draw_circle(r.position + Vector2(r.size.x * 0.5, r.size.y - 10), 3.0, AstraUI.GOLD)
        "clock":
            var c := r.get_center() + Vector2(0, 8)
            ci.draw_circle(c, 18.0, Color("dfe8ef"))
            ci.draw_arc(c, 18.0, 0.0, TAU, 24, Color("2a3a50"), 3.0)
            ci.draw_line(c, c + Vector2(0, -12), Color("1b2433"), 2.0)
            ci.draw_line(c, c + Vector2(9, 3), Color("c0392b"), 2.0)
        "bench":
            ci.draw_rect(r.grow(-8), Color("2a3b52"))
            ci.draw_rect(Rect2(r.position + Vector2(8, 8), Vector2(r.size.x - 16, 6)), Color("3b5170"))
        "cable":
            for i in range(3):
                ci.draw_line(r.position + Vector2(0, 20 + i * 10), r.position + Vector2(r.size.x, 24 + i * 10), Color("0f1a27"), 4.0)
        "table":
            ci.draw_rect(r.grow(-6), Color("2b3d55"))
            ci.draw_rect(Rect2(r.position + Vector2(6, 6), Vector2(r.size.x - 12, 6)), Color("3f5a7c"))
            # papers
            ci.draw_rect(Rect2(r.position + Vector2(18, 18), Vector2(34, 26)), Color("e8e4d8"))
            ci.draw_rect(Rect2(r.position + Vector2(r.size.x - 58, 20), Vector2(34, 26)), Color("e8e4d8"))
        "panel":
            ci.draw_rect(r.grow(-10), Color("223449"))
            ci.draw_rect(Rect2(r.position + Vector2(18, 16), Vector2(r.size.x - 36, 18)), Color(AstraUI.GREEN if blink else AstraUI.CYAN, 0.6))
        "breaker":
            ci.draw_rect(r.grow(-4), Color("24364c"))
            for i in range(4):
                var x := r.position.x + 22 + i * (r.size.x - 44) / 3.0
                ci.draw_line(Vector2(x, r.position.y + 14), Vector2(x, r.position.y + r.size.y - 14), Color("0d1622"), 6.0)
                ci.draw_circle(Vector2(x, r.position.y + (20 if i % 2 == 0 else r.size.y - 20)), 5.0, AstraUI.GOLD)
        "door":
            ci.draw_rect(r.grow(-4), Color("1a2636"))
            ci.draw_line(r.position + Vector2(r.size.x * 0.5, 6), r.position + Vector2(r.size.x * 0.5, r.size.y - 6), Color("0c131d"), 3.0)
            ci.draw_circle(r.position + Vector2(r.size.x - 16, r.size.y * 0.5), 4.0, AstraUI.RED if blink else Color("7a2a33"))
        "door_side":
            ci.draw_rect(r.grow(-6), Color("1a2636"))
            ci.draw_rect(Rect2(r.position + Vector2(8, 10), Vector2(r.size.x - 16, r.size.y - 20)), Color("27384f"))
            ci.draw_circle(r.position + Vector2(18, r.size.y * 0.5), 4.0, Color("c7a15a"))
        "bench_lab":
            ci.draw_rect(r.grow(-4), Color("26394f"))
            for i in range(4):
                var at := r.position + Vector2(26 + i * (r.size.x - 52) / 3.0, r.size.y * 0.5)
                ci.draw_rect(Rect2(at - Vector2(9, 12), Vector2(18, 24)), Color(AstraUI.GREEN, 0.35))
                ci.draw_rect(Rect2(at - Vector2(9, 12), Vector2(18, 24)), Color("9fd8b8"), false, 1.5)
        "planter":
            ci.draw_rect(r.grow(-6), Color("3a2f25"))
            for i in range(5):
                var leaf := r.position + Vector2(14 + (i * 23) % int(maxf(1.0, r.size.x - 28)), 14 + (i * 17) % int(maxf(1.0, r.size.y - 28)))
                ci.draw_circle(leaf, 9.0, Color("4f8a4a"))
                ci.draw_circle(leaf + Vector2(6, -4), 6.0, Color("6fb05f"))
        "shelf":
            ci.draw_rect(r.grow(-4), Color("22334a"))
            for i in range(int(r.size.x / 14.0)):
                var h := 18.0 + float((i * 7) % 12)
                ci.draw_rect(Rect2(r.position + Vector2(8 + i * 14, r.size.y - 8 - h), Vector2(10, h)), Color("8a7a5a") if i % 3 else Color("5a6e8a"))
        "alarm":
            ci.draw_rect(r.grow(-6), Color("2a1f26"))
            ci.draw_rect(Rect2(r.position + Vector2(14, 14), Vector2(r.size.x - 28, r.size.y - 28)), Color(AstraUI.RED, 0.75 if blink else 0.3))
        "chart":
            # a paper roster on the wall: a row per person, a column per day,
            # and one slot outlined
            var paper := Rect2(r.position + Vector2(8, 14), Vector2(r.size.x - 16, r.size.y - 18))
            ci.draw_rect(paper, Color("e8e4d8"))
            ci.draw_rect(paper, Color("8f846c"), false, 2.0)
            var cell := Vector2((paper.size.x - 8.0) / 7.0, (paper.size.y - 8.0) / 8.0)
            for i in range(8):
                for j in range(7):
                    if (i * 3 + j * 5) % 4 == 0:
                        ci.draw_rect(Rect2(paper.position + Vector2(5.0 + j * cell.x, 5.0 + i * cell.y), cell - Vector2(2, 2)), Color("b9ad92"))
            ci.draw_rect(Rect2(paper.position + Vector2(4.0 + 5.0 * cell.x, 4.0 + 6.0 * cell.y), cell), AstraUI.GOLD if blink else Color(AstraUI.GOLD, 0.55), false, 2.0)
        "dining":
            # a long lounge table: top, front edge, plates, a pot
            var top := Rect2(r.position + Vector2(4, 4), Vector2(r.size.x - 8, r.size.y - 22))
            ci.draw_rect(Rect2(top.position + Vector2(0, top.size.y), Vector2(top.size.x, 14)), Color("3a2b20"))
            ci.draw_rect(top, Color("6b4f3a"))
            ci.draw_rect(Rect2(top.position, Vector2(top.size.x, 4)), Color("8a6a4e"))
            var pot := top.position + Vector2(top.size.x * 0.72, top.size.y * 0.5 + 2.0)
            for i in range(int(top.size.x / 64.0)):
                var plate := top.position + Vector2(38.0 + i * 64.0, 15.0)
                if absf(plate.x - pot.x) < 30.0:
                    continue
                ci.draw_circle(plate, 9.0, Color("e6e1d6"))
                ci.draw_circle(plate, 5.0, Color("cfc6b4"))
            ci.draw_rect(Rect2(pot - Vector2(14, 8), Vector2(28, 16)), Color("4c5a6a"))
            ci.draw_rect(Rect2(pot - Vector2(16, 10), Vector2(32, 4)), Color("6f8194"))
        "window":
            ci.draw_rect(Rect2(r.position + Vector2(6, 10), Vector2(r.size.x - 12, r.size.y - 16)), Color("0a1330"))
            for i in range(6):
                ci.draw_circle(r.position + Vector2(16 + (i * 37) % int(maxf(1.0, r.size.x - 32)), 18 + (i * 11) % 30), 1.5, Color("dfe8ff"))
        _:
            ci.draw_rect(r.grow(-6), Color("243449"))
