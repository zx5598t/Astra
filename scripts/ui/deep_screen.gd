class_name AstraDeepScreen
extends Control

# 심층 재구성 screens outside a depth: start (pick one protocol for the run),
# resume, the short scene between depths, and the end-of-run record. Local
# bests only (§46). No stat grinding, no upgrades (§39).

var app
var mode: String = ""

func setup(app_node, screen_mode: String = "", context: Dictionary = {}) -> void:
    app = app_node
    mode = screen_mode
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var art := AstraUI.thumb(AstraArt.background("bridge"), Vector2.ZERO)
    art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    art.modulate = Color(0.35, 0.36, 0.5)
    add_child(art)
    add_child(AstraArt.shade(true))
    var panel := AstraUI.reading_panel(AstraUI.VIOLET, 0.95)
    panel.anchor_left = 0.5
    panel.anchor_right = 0.5
    panel.anchor_top = 0.5
    panel.anchor_bottom = 0.5
    panel.offset_left = -470
    panel.offset_right = 470
    panel.offset_top = -300
    panel.offset_bottom = 300
    add_child(panel)
    var box := AstraUI.vbox(12)
    panel.add_child(box)
    box.add_child(AstraUI.label("심층 재구성  ·  DEEP RECONSTRUCTION", AstraUI.T_TITLE, AstraUI.VIOLET))
    match mode:
        "between":
            _between(box, context)
        "summary":
            _summary(box)
        _:
            _entry(box)

func _records(box: VBoxContainer) -> void:
    var meta: AstraMetaProgress = app.meta
    box.add_child(AstraUI.label("최고 깊이 %d  ·  최고 정확도 %d%%  ·  도전 %d회" % [meta.deep_best_depth, meta.deep_best_accuracy, meta.deep_runs], AstraUI.T_UI, AstraUI.GOLD))

func _entry(box: VBoxContainer) -> void:
    box.add_child(AstraUI.prose("같은 사람들, 새로운 재구성. 한 번 쓰러지거나 Null에게 표를 빼앗기면 이번 도전은 끝납니다. 깊어질수록 사람이 늘고, 4번째 깊이부터는 조건이 하나씩 붙습니다(시작할 때 알려 줍니다). 7번째 깊이부터 Null은 둘입니다.", AstraUI.T_UI, AstraUI.MUTED))
    _records(box)
    var run := AstraDeepRun.active_run()
    if not run.is_empty():
        var card := AstraUI.panel(Color(AstraUI.VIOLET, 0.12), Color(AstraUI.VIOLET, 0.6), 10, 12)
        var col := AstraUI.vbox(6)
        card.add_child(col)
        col.add_child(AstraUI.label("진행 중인 도전 · 깊이 %d · %s" % [int(run.get("depth", 1)), _protocol_name(str(run.get("protocol", "NONE")))], AstraUI.T_HEAD, AstraUI.TEXT))
        col.add_child(AstraUI.label("지금까지 격리한 Null %d · 정확도 %d%%" % [int(Dictionary(run.get("stats", {})).get("contained", 0)), AstraDeepRun.accuracy(run)], AstraUI.T_META, AstraUI.MUTED))
        box.add_child(card)
        var row := AstraUI.hbox(10)
        box.add_child(row)
        var resume := AstraUI.primary_button("이어하기   →", AstraUI.VIOLET)
        resume.pressed.connect(func(): app.deep_resume())
        row.add_child(resume)
        var giveup := AstraUI.button("이 도전 끝내기", AstraUI.MUTED, AstraUI.T_UI, 46)
        giveup.pressed.connect(func(): app.deep_abandon())
        row.add_child(giveup)
    else:
        box.add_child(AstraUI.label("이번 도전에서 쓸 프로토콜 하나를 고르세요. 도전 중에는 바꿀 수 없습니다.", AstraUI.T_UI, AstraUI.TEXT))
        for id in ["GUARDIAN", "ANALYST", "EMPATH"]:
            var button := AstraUI.button("%s  ·  %s" % [_protocol_name(id), _protocol_blurb(id)], AstraUI.VIOLET, AstraUI.T_UI, 50)
            button.alignment = HORIZONTAL_ALIGNMENT_LEFT
            button.pressed.connect(func(): app.deep_start(id))
            box.add_child(button)
    box.add_child(AstraUI.spacer(false))
    var back := AstraUI.button("타이틀로", AstraUI.MUTED, AstraUI.T_UI, 44)
    back.pressed.connect(func(): app.show_title())
    box.add_child(back)

func _between(box: VBoxContainer, context: Dictionary) -> void:
    var speaker := str(context.get("speaker", ""))
    var depth := int(context.get("depth", 1))
    if speaker != "":
        var row := AstraUI.hbox(14)
        box.add_child(row)
        var face := AstraUI.thumb(AstraCrewCatalog.portrait_path(speaker, "neutral"), Vector2(120, 140))
        face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        row.add_child(face)
        var col := AstraUI.vbox(6)
        col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(col)
        col.add_child(AstraUI.label(AstraCrewCatalog.display_name(speaker), AstraUI.T_HEAD, AstraCrewCatalog.accent(speaker)))
        col.add_child(AstraUI.prose("“%s”" % AstraDeepRun.between_line(speaker, depth), AstraUI.T_BODY, AstraUI.TEXT))
    var next_mod := str(context.get("modifier", ""))
    var info := "다음 · 깊이 %d · 깨어 있는 사람 %d명" % [depth, int(context.get("awake", 0))]
    box.add_child(AstraUI.label(info, AstraUI.T_UI, AstraUI.GOLD))
    if next_mod != "":
        var mod: Dictionary = AstraDeepRun.MODIFIERS.get(next_mod, {})
        box.add_child(AstraUI.prose("조건 · %s — %s" % [str(mod.get("name", "")), str(mod.get("text", ""))], AstraUI.T_UI, AstraUI.MUTED))
    box.add_child(AstraUI.spacer(false))
    var go := AstraUI.primary_button("깊이 %d로   →" % depth, AstraUI.VIOLET)
    go.pressed.connect(func(): app.deep_continue())
    box.add_child(go)
    go.grab_focus.call_deferred()

func _summary(box: VBoxContainer) -> void:
    var run := AstraDeepRun.load_run()
    var stats: Dictionary = run.get("stats", {})
    box.add_child(AstraUI.label("도전 종료 · 깊이 %d" % int(run.get("depth", 1)), AstraUI.T_HEAD, AstraUI.RED))
    box.add_child(AstraUI.prose("격리한 Null %d · 끝까지 깨어 있던 승무원 %d · 당신의 표 정확도 %d%% · 공개된 모순 %d · Aegis 차단 %d" % [
        int(stats.get("contained", 0)), int(stats.get("saved", 0)), AstraDeepRun.accuracy(run), int(stats.get("contradictions", 0)), int(stats.get("protects", 0))], AstraUI.T_UI, AstraUI.TEXT))
    _records(box)
    box.add_child(AstraUI.spacer(false))
    var row := AstraUI.hbox(10)
    box.add_child(row)
    var again := AstraUI.primary_button("새 도전   →", AstraUI.VIOLET)
    again.pressed.connect(func(): app.show_deep())
    row.add_child(again)
    var back := AstraUI.button("타이틀로", AstraUI.MUTED, AstraUI.T_UI, 46)
    back.pressed.connect(func(): app.show_title())
    row.add_child(back)

func _protocol_name(id: String) -> String:
    return {"GUARDIAN": "가디언", "ANALYST": "애널리스트", "EMPATH": "엠패스"}.get(id, "없음")

func _protocol_blurb(id: String) -> String:
    return {"GUARDIAN": "밤에 한 사람을 Aegis로 지킨다 (깊이마다 2회)", "ANALYST": "하루 한 번 두 말을 정밀 대조한다", "EMPATH": "하루 한 번 더 묻거나 더 말한다"}.get(id, "")

func consume_advance() -> bool:
    if mode == "between":
        app.deep_continue()
        return true
    return false
