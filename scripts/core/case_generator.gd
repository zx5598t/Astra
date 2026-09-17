class_name AstraCaseGenerator
extends RefCounted

# Turns an incident template + seed into one consistent hidden truth:
#   * two Nulls, each executing one sabotage operation in its own room
#   * where every crew member really was during the incident window
#   * what each of them will claim (crew tell the truth, Nulls and one
#     innocent with a private secret do not)
#   * every clue that can be found, and what it narrows down
# Clues never name a culprit directly. A saboteur is only pinned down by
# intersecting two traces of the same operation, or by breaking an alibi.

const TRACE_AT_SITE := {
    "clearance": ["권한 인증 잔여 기록", "{time}, {op}에 쓰인 콘솔 캐시에서 {group} 인증 흔적이 복구됐다. {group} 보유자: {members}."],
    "fiber": ["작업복 섬유", "{op} 현장 패널 틈에서 {group} 조각이 나왔다. 떨어진 시각은 {time} 전후. 이 작업복을 입는 사람: {members}."],
    "shift": ["교대 태그 신호", "{time}, {room} 안쪽 센서가 {group} 근무 태그를 감지했다. {group} 인원: {members}."],
    "hand": ["패널 조작 궤적", "{op}에 쓰인 패널에 {group} 궤적이 남았다({time}). 같은 습관을 가진 사람: {members}."],
    "terminal": ["단말 세션 흔적", "{time}, {op} 명령은 {group|eul} 거쳐 전송됐다. 이 단말을 쓰는 사람: {members}."]
}

const TRACE_ON_ROUTE := {
    "clearance": ["우회 인증 조회", "{time}, {room} 보조 콘솔에서 {group} 인증이 한 번 조회됐다. {op} 직후다. {group} 보유자: {members}."],
    "fiber": ["통로 필터의 섬유", "{room|ro} 이어지는 통로 필터에서 {group} 조각이 나왔다({time} 전후). {op} 현장에서 이어진 동선이다. 이 작업복을 입는 사람: {members}."],
    "shift": ["통로 센서 기록", "{time}, {op} 현장에서 {room} 방향으로 {group} 근무 태그가 이동했다. {group} 인원: {members}."],
    "hand": ["문 패널 궤적", "{room} 출입문 패널에 {group} 궤적이 찍혔다({time}). {op} 직후다. 같은 습관을 가진 사람: {members}."],
    "terminal": ["중계 접속 기록", "{time}, {room} 중계기에 {group} 접속이 남았다. {op} 명령 직후의 접속이다. 이 단말을 쓰는 사람: {members}."]
}

static func generate(case_id: String, seed_value: int) -> Dictionary:
    var data := AstraCaseCatalog.get_case(case_id)
    if data.is_empty():
        return {}
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value

    var crew: Array = AstraCrewCatalog.ORDER.duplicate()
    var ops: Array = data.get("ops", [])
    var room_ids: Array = []
    for room in data.get("rooms", []):
        room_ids.append(str(room.get("id", "")))
    var common_ids: Array = []
    for common in data.get("commons", []):
        common_ids.append(str(common.get("id", "")))
    var op_rooms: Array = [str(ops[0].get("room", "")), str(ops[1].get("room", ""))]
    var logged_rooms: Array = []
    for room_id in room_ids:
        if room_id not in op_rooms:
            logged_rooms.append(room_id)
    var open_positions: Array = logged_rooms + common_ids

    # 1. Hidden roles
    var pool := crew.duplicate()
    _shuffle(pool, rng)
    var nulls: Array = [str(pool[0]), str(pool[1])]
    var innocents: Array = []
    for npc_id in crew:
        if npc_id not in nulls:
            innocents.append(str(npc_id))
    _shuffle(innocents, rng)
    var herring := str(innocents[0])

    # 2. True positions during the incident window
    var positions := {}
    positions[nulls[0]] = op_rooms[0]
    positions[nulls[1]] = op_rooms[1]
    var herring_pos := str(open_positions[rng.randi_range(0, open_positions.size() - 1)])
    positions[herring] = herring_pos
    var others_positions: Array = []
    for pos in open_positions:
        if pos != herring_pos:
            others_positions.append(pos)
    # Sometimes keep one common area empty so the Nulls have a quiet place to lie about.
    var reserved_empty := ""
    if rng.randf() < 0.5:
        var empty_candidates: Array = []
        for pos in others_positions:
            if pos in common_ids:
                empty_candidates.append(pos)
        if not empty_candidates.is_empty():
            reserved_empty = str(empty_candidates[rng.randi_range(0, empty_candidates.size() - 1)])
    var fill_positions: Array = []
    for pos in others_positions:
        if pos != reserved_empty:
            fill_positions.append(pos)
    var fill_ids: Array = innocents.slice(1)
    for _attempt in range(12):
        for npc_id in fill_ids:
            positions[npc_id] = str(fill_positions[rng.randi_range(0, fill_positions.size() - 1)])
        var used := {}
        for npc_id in fill_ids:
            used[positions[npc_id]] = true
        if used.size() >= mini(2, fill_positions.size()):
            break

    var population := {}
    for pos in open_positions:
        population[pos] = []
    for npc_id in innocents:
        population[positions[npc_id]].append(npc_id)

    # 3. Claims
    var claims := {}
    for npc_id in innocents:
        if npc_id == herring:
            continue
        var mates: Array = []
        for other in population[positions[npc_id]]:
            if other != npc_id:
                mates.append(other)
        claims[npc_id] = {"position": positions[npc_id], "companions": _ordered(mates), "lie": false}

    # The innocent with a secret claims somewhere they can actually be caught.
    var herring_options: Array = []
    for pos in open_positions:
        if pos == herring_pos:
            continue
        var crowded: bool = population[pos].size() > 0
        if crowded or pos in logged_rooms:
            herring_options.append(pos)
    if herring_options.is_empty():
        for pos in open_positions:
            if pos != herring_pos:
                herring_options.append(pos)
    var herring_claim := str(herring_options[rng.randi_range(0, herring_options.size() - 1)])
    claims[herring] = {"position": herring_claim, "companions": [], "lie": true, "secret": true}

    # Nulls pick cover stories. Quiet commons first, crowded commons next, logged rooms last.
    var quiet: Array = []
    var crowded_commons: Array = []
    for pos in common_ids:
        var occupants: Array = population.get(pos, [])
        var only_herring := occupants.is_empty() or (occupants.size() == 1 and str(occupants[0]) == herring)
        if only_herring:
            quiet.append(pos)
        else:
            crowded_commons.append(pos)
    _shuffle(quiet, rng)
    _shuffle(crowded_commons, rng)
    var mutual := rng.randf() < float(data.get("mutual_alibi_chance", 0.3))
    if mutual:
        var shared := ""
        if not quiet.is_empty():
            shared = str(quiet[0])
        else:
            shared = _least_crowded(common_ids, population)
        claims[nulls[0]] = {"position": shared, "companions": [nulls[1]], "lie": true}
        claims[nulls[1]] = {"position": shared, "companions": [nulls[0]], "lie": true}
    else:
        var taken := ""
        for null_id in nulls:
            var choice := ""
            for pos in quiet:
                if pos != taken:
                    choice = str(pos)
                    break
            if choice == "":
                for pos in crowded_commons:
                    if pos != taken:
                        choice = str(pos)
                        break
            if choice == "":
                var fallback: Array = []
                for pos in logged_rooms:
                    if pos != taken:
                        fallback.append(pos)
                if fallback.is_empty():
                    fallback = logged_rooms.duplicate()
                choice = str(fallback[rng.randi_range(0, fallback.size() - 1)])
            claims[null_id] = {"position": choice, "companions": [], "lie": true}
            taken = choice

    # 4. Clues
    var clues: Array = []
    var context: Dictionary = data.get("context", {})
    _add_clue(clues, {
        "kind": "context", "room": str(context.get("room", room_ids[0])), "op": "",
        "title": str(context.get("title", "사건 기록")), "text": str(context.get("text", "")),
        "time": AstraCaseCatalog.window_text(data)
    })
    for op in ops:
        _add_clue(clues, {
            "kind": "op_record", "room": str(op.get("room", "")), "op": str(op.get("id", "")),
            "title": str(op.get("record_title", "")), "text": str(op.get("record_text", "")),
            "time": AstraCaseCatalog.format_time(int(op.get("minute", 0)), int(op.get("second", 0)))
        })
    for room_id in logged_rooms:
        var present: Array = []
        for npc_id in crew:
            if positions.get(npc_id, "") == room_id:
                present.append(npc_id)
        var names: Array = []
        for npc_id in present:
            names.append(AstraCrewCatalog.display_name(npc_id))
        var room_label := AstraCaseCatalog.room_name(data, room_id)
        var text := ""
        if names.is_empty():
            text = "%s 사이 %s 출입 인증은 한 건도 없다." % [AstraCaseCatalog.window_text(data), room_label]
        else:
            text = "%s 사이 %s 출입 인증: %s. 같은 시간대의 다른 인증은 없다." % [AstraCaseCatalog.window_text(data), room_label, ", ".join(PackedStringArray(names))]
        _add_clue(clues, {
            "kind": "access_log", "room": room_id, "op": "",
            "title": "%s 출입 기록" % room_label, "text": text,
            "log_room": room_id, "log_people": present,
            "time": AstraCaseCatalog.window_text(data)
        })

    var used_pairs := {}
    for index in range(2):
        var null_id := str(nulls[index])
        var op: Dictionary = ops[index]
        var pairs := AstraCrewCatalog.identifying_pairs(null_id)
        var pair: Array = pairs[rng.randi_range(0, pairs.size() - 1)]
        if rng.randf() < 0.5:
            pair = [pair[1], pair[0]]
        used_pairs[null_id] = pair
        var route_room := str(logged_rooms[index % logged_rooms.size()])
        if rng.randf() < 0.5:
            route_room = str(logged_rooms[(index + 1) % logged_rooms.size()])
        for step in range(2):
            var category := str(pair[step])
            var group := AstraCrewCatalog.group_of(null_id, category)
            var minute := int(op.get("minute", 0)) + (0 if step == 0 else rng.randi_range(1, 2))
            var room_id := str(op.get("room", "")) if step == 0 else route_room
            _add_clue(clues, _trace_clue(data, op, room_id, category, group, minute, step == 0, null_id, false))

    for _decoy_index in range(int(data.get("decoy_traces", 0))):
        var op_index := rng.randi_range(0, 1)
        var op: Dictionary = ops[op_index]
        var culprit := str(nulls[op_index])
        var categories: Array = AstraCrewCatalog.TRAIT_CATEGORIES.keys()
        _shuffle(categories, rng)
        var picked_category := ""
        var picked_group := ""
        for category in categories:
            var groups: Array = AstraCrewCatalog.TRAIT_CATEGORIES[category]["groups"].keys()
            _shuffle(groups, rng)
            for group in groups:
                var members: Array = AstraCrewCatalog.group_members(str(category), str(group))
                if culprit in members:
                    continue
                picked_category = str(category)
                picked_group = str(group)
                break
            if picked_category != "":
                break
        var decoy_minute := int(data.get("window_start", 0)) - rng.randi_range(38, 140)
        var decoy_room := str(room_ids[rng.randi_range(0, room_ids.size() - 1)])
        _add_clue(clues, _trace_clue(data, op, decoy_room, picked_category, picked_group, decoy_minute, decoy_room == str(op.get("room", "")), culprit, true))

    # 5. Sightings a crew member can recall when asked who they saw.
    var sightings: Array = []
    var witness_pool: Array = innocents.slice(1)
    _shuffle(witness_pool, rng)
    for sighting_index in range(mini(int(data.get("sightings", 1)), witness_pool.size())):
        var witness := str(witness_pool[sighting_index])
        var target_index := rng.randi_range(0, 1)
        var target_null := str(nulls[target_index])
        var op: Dictionary = ops[target_index]
        var pair: Array = used_pairs.get(target_null, [])
        var candidates: Array = []
        for category in AstraCrewCatalog.TRAIT_CATEGORIES.keys():
            if category in ["hand", "terminal", "clearance"]:
                continue
            candidates.append(category)
        var category := str(candidates[rng.randi_range(0, candidates.size() - 1)])
        for option in candidates:
            if option not in pair:
                category = str(option)
                break
        var group := AstraCrewCatalog.group_of(target_null, category)
        sightings.append({
            "witness": witness, "culprit": target_null, "op": str(op.get("id", "")),
            "room": str(op.get("room", "")), "category": category, "group": group,
            "members": AstraCrewCatalog.group_members(category, group).duplicate(),
            "time": AstraCaseCatalog.format_time(int(op.get("minute", 0)) - 1)
        })

    return {
        "case_id": case_id,
        "seed": seed_value,
        "nulls": nulls,
        "null_ops": {nulls[0]: str(ops[0].get("id", "")), nulls[1]: str(ops[1].get("id", ""))},
        "positions": positions,
        "claims": claims,
        "herring": herring,
        "mutual_alibi": mutual,
        "sightings": sightings,
        "clues": clues,
        "logged_rooms": logged_rooms,
        "open_positions": open_positions,
        "trace_pairs": used_pairs
    }

static func _trace_clue(data: Dictionary, op: Dictionary, room_id: String, category: String, group: String, minute: int, at_site: bool, culprit: String, decoy: bool) -> Dictionary:
    var members: Array = AstraCrewCatalog.group_members(category, group).duplicate()
    var names: Array = []
    for npc_id in members:
        names.append(AstraCrewCatalog.display_name(str(npc_id)))
    var table: Dictionary = TRACE_AT_SITE if at_site else TRACE_ON_ROUTE
    var row: Array = table.get(category, ["흔적", "{group} 흔적."])
    var params := {
        "time": AstraCaseCatalog.format_time(minute),
        "op": str(op.get("name", "")),
        "room": AstraCaseCatalog.room_name(data, room_id),
        "group": AstraCrewCatalog.group_label(category, group),
        "members": ", ".join(PackedStringArray(names))
    }
    return {
        "kind": "trace", "room": room_id, "op": str(op.get("id", "")),
        "title": str(row[0]), "text": AstraJosa.fill(str(row[1]), params),
        "time": params["time"], "minute": minute,
        "category": category, "group": group, "members": members,
        "culprit": culprit, "decoy": decoy
    }

static func _add_clue(clues: Array, clue: Dictionary) -> void:
    clue["id"] = "C%02d" % (clues.size() + 1)
    for key in ["members", "log_people"]:
        if not clue.has(key):
            clue[key] = []
    for flag in ["decoy", "planted", "found", "destroyed", "public"]:
        if not clue.has(flag):
            clue[flag] = false
    if not clue.has("culprit"):
        clue["culprit"] = ""
    if not clue.has("source"):
        clue["source"] = ""
    if not clue.has("category"):
        clue["category"] = ""
    clue["found_day"] = 0
    clues.append(clue)

static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
    for index in range(items.size() - 1, 0, -1):
        var swap := rng.randi_range(0, index)
        var temp = items[index]
        items[index] = items[swap]
        items[swap] = temp

static func _ordered(ids: Array) -> Array:
    var result: Array = []
    for npc_id in AstraCrewCatalog.ORDER:
        if npc_id in ids:
            result.append(npc_id)
    return result

static func _least_crowded(candidates: Array, population: Dictionary) -> String:
    var best := str(candidates[0])
    var best_count := 999
    for pos in candidates:
        var count: int = population.get(pos, []).size()
        if count < best_count:
            best_count = count
            best = str(pos)
    return best
