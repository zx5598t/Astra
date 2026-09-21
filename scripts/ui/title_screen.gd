class_name AstraTitleScreen
extends Control

# The title.
#
# Two rewrites got it here. 0.3.1 showed the archive, the protocol picker and
# six cases to somebody who had never pressed a button. The first 0.4.0 pass cut
# that to one button but named it "접속 시작" / "다음 항해" / "계속하기" — words
# that describe the fiction rather than the action, so nobody could tell which
# one started a new game and which one carried on.
#
# This version uses the two words every game uses, and shows the three save
# slots as rows rather than hiding them behind a menu:
#
#   처음 시작 / 새로 시작   — begin a case
#   이어하기                — one row per slot, with what is in it
#
# Locked features are still absent rather than greyed out.

var app

func setup(app_node) -> void:
    app = app_node
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var art := AstraUI.thumb(AstraArt.background("medical"), Vector2.ZERO)
    art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(art)
    add_child(AstraArt.shade(true))

    var root := AstraUI.hbox(28)
    var margin := AstraUI.margin(root, 58, 30, 48, 26)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(margin)

    var started: bool = app.meta.past_calibration()
    var slots: Array = app.slot_infos()
    var has_save := false
    for row in slots:
        if not bool(row["empty"]):
            has_save = true

    # ---- left: identity --------------------------------------------------
    var left := AstraUI.vbox(10)
    left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    left.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(left)

    var top := AstraUI.hbox(10)
    left.add_child(top)
    top.add_child(AstraArt.icon("icons_14", Vector2(38, 38)))
    top.add_child(AstraUI.label("ASTRA  /  목적지 미확인", AstraUI.T_META, AstraUI.MUTED))

    left.add_child(AstraUI.spacer(false))
    left.add_child(AstraUI.label("A S T R A", 88, AstraUI.TEXT))
    left.add_child(AstraUI.label("마지막 교신", AstraUI.T_TITLE, AstraUI.CYAN))
    left.add_child(AstraUI.prose("같은 배에서 깨어났지만,\n우리는 서로 다른 목적지를 기억한다.", AstraUI.T_HEAD, AstraUI.TEXT))
    left.add_child(AstraUI.spacer(false))

    var footer := AstraUI.hbox(10)
    left.add_child(footer)
    var entries: Array = [["설정", app.show_settings]]
    if started:
        entries.append(["도움말", app.show_help])
    entries.append(["종료", app.quit_game])
    for spec in entries:
        var button := AstraUI.button(str(spec[0]), AstraUI.MUTED, AstraUI.T_UI, 40)
        button.pressed.connect(spec[1])
        footer.add_child(button)
    footer.add_child(AstraUI.spacer())
    footer.add_child(AstraUI.label("v" + app.version_text(), AstraUI.T_META, AstraUI.MUTED))

    # ---- right: what you can actually do ---------------------------------
    var panel := AstraUI.reading_panel(AstraUI.CYAN, 0.9)
    panel.custom_minimum_size.x = 470
    panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    root.add_child(panel)
    var menu := AstraUI.vbox(12)
    panel.add_child(menu)

    if not started:
        # A brand new archive: one button, and a sentence saying what it costs.
        var begin := AstraUI.primary_button("처음 시작   →")
        begin.pressed.connect(_begin_first_run)
        menu.add_child(begin)
        menu.add_child(AstraUI.prose("당신은 ASTRA의 탐사요원입니다. 네 명의 동료가 깨어 있고, 네 명은 아직 잠들어 있습니다.", AstraUI.T_META, AstraUI.MUTED))
        if has_save:
            menu.add_child(_slot_section(slots))
    else:
        if has_save:
            menu.add_child(AstraUI.label("이어하기", AstraUI.T_HEAD, AstraUI.CYAN))
            menu.add_child(_slot_section(slots))
            menu.add_child(AstraUI.label("", AstraUI.T_META, AstraUI.DIM))
        var fresh := AstraUI.primary_button("새로 시작   →")
        fresh.pressed.connect(_begin_new_case)
        menu.add_child(fresh)
        menu.add_child(AstraUI.prose("다음 항해 기록을 따라갑니다. 지난번에 나눈 마음은 작은 행동으로 남습니다.", AstraUI.T_META, AstraUI.MUTED))
        if app.meta.has_feature("case_select"):
            var archive := AstraUI.secondary_button("사건 선택 · 항해 기록")
            archive.pressed.connect(func(): app.show_archive())
            menu.add_child(archive)
        menu.add_child(_progress_strip())

# Three rows, always three, so the player can see how many saves they have.
func _slot_section(slots: Array) -> Control:
    var box := AstraUI.vbox(6)
    for row in slots:
        box.add_child(_slot_row(row))
    return box

func _slot_row(row: Dictionary) -> Control:
    var slot := int(row["slot"])
    var info: Dictionary = row["info"]
    var empty: bool = bool(row["empty"])
    var card := AstraUI.panel(
        Color(AstraUI.CYAN, 0.10) if not empty else Color(0.03, 0.05, 0.09, 0.7),
        Color(AstraUI.CYAN, 0.45) if not empty else Color(AstraUI.BORDER, 0.7), 8, 10)
    var line := AstraUI.hbox(10)
    card.add_child(line)
    var index_label := AstraUI.label("%d" % (slot + 1), AstraUI.T_HEAD, AstraUI.CYAN if not empty else AstraUI.DIM)
    index_label.custom_minimum_size.x = 26
    line.add_child(index_label)

    var text := AstraUI.vbox(1)
    text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    line.add_child(text)
    if empty:
        text.add_child(AstraUI.label("비어 있음", AstraUI.T_BODY, AstraUI.DIM))
    else:
        var case_data := AstraCaseCatalog.get_case(str(info.get("case_id", "")))
        text.add_child(AstraUI.label(str(case_data.get("title_ko", info.get("case_id", ""))), AstraUI.T_BODY, AstraUI.TEXT))
        var detail := "사건 %d일차 · %s" % [int(info.get("day", 1)), AstraGameSession.PHASE_LABELS.get(str(info.get("phase", "")), "")]
        var saved_at := str(info.get("saved_at", ""))
        if saved_at != "":
            # "2026-09-19T14:20:31" reads better as a date and a time, and the
            # seconds are noise on a save slot.
            var parts := saved_at.split("T")
            detail += "   " + parts[0] + ("  " + parts[1].substr(0, 5) if parts.size() > 1 else "")
        text.add_child(AstraUI.label(detail, AstraUI.T_META, AstraUI.MUTED))

    if empty:
        line.add_child(AstraUI.label("—", AstraUI.T_META, AstraUI.DIM))
        return card
    var load_button := AstraUI.button("이어하기", AstraUI.CYAN, AstraUI.T_UI, 40, true)
    load_button.pressed.connect(func(): app.resume_case(slot))
    line.add_child(load_button)
    var erase := AstraUI.button("삭제", AstraUI.MUTED, AstraUI.T_META, 40)
    erase.pressed.connect(_confirm_erase.bind(slot))
    line.add_child(erase)
    return card

func _confirm_erase(slot: int) -> void:
    var body := AstraUI.prose("%d번 저장을 지웁니다. 되돌릴 수 없습니다. 완료한 사건 기록은 그대로 남습니다." % (slot + 1), AstraUI.T_BODY, AstraUI.TEXT)
    var handler := func(choice: int) -> void:
        if choice == 1:
            AstraGameSession.delete_snapshot(app.slot_path(slot))
            app.clear_slot_state(slot)
            app.show_title()
    AstraModal.open(app.overlay_root(), "저장을 지울까요?", body,
        [["취소", AstraUI.MUTED], ["지우기", AstraUI.RED]], handler, 520.0)

# Progress shown as recovered record rather than as a percentage. A bare number
# tells the player how much grinding is left; a filling archive tells them the
# repetition is going somewhere (§81, §105).
func _progress_strip() -> Control:
    var recovered: int = app.meta.completed_campaign_cases()
    var total: int = AstraCaseCatalog.CAMPAIGN.size()
    var card := AstraUI.panel(Color(0.02, 0.05, 0.09, 0.85), Color(AstraUI.CYAN, 0.25), 10, 12)
    var box := AstraUI.vbox(6)
    card.add_child(box)
    box.add_child(AstraUI.label("확인한 항해 기록  %d / %d" % [recovered, total], AstraUI.T_META, AstraUI.CYAN))
    var blocks := AstraUI.hbox(4)
    box.add_child(blocks)
    for index in range(total):
        var cell := ColorRect.new()
        cell.custom_minimum_size = Vector2(38, 10)
        # Recovered layers read solid; the rest are damaged area, not "???".
        cell.color = Color(AstraUI.CYAN, 0.85) if index < recovered else Color(AstraUI.BORDER, 0.55)
        blocks.add_child(cell)
    var hint := AstraUnlocks.next_hint(app.meta.past_calibration(), app.meta.campaign_cases_played())
    if hint != "":
        box.add_child(AstraUI.label(hint, AstraUI.T_META, AstraUI.DIM))
    return card

func _begin_first_run() -> void:
    app.start_new_campaign(app.first_free_slot())

func _begin_new_case() -> void:
    var free_slot: int = app.first_free_slot()
    if free_slot >= 0:
        app.start_case(app.meta.recommended_case_id(), app.selected_protocol, free_slot)
        return
    # All three slots are in use, so the player has to say which one to reuse.
    var box := AstraUI.vbox(8)
    box.add_child(AstraUI.prose("저장 슬롯 세 개가 모두 차 있습니다. 어느 자리에 새 사건을 넣을까요?", AstraUI.T_BODY, AstraUI.TEXT))
    var holder := []
    for row in app.slot_infos():
        var slot := int(row["slot"])
        var info: Dictionary = row["info"]
        var case_data := AstraCaseCatalog.get_case(str(info.get("case_id", "")))
        var button := AstraUI.button("%d번 · %s · %d일째" % [slot + 1, str(case_data.get("title_ko", "")), int(info.get("day", 1))], AstraUI.GOLD, AstraUI.T_UI, 46)
        button.pressed.connect(func():
            if not holder.is_empty() and is_instance_valid(holder[0]):
                holder[0].close(-1)
            app.start_case(app.meta.recommended_case_id(), app.selected_protocol, slot)
        )
        box.add_child(button)
    holder.append(AstraModal.open(app.overlay_root(), "덮어쓸 자리를 고르세요", box, [["취소", AstraUI.MUTED]], Callable(), 560.0))
