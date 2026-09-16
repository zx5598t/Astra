class_name AstraNotebookBoard
extends Control

var state: AstraProgressionGameState
var _evidence_nodes: Array[Dictionary] = []
var _crew_nodes: Array[Dictionary] = []
var _claim_nodes: Array[Dictionary] = []

var bg := Color("09121f")
var panel := Color("13243a")
var text_color := Color("e8f1ff")
var muted := Color("8096b5")
var cyan := Color("55d6ff")
var gold := Color("ffd36a")
var red := Color("ff6f7f")
var green := Color("5ee3a0")

func configure(game_state: AstraProgressionGameState) -> void:
    state = game_state
    custom_minimum_size = Vector2(930, 520)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _rebuild_nodes()
    queue_redraw()

func _rebuild_nodes() -> void:
    _evidence_nodes.clear()
    _crew_nodes.clear()
    _claim_nodes.clear()
    if state == null:
        return
    var ev_index := 0
    for edge in state.notebook_edges:
        _evidence_nodes.append({"id":str(edge.get("evidence_id", "")), "label":str(edge.get("name", "Evidence")), "pos":Vector2(145, 105 + ev_index * 52), "signal":str(edge.get("signal", "context")), "target_id":str(edge.get("target_id", ""))})
        ev_index += 1
    var crew_index := 0
    for npc_id in state.crew_order:
        var npc: NPCState = state.npcs[npc_id]
        if not npc.alive:
            continue
        _crew_nodes.append({"id":npc_id, "label":npc.display_name, "pos":Vector2(710, 88 + crew_index * 50)})
        crew_index += 1
    var start := maxi(0, state.claim_register.size() - 4)
    var claim_index := 0
    for i in range(start, state.claim_register.size()):
        var claim: Dictionary = state.claim_register[i]
        var npc_id := str(claim.get("npc_id", ""))
        _claim_nodes.append({"npc_id":npc_id, "label":"D%d %s" % [int(claim.get("day", 1)), _name_for(npc_id)], "pos":Vector2(430, 340 + claim_index * 42)})
        claim_index += 1

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), bg, true)
    draw_string(ThemeDB.fallback_font, Vector2(28, 34), "INVESTIGATOR LINK BOARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, cyan)
    draw_string(ThemeDB.fallback_font, Vector2(28, 58), "발견한 정보만 표시됩니다. 선은 정답이 아니라 현재 연결입니다.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, muted)

    for ev in _evidence_nodes:
        var target_id := str(ev.get("target_id", ""))
        if target_id != "":
            var crew_pos := _crew_position(target_id)
            if crew_pos != Vector2.ZERO:
                var signal := str(ev.get("signal", "context"))
                var line_color := gold
                if signal == "implicates": line_color = red
                elif signal == "clears": line_color = green
                draw_line(Vector2(ev["pos"]) + Vector2(112, 0), crew_pos - Vector2(48, 0), line_color, 2.0, true)

    if state != null:
        for item in state.contradiction_register:
            var npc_id := str(item.get("npc_id", ""))
            var ev_id := str(item.get("evidence_id", ""))
            var a := _evidence_position(ev_id)
            var b := _crew_position(npc_id)
            if a != Vector2.ZERO and b != Vector2.ZERO:
                draw_line(a + Vector2(112, 8), b - Vector2(48, -8), red, 4.0, true)

    for claim in _claim_nodes:
        var npc_id := str(claim.get("npc_id", ""))
        var crew_pos := _crew_position(npc_id)
        if crew_pos != Vector2.ZERO:
            draw_line(Vector2(claim["pos"]) + Vector2(72, -8), crew_pos - Vector2(48, 0), Color(cyan.r, cyan.g, cyan.b, 0.45), 1.5, true)

    for ev in _evidence_nodes:
        _draw_node(Vector2(ev["pos"]), str(ev["label"]), Color("1a2a41"), gold, 215)
    for crew in _crew_nodes:
        _draw_node(Vector2(crew["pos"]), str(crew["label"]), Color("152338"), cyan, 150)
    for claim in _claim_nodes:
        _draw_node(Vector2(claim["pos"]), str(claim["label"]), Color("1a2234"), Color("ff9ed1"), 145)

    draw_string(ThemeDB.fallback_font, Vector2(98, 92), "EVIDENCE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, gold)
    draw_string(ThemeDB.fallback_font, Vector2(690, 72), "CREW", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, cyan)
    draw_string(ThemeDB.fallback_font, Vector2(397, 325), "CLAIMS", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ff9ed1"))

func _draw_node(pos: Vector2, label: String, fill: Color, border: Color, width: float) -> void:
    var rect := Rect2(pos - Vector2(width * 0.5, 17), Vector2(width, 34))
    draw_rect(rect, fill, true)
    draw_rect(rect, border, false, 1.5)
    var display := label
    if display.length() > 24:
        display = display.substr(0, 23) + "…"
    draw_string(ThemeDB.fallback_font, pos + Vector2(-width * 0.5 + 8, 5), display, HORIZONTAL_ALIGNMENT_LEFT, width - 16, 13, text_color)

func _crew_position(npc_id: String) -> Vector2:
    for node in _crew_nodes:
        if str(node.get("id", "")) == npc_id:
            return Vector2(node["pos"])
    return Vector2.ZERO

func _evidence_position(ev_id: String) -> Vector2:
    for node in _evidence_nodes:
        if str(node.get("id", "")) == ev_id:
            return Vector2(node["pos"])
    return Vector2.ZERO

func _name_for(npc_id: String) -> String:
    if state != null and npc_id in state.npcs:
        return state.npcs[npc_id].display_name
    return npc_id
