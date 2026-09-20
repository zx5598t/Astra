class_name AstraNotebookPanel
extends PanelContainer

var session: AstraGameSession
var tabs: TabContainer
var _clue_list: VBoxContainer
var _people: VBoxContainer
var _claims: VBoxContainer
var _search_field: LineEdit
var _search_results: VBoxContainer
var _notes: VBoxContainer
var _log: RichTextLabel
var _clue_pick: OptionButton
var _npc_pick: OptionButton
var _op_pick: OptionButton
var _relation_pick: OptionButton

func setup(game_session: AstraGameSession) -> void:
    session = game_session
    add_theme_stylebox_override("panel", AstraUI.style(AstraUI.PANEL,AstraUI.BORDER,10,1,10))
    tabs = TabContainer.new()
    tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
    tabs.add_theme_font_size_override("font_size",16)
    add_child(tabs)
    # The notebook starts as three plain lists. The hypothesis board — the part
    # that made 0.3.1's notebook look like a spreadsheet on first open — only
    # appears once the player has finished a couple of cases (§27).
    _clue_list = AstraUI.vbox(10)
    var clues := AstraUI.scroll(_clue_list)
    clues.name = "단서"
    tabs.add_child(clues)

    _people = AstraUI.vbox(10)
    var people := AstraUI.scroll(_people)
    people.name = "인물"
    tabs.add_child(people)

    _claims = AstraUI.vbox(10)
    var claims := AstraUI.scroll(_claims)
    claims.name = "발언"
    tabs.add_child(claims)

    if session.has_feature("hypothesis"):
        _notes = AstraUI.vbox(12)
        var notes := AstraUI.scroll(_notes)
        notes.name = "가설"
        tabs.add_child(notes)

    _log = AstraUI.rich(AstraUI.T_UI, false)
    _log.name = "사건 기록"
    _log.size_flags_vertical = Control.SIZE_EXPAND_FILL
    tabs.add_child(_log)
    refresh()

func focus_tab(index: int) -> void:
    tabs.current_tab = clampi(index, 0, tabs.get_tab_count() - 1)

func cycle_tab() -> void:
    tabs.current_tab = (tabs.current_tab + 1) % tabs.get_tab_count()

func refresh() -> void:
    AstraUI.clear(_clue_list)
    if not session.voyage.is_empty():
        var questions := session.current_questions()
        if not questions.is_empty():
            _clue_list.add_child(AstraUI.label("지금 궁금한 것",20,AstraUI.GOLD))
            for question in questions:
                var status := str(question.get("status","OPEN"))
                var prefix := "?" if status == "OPEN" else ("✓" if status == "ANSWERED" else ("◐" if status == "PARTIAL" else "↻"))
                var question_id := str(question.get("id",""))
                var qrow := AstraUI.hbox(8)
                _clue_list.add_child(qrow)
                qrow.add_child(AstraUI.prose("%s %s" % [prefix,str(question.get("text",""))],17,AstraUI.TEXT))
                var pinned := str(session.voyage.get("pinned_question","")) == question_id
                var pin := AstraUI.button("집중 중" if pinned else "집중해서 확인",AstraUI.GOLD if pinned else AstraUI.MUTED,13,34)
                pin.custom_minimum_size.x = 104
                pin.pressed.connect(func(): session.pin_question(question_id))
                qrow.add_child(pin)
                if pinned:
                    var related_labels: Array[String] = []
                    for raw in question.get("related",[]):
                        var key := str(raw)
                        if key in session.roster:
                            related_labels.append(session.name_of(key))
                        elif AstraVoyageContent.ROOMS.has(key):
                            related_labels.append(str(AstraVoyageContent.ROOMS[key]["name"]))
                    if not related_labels.is_empty():
                        _clue_list.add_child(AstraUI.prose("관련해서 볼 것 · " + " / ".join(PackedStringArray(related_labels)),14,AstraUI.DIM))
        _clue_list.add_child(AstraUI.label("확인한 사실",20,AstraUI.CYAN))
        for note in session.voyage.get("notes",[]):
            _clue_list.add_child(AstraUI.prose(str(note),17,AstraUI.TEXT))
        var routine_notes: Array = session.voyage.get("routine_observations",[])
        if not routine_notes.is_empty():
            _clue_list.add_child(AstraUI.label("직접 본 변화",18,AstraUI.MUTED))
            for observation in routine_notes.slice(maxi(0,routine_notes.size()-3)):
                _clue_list.add_child(AstraUI.prose(str(observation),15,AstraUI.DIM))
        var ownership: Dictionary = session.voyage.get("evidence_ownership",{})
        if not ownership.is_empty():
            _clue_list.add_child(AstraUI.label("정보 공유",18,AstraUI.MUTED))
            var ownership_keys: Array = ownership.keys()
            var start := maxi(0,ownership_keys.size()-3)
            for index in range(start,ownership_keys.size()):
                var fact_id := str(ownership_keys[index])
                var entry: Dictionary = ownership[fact_id]
                var label := fact_id
                for room_id in AstraVoyageContent.ROOMS:
                    for point in AstraVoyageContent.ROOMS[room_id].get("points",[]):
                        if str(point[4]) == fact_id:
                            label = str(point[1])
                var names: Array[String] = []
                for knower_raw in entry.get("knows",[]):
                    var knower := str(knower_raw)
                    names.append("나" if knower == "player" else session.name_of(knower))
                var public_text := "공개됨" if bool(entry.get("public",false)) else "아직 비공개"
                _clue_list.add_child(AstraUI.prose("%s · 알고 있음: %s · %s" % [label," / ".join(PackedStringArray(names)),public_text],15,AstraUI.DIM))
        if int(session.voyage.get("loop",0)) > 0:
            var differences := session.loop_difference_summary()
            if not differences.is_empty():
                _clue_list.add_child(AstraUI.label("지난 기록과 달라진 점",20,AstraUI.CYAN))
                for note in differences:
                    _clue_list.add_child(AstraUI.prose(str(note),16,AstraUI.MUTED))
    var found := session.found_clues()
    if found.is_empty():
        _clue_list.add_child(AstraUI.label("아직 확보한 단서가 없습니다. 현장의 단말과 흔적을 살펴보세요.",16,AstraUI.MUTED,true))
    for i in range(found.size()-1,-1,-1):
        var card := AstraClueCard.new()
        card.setup(session,found[i],true)
        _clue_list.add_child(card)
    _refresh_people()
    _refresh_claims()
    if _notes != null:
        _refresh_notes(found)
    var lines: Array[String] = []
    for entry in session.journal:
        lines.append("[color=#8fbee5]%d일째[/color]  %s" % [int(entry.get("day",1)),AstraUI.escape(str(entry.get("text","")))])
    _log.text = "\n\n".join(lines)

func _option() -> OptionButton:
    var b := OptionButton.new()
    b.custom_minimum_size.y = 42
    b.add_theme_font_size_override("font_size",15)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.fit_to_longest_item = false
    return b

func _refresh_notes(found: Array) -> void:
    AstraUI.clear(_notes)
    _notes.add_child(AstraUI.label("사건 시각 · " + session.window_text(),16,AstraUI.GOLD))
    _notes.add_child(AstraUI.label("단서와 인물을 연결해 자신의 해석을 남기세요. 장소·시각은 단서 원문과 대조하세요. 가설을 기록하는 것만으로 정답이 확인되지는 않습니다.",15,AstraUI.MUTED,true))
    _clue_pick = _option()
    for clue in found:
        _clue_pick.add_item(str(clue.get("title","")))
        _clue_pick.set_item_metadata(_clue_pick.item_count-1,str(clue.get("id","")))
    _notes.add_child(_clue_pick)
    var row := AstraUI.hbox(10)
    _notes.add_child(row)
    _npc_pick = _option()
    for id in session.active_roster():
        _npc_pick.add_item(session.name_of(id))
        _npc_pick.set_item_metadata(_npc_pick.item_count-1,id)
    row.add_child(_npc_pick)
    _op_pick = _option()
    for op in session.case_data.get("ops",[]):
        _op_pick.add_item(str(op.get("name","")))
        _op_pick.set_item_metadata(_op_pick.item_count-1,str(op.get("id","")))
    row.add_child(_op_pick)
    _relation_pick = _option()
    for name in ["관련","모순","무관"]:
        _relation_pick.add_item(name)
    row.add_child(_relation_pick)
    var save := AstraUI.button("가설 연결",AstraUI.CYAN,15,42)
    save.disabled = found.is_empty() or session.outcome != "" or session.hypotheses().size() >= 24
    save.pressed.connect(_save_link)
    row.add_child(save)
    _notes.add_child(AstraUI.section("나의 연결"))
    var links := session.hypotheses()
    if links.is_empty():
        _notes.add_child(AstraUI.label("아직 연결하지 않았습니다. 기록한 가설은 저녁 회의에서 제시할 수 있습니다.",15,AstraUI.DIM,true))
    for i in range(links.size()):
        var link: Dictionary = links[i]
        var clue := session.clue_by_id(str(link["clue"]))
        var line := AstraUI.hbox(8)
        line.add_child(AstraArt.icon(AstraArt.clue(clue),Vector2(48,48)))
        line.add_child(AstraUI.label("%s → %s / %s · %s" % [str(clue.get("title","")),session.name_of(str(link["npc"])),session.op_name(str(link["op"])),str(link["relation"])],15,AstraUI.TEXT,true))
        var remove := AstraUI.button("지우기",AstraUI.MUTED,13,36)
        remove.pressed.connect(session.remove_hypothesis.bind(i))
        line.add_child(remove)
        _notes.add_child(line)
    _notes.add_child(AstraUI.section("직접 들은 알리바이"))
    for id in session.active_roster():
        var claim: Dictionary = session.known_claims.get(id,{})
        var detail := "아직 듣지 못함"
        if not claim.is_empty():
            var mates: Array = claim.get("companions",[])
            detail = session.room_name(str(claim.get("position",""))) + " · " + ("혼자" if mates.is_empty() else AstraJosa.wa(session.names_of(mates)) + " 함께")
        _notes.add_child(AstraUI.label(session.name_of(id) + "  —  " + detail,15,AstraUI.MUTED,true))

func _save_link() -> void:
    if _clue_pick.item_count == 0:
        return
    session.link_hypothesis(str(_clue_pick.get_selected_metadata()),str(_npc_pick.get_selected_metadata()),str(_op_pick.get_selected_metadata()),_relation_pick.get_item_text(_relation_pick.selected))

# ---- 인물 -------------------------------------------------------------------
#
# One row per person: what they said, and whether anything they said conflicts.
# Deliberately not a trust meter — showing "Jun 0.42" would replace the reading
# of a person with the reading of a number (§100).
func _refresh_people() -> void:
    AstraUI.clear(_people)
    for npc_id in session.active_roster():
        var member := session.npc(npc_id)
        if member == null:
            continue
        var card := AstraUI.panel(AstraUI.PANEL_2, Color(member.accent, 0.3), 10, 12)
        _people.add_child(card)
        var row := AstraUI.hbox(12)
        card.add_child(row)
        var art := AstraUI.thumb(AstraCrewCatalog.portrait_path(npc_id, member.expression), Vector2(56, 56))
        art.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
        row.add_child(art)
        var box := AstraUI.vbox(3)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(box)
        var head := AstraUI.hbox(8)
        box.add_child(head)
        head.add_child(AstraUI.label(member.display_name, AstraUI.T_HEAD, member.accent))
        head.add_child(AstraUI.label(member.job, AstraUI.T_META, AstraUI.DIM))
        if not member.is_alive():
            head.add_child(AstraUI.chip("격리 또는 두절", AstraUI.RED, AstraUI.T_META - 2))
        if not session.voyage.is_empty():
            for observation in session.character_observations(npc_id):
                box.add_child(AstraUI.prose("· " + str(observation), AstraUI.T_META, AstraUI.TEXT))
            continue
        var claim: Dictionary = session.known_claims.get(npc_id, {})
        if claim.is_empty():
            box.add_child(AstraUI.label("진술 · 아직 듣지 못함", AstraUI.T_META, AstraUI.DIM))
        else:
            var mates: Array = claim.get("companions", [])
            box.add_child(AstraUI.label("진술 · %s / %s" % [
                session.room_name(str(claim.get("position", ""))),
                "혼자" if mates.is_empty() else AstraJosa.wa(session.names_of(mates)) + " 함께"
            ], AstraUI.T_META, AstraUI.TEXT))
        for issue in session.contradictions_on(npc_id):
            box.add_child(AstraUI.prose("· " + str(issue.get("detail", "")), AstraUI.T_META, AstraUI.GOLD))
        # Who this person is watching, and who is watching them.
        if member.is_alive():
            var relations: Dictionary = session.relations_of(npc_id)
            for entry in relations.get("watching", []):
                box.add_child(AstraUI.prose("→ %s · %s (%s)" % [
                    AstraCrewCatalog.display_name(str(entry["id"])),
                    str(entry["strength"]), str(entry["reason"])
                ], AstraUI.T_META, AstraUI.RED))
            var eyes := session.opinions_about(npc_id)
            if not eyes.is_empty():
                var names: Array = []
                for entry in eyes:
                    names.append(AstraCrewCatalog.display_name(str(entry["id"])))
                box.add_child(AstraUI.prose("← 이 사람을 보고 있는 사람: %s" % ", ".join(PackedStringArray(names)), AstraUI.T_META, AstraUI.GOLD))

# ---- 발언 -------------------------------------------------------------------
#
# "Who said this?" — the memory aid §28 asks for. It finds sentences; it does
# not rule on them. Two matching lines being contradictory is the player's call.
func _refresh_claims() -> void:
    AstraUI.clear(_claims)
    if not session.has_feature("claim_search"):
        _claims.add_child(AstraUI.prose("공개된 발언이 여기에 쌓입니다.", AstraUI.T_META, AstraUI.DIM))
        _list_recent_claims(_claims, session.claim_ledger)
        return
    _claims.add_child(AstraUI.prose("누가 이 말을 했는지 찾아볼 수 있습니다. 게임은 어느 쪽이 거짓인지 판정하지 않습니다.", AstraUI.T_META, AstraUI.MUTED))
    var row := AstraUI.hbox(8)
    _claims.add_child(row)
    _search_field = LineEdit.new()
    _search_field.placeholder_text = "예: 엔진실, 07:38, 혼자"
    _search_field.add_theme_font_size_override("font_size", AstraUI.font_size(AstraUI.T_UI))
    _search_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(_search_field)
    var find := AstraUI.button("찾기", AstraUI.CYAN, AstraUI.T_UI, 40)
    row.add_child(find)
    _search_results = AstraUI.vbox(6)
    _claims.add_child(_search_results)
    var run_search := func() -> void:
        AstraUI.clear(_search_results)
        var needle := _search_field.text.strip_edges()
        if needle == "":
            _list_recent_claims(_search_results, session.claim_ledger)
            return
        var hits := session.search_claims(needle)
        if hits.is_empty():
            _search_results.add_child(AstraUI.label("일치하는 발언이 없습니다.", AstraUI.T_META, AstraUI.DIM))
        else:
            _list_recent_claims(_search_results, hits)
    find.pressed.connect(run_search)
    _search_field.text_submitted.connect(func(_text: String): run_search.call())
    _list_recent_claims(_search_results, session.claim_ledger)

func _list_recent_claims(target: VBoxContainer, entries: Array) -> void:
    if entries.is_empty():
        target.add_child(AstraUI.label("아직 기록된 발언이 없습니다.", AstraUI.T_META, AstraUI.DIM))
        return
    var start := maxi(0, entries.size() - 30)
    for index in range(entries.size() - 1, start - 1, -1):
        var entry: Dictionary = entries[index]
        var speaker := str(entry.get("speaker", ""))
        var accent: Color = AstraUI.CYAN if speaker == "player" else AstraCrewCatalog.accent(speaker)
        var line := AstraUI.hbox(8)
        var who := AstraUI.label("탐사요원" if speaker == "player" else session.name_of(speaker), AstraUI.T_META, accent)
        who.custom_minimum_size.x = 84
        line.add_child(who)
        var day_tag := AstraUI.label("DAY %d" % int(entry.get("day", 1)), AstraUI.T_META, AstraUI.DIM)
        day_tag.custom_minimum_size.x = 64
        line.add_child(day_tag)
        var text := AstraUI.prose(str(entry.get("text", "")), AstraUI.T_META, AstraUI.MUTED if bool(entry.get("retracted", false)) else AstraUI.TEXT)
        line.add_child(text)
        target.add_child(line)
