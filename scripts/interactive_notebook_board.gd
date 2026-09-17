class_name AstraInteractiveNotebookBoard
extends Control

signal hypothesis_changed

var state: AstraHypothesisGameState
var selected_evidence_id: String = ""
var _evidence_nodes: Array[Dictionary] = []
var _crew_nodes: Array[Dictionary] = []

var bg := Color("07111f")
var text_color := Color("e8f1ff")
var muted := Color("8196b4")
var cyan := Color("55d6ff")
var gold := Color("ffd36a")
var red := Color("ff6f7f")
var green := Color("5ee3a0")
var magenta := Color("ff9ed1")

func configure(game_state: AstraHypothesisGameState) -> void:
    state = game_state
    custom_minimum_size = Vector2(930, 535)
    mouse_filter = Control.MOUSE_FILTER_STOP
    focus_mode = Control.FOCUS_ALL
    _rebuild_nodes()
    queue_redraw()

func _rebuild_nodes() -> void:
    _evidence_nodes.clear()
    _crew_nodes.clear()
    if state == null:
        return

    var ev_index := 0
    for ev_id in state.discovered_evidence:
        var ev: Dictionary = state.truth.evidence.get(ev_id, {})
        _evidence_nodes.append({
            "id":ev_id,
            "label":str(ev.get("name", ev_id)),
            "pos":Vector2(155, 115 + ev_index * 48),
            "rect":Rect2(36, 98 + ev_index * 48, 238, 34)
        })
        ev_index += 1

    var crew_index := 0
    for npc_id in state.crew_order:
        var npc: NPCState = state.npcs[npc_id]
        _crew_nodes.append({
            "id":npc_id,
            "label":("× " if not npc.alive else "") + npc.display_name,
            "alive":npc.alive,
            "pos":Vector2(760, 100 + crew_index * 48),
            "rect":Rect2(670, 83 + crew_index * 48, 180, 34)
        })
        crew_index += 1

func _gui_input(event: InputEvent) -> void:
    if state == null or not (event is InputEventMouseButton):
        return

    var mouse := event as InputEventMouseButton
    if not mouse.pressed:
        return

    var ev_id := _hit_evidence(mouse.position)
    if ev_id != "":
        selected_evidence_id = ev_id
        queue_redraw()
        accept_event()
        return

    var target_id := _hit_crew(mouse.position)
    if target_id == "" or selected_evidence_id == "":
        return

    if mouse.button_index == MOUSE_BUTTON_RIGHT:
        state.remove_manual_link(selected_evidence_id, target_id)
    elif mouse.button_index == MOUSE_BUTTON_LEFT:
        var kind := "clear" if mouse.shift_pressed else "suspect"
        if mouse.ctrl_pressed or mouse.meta_pressed:
            kind = "question"
        state.add_manual_link(selected_evidence_id, target_id, kind)

    _rebuild_nodes()
    queue_redraw()
    hypothesis_changed.emit()
    accept_event()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), bg, true)
    draw_string(ThemeDB.fallback_font, Vector2(28, 32), "PLAYER HYPOTHESIS BOARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, cyan)
    draw_string(ThemeDB.fallback_font, Vector2(28, 56), "증거 선택 → Crew 클릭: 의심 / Shift+클릭: 해명 / Ctrl+클릭: 질문 / 우클릭: 삭제", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, muted)
    _draw_engine_links()
    _draw_manual_links()

    for ev in _evidence_nodes:
        var selected := str(ev.get("id", "")) == selected_evidence_id
        var rect: Rect2 = ev["rect"]
        _draw_node(rect, str(ev.get("label", "Evidence")), Color("17283e"), cyan if selected else gold, selected)

    for crew in _crew_nodes:
        var border := cyan if bool(crew.get("alive", true)) else muted
        var rect: Rect2 = crew["rect"]
        _draw_node(rect, str(crew.get("label", "Crew")), Color("122033"), border, false)

    draw_string(ThemeDB.fallback_font, Vector2(80, 90), "DISCOVERED EVIDENCE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, gold)
    draw_string(ThemeDB.fallback_font, Vector2(720, 76), "CREW", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, cyan)
    draw_string(ThemeDB.fallback_font, Vector2(335, 505), "RED=engine suspicion   GREEN=engine clear   MAGENTA=your hypothesis   CYAN=your clear   GOLD=?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, muted)

func _draw_engine_links() -> void:
    if state == null:
        return

    for edge in state.notebook_edges:
        var ev_id := str(edge.get("evidence_id", ""))
        var target_id := str(edge.get("target_id", ""))
        if target_id == "":
            continue

        var a := _evidence_center(ev_id)
        var b := _crew_center(target_id)
        if a == Vector2.ZERO or b == Vector2.ZERO:
            continue

        var evidence_signal := str(edge.get("signal", "context"))
        var line_color := gold
        if evidence_signal == "implicates":
            line_color = Color(red, 0.45)
        elif evidence_signal == "clears":
            line_color = Color(green, 0.45)
        draw_line(a + Vector2(120, 0), b - Vector2(90, 0), line_color, 1.5, true)

    for item in state.contradiction_register:
        var a := _evidence_center(str(item.get("evidence_id", "")))
        var b := _crew_center(str(item.get("npc_id", "")))
        if a != Vector2.ZERO and b != Vector2.ZERO:
            draw_line(a + Vector2(120, 7), b - Vector2(90, -7), Color(red, 0.75), 3.0, true)

func _draw_manual_links() -> void:
    if state == null:
        return

    for item in state.manual_links:
        var a := _evidence_center(str(item.get("evidence_id", "")))
        var b := _crew_center(str(item.get("target_id", "")))
        if a == Vector2.ZERO or b == Vector2.ZERO:
            continue

        var kind := str(item.get("kind", "suspect"))
        var line_color := magenta
        if kind == "clear":
            line_color = cyan
        elif kind == "question":
            line_color = gold
        draw_line(a + Vector2(120, -6), b - Vector2(90, 6), line_color, 4.0, true)

func _draw_node(rect: Rect2, label: String, fill: Color, border: Color, selected: bool) -> void:
    draw_rect(rect, fill, true)
    draw_rect(rect, border, false, 3.0 if selected else 1.5)
    var display := label
    if display.length() > 26:
        display = display.substr(0, 25) + "…"
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, 22), display, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16, 13, text_color)

func _hit_evidence(pos: Vector2) -> String:
    for node in _evidence_nodes:
        var rect: Rect2 = node["rect"]
        if rect.has_point(pos):
            return str(node.get("id", ""))
    return ""

func _hit_crew(pos: Vector2) -> String:
    for node in _crew_nodes:
        var rect: Rect2 = node["rect"]
        if rect.has_point(pos):
            return str(node.get("id", ""))
    return ""

func _evidence_center(ev_id: String) -> Vector2:
    for node in _evidence_nodes:
        if str(node.get("id", "")) == ev_id:
            var rect: Rect2 = node["rect"]
            return rect.get_center()
    return Vector2.ZERO

func _crew_center(npc_id: String) -> Vector2:
    for node in _crew_nodes:
        if str(node.get("id", "")) == npc_id:
            var rect: Rect2 = node["rect"]
            return rect.get_center()
    return Vector2.ZERO
