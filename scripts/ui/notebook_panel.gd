class_name AstraNotebookPanel
extends HBoxContainer

# The notebook is a help, not a HUD (§78): everything needed to play is on the
# play screens already. This page gathers what the explorer has heard today,
# one line per person, and the points that do not fit. Nothing here is needed
# to finish a Stage; it is here for the moment you want to look back.

var session: AstraGameSession

func setup(game_session: AstraGameSession) -> void:
    session = game_session
    add_theme_constant_override("separation", 16)
    var summary := session.notebook_summary()
    var left := AstraUI.vbox(8)
    left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_child(AstraUI.scroll(left))
    left.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
    left.add_child(AstraUI.label("오늘 알게 된 것", AstraUI.T_HEAD, AstraUI.GOLD))
    var today: Array = summary.get("today", [])
    if today.size() <= 1:
        left.add_child(AstraUI.prose("아직 들은 것이 없습니다. 대화에서 누군가 본 것이나 기록을 꺼내면 여기에 모입니다.", AstraUI.T_UI, AstraUI.MUTED))
    for line in today:
        left.add_child(AstraUI.prose("· " + str(line), AstraUI.T_UI, AstraUI.TEXT))
    var conflicts: Array = summary.get("contradictions", [])
    left.add_child(AstraUI.label("말이 안 맞는 곳", AstraUI.T_HEAD, AstraUI.RED))
    if conflicts.is_empty():
        left.add_child(AstraUI.prose("아직 없습니다.", AstraUI.T_UI, AstraUI.MUTED))
    for line in conflicts:
        left.add_child(AstraUI.prose("· " + str(line), AstraUI.T_UI, AstraUI.TEXT))

    var right := AstraUI.vbox(6)
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_child(AstraUI.scroll(right))
    right.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.add_child(AstraUI.label("사람별로", AstraUI.T_HEAD, AstraUI.CYAN))
    for row in summary.get("people", []):
        var id := str(row.get("id", ""))
        var card := AstraUI.panel(AstraUI.PANEL_2, AstraUI.BORDER, 8, 10)
        var box := AstraUI.vbox(3)
        card.add_child(box)
        var head := AstraUI.hbox(8)
        box.add_child(head)
        head.add_child(AstraUI.crew_dot(id, 28))
        head.add_child(AstraUI.label(session.name_of(id), AstraUI.T_UI, AstraCrewCatalog.accent(id)))
        if not bool(row.get("alive", true)):
            head.add_child(AstraUI.label(str(row.get("status", "")), AstraUI.T_META, AstraUI.DIM))
        var lines: Array = row.get("lines", [])
        if lines.is_empty():
            box.add_child(AstraUI.label("아직 이야기하지 않음", AstraUI.T_META, AstraUI.DIM))
        for line in lines:
            box.add_child(AstraUI.prose(str(line), AstraUI.T_META, AstraUI.TEXT))
        right.add_child(card)

func refresh() -> void:
    pass
