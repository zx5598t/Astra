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

const INNOCENT_SECRET_TYPES := [
    "EMBARRASSMENT", "PROTECT_OTHER", "HIDE_MISTAKE", "KEEP_PROMISE",
    "PERSONAL_SECRET", "FEAR", "MISREMEMBERED"
]

const TRACE_ON_ROUTE := {
    "clearance": ["우회 인증 조회", "{time}, {room} 보조 콘솔에서 {group} 인증이 한 번 조회됐다. {op} 직후다. {group} 보유자: {members}."],
    "fiber": ["통로 필터의 섬유", "{room|ro} 이어지는 통로 필터에서 {group} 조각이 나왔다({time} 전후). {op} 현장에서 이어진 동선이다. 이 작업복을 입는 사람: {members}."],
    "shift": ["통로 센서 기록", "{time}, {op} 현장에서 {room} 방향으로 {group} 근무 태그가 이동했다. {group} 인원: {members}."],
    "hand": ["문 패널 궤적", "{room} 출입문 패널에 {group} 궤적이 찍혔다({time}). {op} 직후다. 같은 습관을 가진 사람: {members}."],
    "terminal": ["중계 접속 기록", "{time}, {room} 중계기에 {group} 접속이 남았다. {op} 명령 직후의 접속이다. 이 단말을 쓰는 사람: {members}."]
}

static func generate(case_id: String, seed_value: int, null_history: Array = [], difficulty: String = "STANDARD") -> Dictionary:
    var data := AstraCaseCatalog.resolve(case_id, seed_value)
    if data.is_empty():
        return {}
    var rng := RandomNumberGenerator.new()
    # Hashed with the Stage id: nearby seeds (time-based, or a test's
    # arithmetic sequence) must not give correlated first draws, or the same
    # faces come up as Null far more often than others.
    rng.seed = absi(hash("%s|%d|stage" % [case_id, seed_value]))

    var crew: Array = AstraCaseCatalog.roster(data)
    var wanted_nulls := AstraCaseCatalog.null_count(data)
    var ops: Array = data.get("ops", []).slice(0, wanted_nulls)
    var room_ids: Array = []
    for room in data.get("rooms", []):
        room_ids.append(str(room.get("id", "")))
    var common_ids: Array = []
    for common in data.get("commons", []):
        common_ids.append(str(common.get("id", "")))
    var op_rooms: Array = []
    for op in ops:
        op_rooms.append(str(op.get("room", "")))
    var logged_rooms: Array = []
    for room_id in room_ids:
        if room_id not in op_rooms:
            logged_rooms.append(room_id)
    var open_positions: Array = logged_rooms + common_ids

    # 1. Hidden roles.
    # A flat shuffle lets the same face draw Null three cases running, which
    # reads as "the game has decided Jun is the villain" and kills the point of
    # re-rolling roles. `null_history` is the archive's record of recent picks:
    # a face that came up lately is weighted down, never excluded. The residual
    # randomness stays large enough that the player cannot count whose turn it
    # is (§67).
    var nulls: Array = _draw_nulls(crew, wanted_nulls, null_history, rng)
    var innocents: Array = []
    for npc_id in crew:
        if npc_id not in nulls:
            innocents.append(str(npc_id))
    _shuffle(innocents, rng)
    var herring := str(innocents[0])
    var herring_reason := str(INNOCENT_SECRET_TYPES[rng.randi_range(0, INNOCENT_SECRET_TYPES.size() - 1)])

    # 2. True positions during the incident window
    var positions := {}
    for index in range(nulls.size()):
        positions[str(nulls[index])] = op_rooms[index]
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
    if herring_reason == "MISREMEMBERED":
        claims[herring] = {
            "position": herring_claim, "companions": [], "lie": false, "secret": false,
            "misremembered": true, "innocent_reason": herring_reason
        }
    else:
        claims[herring] = {
            "position": herring_claim, "companions": [], "lie": true, "secret": true,
            "misremembered": false, "innocent_reason": herring_reason
        }

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
    # Two Nulls vouching for each other is the hardest alibi to break, so how
    # often it happens is a difficulty knob rather than a fixed case constant.
    var mutual_chance := float(data.get("mutual_alibi_chance", 0.3)) * AstraDifficulty.number(difficulty, "mutual_alibi_scale", 1.0)
    var mutual := nulls.size() >= 2 and rng.randf() < clampf(mutual_chance, 0.0, 0.95)
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
    for index in range(nulls.size()):
        var null_id := str(nulls[index])
        var op: Dictionary = ops[index]
        var pairs := AstraCrewCatalog.identifying_pairs(null_id, crew)
        if pairs.is_empty():
            pairs = AstraCrewCatalog.identifying_pairs(null_id)
        var pair: Array = pairs[rng.randi_range(0, pairs.size() - 1)]
        if rng.randf() < 0.5:
            pair = [pair[1], pair[0]]
        used_pairs[null_id] = pair
        var route_room := str(logged_rooms[index % logged_rooms.size()])
        if rng.randf() < 0.5:
            route_room = str(logged_rooms[(index + 1) % logged_rooms.size()])
        for step in range(AstraCaseCatalog.trace_steps(data)):
            var category := str(pair[step])
            var group := AstraCrewCatalog.group_of(null_id, category)
            var minute := int(op.get("minute", 0)) + (0 if step == 0 else rng.randi_range(1, 2))
            var room_id := str(op.get("room", "")) if step == 0 else route_room
            _add_clue(clues, _trace_clue(data, op, room_id, category, group, minute, step == 0, null_id, false, crew))

    # Decoys are traces from outside the incident window. 0.4.0 does not scale
    # difficulty by adding more of them: reading past more noise is not the same
    # as being outsmarted (§25). STORY halves them; STANDARD and EXPERT match 0.3.1.
    var decoy_total := int(round(float(data.get("decoy_traces", 0)) * AstraDifficulty.number(difficulty, "decoy_scale", 1.0)))
    for _decoy_index in range(decoy_total):
        var op_index := rng.randi_range(0, ops.size() - 1)
        var op: Dictionary = ops[op_index]
        var culprit := str(nulls[op_index])
        var categories: Array = AstraCrewCatalog.LEGACY_TRAIT_KEYS.duplicate()
        _shuffle(categories, rng)
        var picked_category := ""
        var picked_group := ""
        for category in categories:
            var groups: Array = AstraCrewCatalog.TRAIT_CATEGORIES[category]["groups"].keys()
            _shuffle(groups, rng)
            for group in groups:
                var members: Array = AstraCrewCatalog.group_members_in(str(category), str(group), crew)
                # A decoy has to point at somebody who is actually in this case,
                # or it reads as a bug rather than as a red herring.
                if culprit in members or members.is_empty():
                    continue
                picked_category = str(category)
                picked_group = str(group)
                break
            if picked_category != "":
                break
        var decoy_minute := int(data.get("window_start", 0)) - rng.randi_range(38, 140)
        var decoy_room := str(room_ids[rng.randi_range(0, room_ids.size() - 1)])
        _add_clue(clues, _trace_clue(data, op, decoy_room, picked_category, picked_group, decoy_minute, decoy_room == str(op.get("room", "")), culprit, true, crew))

    # 5. Sightings a crew member can recall when asked who they saw.
    var sightings: Array = []
    var witness_pool: Array = innocents.slice(1)
    _shuffle(witness_pool, rng)
    for sighting_index in range(mini(int(data.get("sightings", 1)), witness_pool.size())):
        var witness := str(witness_pool[sighting_index])
        var target_index := rng.randi_range(0, nulls.size() - 1)
        var target_null := str(nulls[target_index])
        var op: Dictionary = ops[target_index]
        var pair: Array = used_pairs.get(target_null, [])
        var candidates: Array = []
        for category in AstraCrewCatalog.LEGACY_TRAIT_KEYS:
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
            "members": AstraCrewCatalog.group_members_in(category, group, crew),
            "time": AstraCaseCatalog.format_time(int(op.get("minute", 0)) - 1)
        })

    return {
        "case_id": case_id,
        "seed": seed_value,
        "nulls": nulls,
        "null_ops": _null_ops(nulls, ops),
        "positions": positions,
        "claims": claims,
        "herring": herring,
        "herring_reason": herring_reason,
        "mutual_alibi": mutual,
        "sightings": sightings,
        "clues": clues,
        "roster": crew.duplicate(),
        "difficulty": difficulty,
        "logged_rooms": logged_rooms,
        "open_positions": open_positions,
        "trace_pairs": used_pairs
    }

const HISTORY_WINDOW := 6
const HISTORY_DAMPING := 0.55

# Weighted draw without replacement. `history` is a list of crew ids that were
# Null in recent cases, most recent last. Each appearance inside the window
# multiplies that face's weight by HISTORY_DAMPING, so three recent turns leave
# it at ~17% of a fresh face rather than excluding it. Nobody is ever locked
# out, and nobody is ever due, so "whose turn is it" stays unanswerable.
static func _draw_nulls(crew: Array, wanted: int, history: Array, rng: RandomNumberGenerator) -> Array:
    var recent: Array = history.slice(maxi(0, history.size() - HISTORY_WINDOW))
    var pool: Array = crew.duplicate()
    var chosen: Array = []
    for _pick in range(mini(wanted, pool.size())):
        var weights: Array = []
        var total := 0.0
        for npc_id in pool:
            var weight := 1.0
            for entry in recent:
                if str(entry) == str(npc_id):
                    weight *= HISTORY_DAMPING
            # Jitter keeps the ordering of two similarly-weighted faces from
            # being a function of history alone.
            weight *= rng.randf_range(0.85, 1.15)
            weights.append(weight)
            total += weight
        var roll := rng.randf() * total
        var index := pool.size() - 1
        for position in range(weights.size()):
            roll -= float(weights[position])
            if roll <= 0.0:
                index = position
                break
        chosen.append(str(pool[index]))
        pool.remove_at(index)
    return chosen

static func _null_ops(nulls: Array, ops: Array) -> Dictionary:
    var mapping := {}
    for index in range(nulls.size()):
        mapping[str(nulls[index])] = str(ops[index].get("id", ""))
    return mapping

static func _trace_clue(data: Dictionary, op: Dictionary, room_id: String, category: String, group: String, minute: int, at_site: bool, culprit: String, decoy: bool, roster: Array = []) -> Dictionary:
    var members: Array = AstraCrewCatalog.group_members_in(category, group, roster)
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

# ================================================================ 0.8.0 DAY PACKET
#
# generate() above still produces the Stage truth: who the Nulls are (drawn with
# history damping) for the whole Stage. The Null role never changes inside a
# Stage. Everything that happens on one Day is a separate Day Packet:
#
#   * one incident (authored per Stage, AstraStageStory.INCIDENTS)
#   * where every active crew member really was at the incident time
#   * what each of them claims (honest crew tell the truth; the acting Null,
#     a covering Null and at most one innocent with a benign secret do not)
#   * three to six information fragments, each owned by the person who knows it
#     (a witness, a record keeper, an expert, someone who heard it, or a Null's
#     own deception)
#
# The packet is deterministic for (stage seed, day, active roster, living
# Nulls) and is also stored in the snapshot, so a reload never re-rolls it.
# Fairness contract (validate_day_packet):
#   A  the acting Null is implicated by at least one fragment an innocent holds
#   B  that evidence comes from two independent owners, or a record with a
#      living backup owner, so one death cannot erase the only path
#   C  on Day 1 at most one piece of actor evidence names the actor outright
#   D  group-level evidence intersects to the actor (solvable in principle)
#   E/F innocents can look guilty (benign lie, frame) and every such lie is
#      catchable, so "lied" never simply equals "Null"

const PACKET_VERSION := 1
const WITNESS_CATEGORIES := ["fiber", "hand", "shift", "hair"]

# What kind of social problem each Stage leans on (§71, §73). The rules are
# the same everywhere; the pressure is not.
#   CALIBRATION   one clear contradiction (few benign lies, little hearsay)
#   DEAD_AIR      people hiding things for each other (benign lies)
#   GLASS_GARDEN  direct sighting vs retold sighting (distorted hearsay)
#   ECHO_WARD     time and place (more frames that place people wrongly)
#   Part II       two Nulls; mixes of the above, heavier late
const STAGE_THEMES := {
    "CALIBRATION": {"benign_day1": 0.35, "benign_later": 0.3, "hearsay_chance": 0.3, "hearsay_distort": 0.0},
    "DEAD_AIR": {"benign_day1": 0.95, "benign_later": 0.7, "hearsay_chance": 0.45, "hearsay_distort": 0.1},
    "GLASS_GARDEN": {"benign_day1": 0.5, "benign_later": 0.45, "hearsay_chance": 0.9, "hearsay_overnight": 0.8, "hearsay_distort": 0.55},
    "ECHO_WARD": {"benign_day1": 0.55, "benign_later": 0.5, "hearsay_chance": 0.6, "hearsay_distort": 0.25, "frame_bonus": 0.2, "specific_scale": 0.35},
    "SILENT_ORBIT": {"hearsay_distort": 0.25, "frame_bonus": 0.1},
    "RED_SHIFT": {"benign_day1": 0.75, "hearsay_distort": 0.3},
    "LAST_LIGHT": {"hearsay_distort": 0.3, "frame_bonus": 0.15},
    "SECOND_WATCH": {"benign_day1": 0.7, "hearsay_distort": 0.3},
    "BORROWED_DAYS": {"benign_day1": 0.8, "benign_later": 0.6, "hearsay_distort": 0.25},
    "BLIND_DECK": {"hearsay_chance": 0.7, "hearsay_distort": 0.4, "frame_bonus": 0.15},
    "THREE_MINUTES_DARK": {"hearsay_chance": 0.85, "hearsay_overnight": 0.6, "hearsay_distort": 0.5},
    "CONTINUITY": {"benign_day1": 0.75, "hearsay_distort": 0.3, "frame_bonus": 0.1},
    "THRESHOLD": {"benign_day1": 0.7, "hearsay_distort": 0.4, "frame_bonus": 0.2}
}
# What a log can tell about whoever triggered it. Corridor motion sensors read
# the cabin-wing field of a crew tag, not the person.
const RECORD_CATEGORY := {"terminal":"terminal", "door":"clearance", "power":"clearance", "comms":"terminal",
    "motion":"wing", "vitals":"shift", "environment":"shift", "system":"clearance"}
const RECORD_DEVICE := {"terminal":"개인 단말 접속 기록", "door":"출입 인증 기록", "power":"분배반 조작 기록",
    "comms":"통신 채널 접속 기록", "motion":"통로 이동 센서", "vitals":"생체 태그 기록",
    "environment":"구역 대기 센서", "system":"시스템 감사 로그"}
const BENIGN_REASONS := ["EMBARRASSMENT", "PROTECT_OTHER", "HIDE_MISTAKE", "KEEP_PROMISE", "PERSONAL_SECRET", "FEAR", "MISREMEMBERED"]

static func generate_day_packet(case_id: String, stage_seed: int, day: int, active: Array, living_nulls: Array, difficulty: String = "STANDARD", heat: Dictionary = {}) -> Dictionary:
    var last: Dictionary = {}
    for attempt in range(80):
        last = _build_day_packet(case_id, stage_seed, day, active, living_nulls, difficulty, heat, attempt)
        if validate_day_packet(last, active, living_nulls).is_empty():
            return last
    return last

static func _packet_rng(case_id: String, stage_seed: int, day: int, attempt: int) -> RandomNumberGenerator:
    var rng := RandomNumberGenerator.new()
    rng.seed = absi(hash("%s|%d|day%d|%d" % [case_id, stage_seed, day, attempt]))
    return rng

static func _build_day_packet(case_id: String, stage_seed: int, day: int, active: Array, living_nulls: Array, difficulty: String, heat: Dictionary, attempt: int) -> Dictionary:
    var rng := _packet_rng(case_id, stage_seed, day, attempt)
    var incident := AstraStageStory.incident(case_id, day)
    var room := str(incident.get("room", "medbay"))
    var data := AstraCaseCatalog.get_case(case_id)
    var loc_ids: Array = []
    for entry in data.get("rooms", []):
        if str(entry.get("id", "")) not in loc_ids:
            loc_ids.append(str(entry.get("id", "")))
    for entry in data.get("commons", []):
        if str(entry.get("id", "")) not in loc_ids:
            loc_ids.append(str(entry.get("id", "")))
    if room not in loc_ids:
        loc_ids.append(room)
    if "quarters" not in loc_ids:
        loc_ids.append("quarters")
    var locations := {}
    for id in loc_ids:
        var name := AstraCaseCatalog.room_name(data, str(id))
        locations[str(id)] = name if name != str(id) else AstraStageStory.location_name(str(id))
    var others: Array = []
    for id in loc_ids:
        if str(id) != room:
            others.append(str(id))
    var time_text := AstraCaseCatalog.format_time(int(incident.get("minute", 0)))
    var time_before := AstraCaseCatalog.format_time(int(incident.get("minute", 0)) - 2)

    # ---- who acts today. Nulls alternate by Day, so in a two-Null Stage both
    # of them act (and leave evidence) within two Days.
    var nulls: Array = []
    for id in AstraCrewCatalog.ORDER:
        if id in living_nulls and id in active:
            nulls.append(id)
    var innocents: Array = []
    for id in AstraCrewCatalog.ORDER:
        if id in active and id not in nulls:
            innocents.append(id)
    if nulls.is_empty() or innocents.is_empty():
        return {"version": PACKET_VERSION, "day": day, "incident": incident, "locations": locations, "positions": {}, "claims": {}, "fragments": [], "actor": "", "empty": true}
    var order := nulls.duplicate()
    var stage_rng := RandomNumberGenerator.new()
    stage_rng.seed = absi(hash("%s|%d|actors" % [case_id, stage_seed]))
    _shuffle(order, stage_rng)
    var actor := str(order[(day - 1) % order.size()])
    var cover := ""
    for id in order:
        if str(id) != actor:
            cover = str(id)


    # ---- true positions at the incident time
    # At night most people are asleep in their own cabin, alone; during working
    # hours they are at stations, often in pairs. A cabin is a location of its
    # own ("준의 선실"), so sleeping alone is an alibi nobody can confirm, not a
    # place two people can contradict each other about.
    var minute := int(incident.get("minute", 0))
    var night := minute < 360 or minute >= 1320
    for id in active:
        locations["cabin:" + str(id)] = "%s의 선실" % AstraCrewCatalog.display_name(str(id))
    var positions := {}
    positions[actor] = room
    var pool := innocents.duplicate()
    _shuffle(pool, rng)
    var sizes: Array = []
    var remaining := pool.size()
    var need_alone := pool.size() >= 3
    var pair_chance := 0.34 if night else 0.66
    while remaining > 0:
        var size := 1
        if need_alone:
            need_alone = false
        elif remaining >= 2 and rng.randf() < pair_chance:
            size = 2
        sizes.append(size)
        remaining -= size
    _shuffle(sizes, rng)
    var loc_order := others.duplicate()
    _shuffle(loc_order, rng)
    var cursor := 0
    var station := 0
    for index in range(sizes.size()):
        if int(sizes[index]) == 1 and rng.randf() < (0.72 if night else 0.3):
            var sleeper := str(pool[cursor])
            positions[sleeper] = "cabin:" + sleeper
            cursor += 1
            continue
        var loc := str(loc_order[station % loc_order.size()])
        station += 1
        for _k in range(int(sizes[index])):
            positions[str(pool[cursor])] = loc
            cursor += 1
    if cover != "":
        positions[cover] = "cabin:" + cover if rng.randf() < (0.6 if night else 0.25) else str(loc_order[rng.randi_range(0, loc_order.size() - 1)])

    # ---- honest claims: exactly the truth, with everyone really in the same place
    var claims := {}
    for id in active:
        var mates: Array = []
        for other in active:
            if other != id and str(positions.get(other, "")) == str(positions.get(id, "")):
                mates.append(other)
        claims[str(id)] = {"position": str(positions.get(id, "")), "companions": _ordered(mates), "lie": false, "kind": "honest", "reason": ""}

    # ---- the acting Null's cover story. Mostly somewhere nobody can check
    # (their own cabin at night, an empty station by day). Claiming a room
    # someone else was in is a mistake a Null rarely makes.
    var occupied := {}
    for id in positions:
        occupied[str(positions[id])] = true
    var quiet: Array = []
    for id in others:
        if not occupied.has(id):
            quiet.append(id)
    if night or quiet.is_empty():
        quiet.append("cabin:" + actor)
        if night:
            quiet.append("cabin:" + actor)
    var crowded: Array = []
    for id in others:
        var count := 0
        for other in innocents:
            if str(positions.get(other, "")) == id:
                count += 1
        if count >= 1:
            crowded.append(id)
    var mutual_chance := 0.0
    if cover != "":
        mutual_chance = clampf(0.3 * AstraDifficulty.number(difficulty, "mutual_alibi_scale", 1.0), 0.0, 0.7)
    # "Borrowed" (§12): the Null claims it was with someone who was really
    # alone at a station. The other person honestly says they were alone, the
    # same shape of contradiction a harmless liar leaves the other way round,
    # so "the one whose company is denied is always innocent" stops being a rule.
    var lonely: Array = []
    for id in innocents:
        var spot := str(positions.get(id, ""))
        if spot.begins_with("cabin:") or spot == room:
            continue
        var together := 0
        for other in innocents:
            if str(positions.get(other, "")) == spot:
                together += 1
        if together == 1:
            lonely.append(str(id))
    var style := "quiet"
    var roll := rng.randf()
    if cover != "" and roll < mutual_chance:
        style = "mutual"
    elif not crowded.is_empty() and roll < mutual_chance + 0.14:
        style = "crowded"
    elif not lonely.is_empty() and roll < mutual_chance + 0.14 + 0.18:
        style = "borrowed"
    var actor_claim := str(quiet[rng.randi_range(0, quiet.size() - 1)])
    if style == "crowded":
        actor_claim = str(crowded[rng.randi_range(0, crowded.size() - 1)])
    if style == "mutual":
        var shared: Array = []
        for id in others:
            if not occupied.has(id):
                shared.append(id)
        actor_claim = str(shared[rng.randi_range(0, shared.size() - 1)]) if not shared.is_empty() else str(others[0])
    var borrowed := ""
    if style == "borrowed":
        borrowed = str(lonely[rng.randi_range(0, lonely.size() - 1)])
        actor_claim = str(positions[borrowed])
    claims[actor] = {"position": actor_claim, "companions": [borrowed] if borrowed != "" else [], "lie": true, "kind": "null", "reason": "NULL"}
    if style == "mutual":
        claims[actor]["companions"] = [cover]
        claims[cover] = {"position": actor_claim, "companions": [actor], "lie": str(positions[cover]) != actor_claim, "kind": "cover", "reason": "NULL_COVER"}
    # ---- evidence against the actor: one witness, one record, independent owners
    var fragments: Array = []
    var witness_pool: Array = innocents.duplicate()
    _shuffle(witness_pool, rng)
    var witness := str(witness_pool[0])
    var record_types: Array = Array(incident.get("records", ["system"])).duplicate()
    _shuffle(record_types, rng)
    # Ship-wide sensors are always there too; an incident's own logs come first.
    var generic: Array = ["motion", "vitals", "environment", "terminal"]
    _shuffle(generic, rng)
    for type in generic:
        if str(type) not in record_types:
            record_types.append(str(type))
    var incident_records: int = Array(incident.get("records", ["system"])).size()
    var record_options: Array = []
    for index in range(record_types.size()):
        var type := str(record_types[index])
        var owner := AstraCrewCatalog.record_owner(type)
        var backup := str(AstraCrewCatalog.RECORD_BACKUP.get(type, ""))
        if owner in innocents and owner != witness:
            record_options.append({"type": type, "owner": owner, "backup": backup if backup in innocents and backup != owner else "", "generic": index >= incident_records})
        elif backup in innocents and backup != witness:
            record_options.append({"type": type, "owner": backup, "backup": "", "generic": index >= incident_records})
    if record_options.is_empty():
        # Nobody whose job produces a record is awake and trustworthy today:
        # the audit log is pulled by whoever is left.
        for id in witness_pool:
            if str(id) != witness:
                record_options.append({"type": "system", "owner": str(id), "backup": "", "generic": false})
                break

    # ---- the evidence curve (§3, §4). How far today's two traces narrow the
    # room is drawn per Day, not fixed: Day 1 usually leaves two or three
    # people, Day 2 one or two, later Days mostly one. Across Days the same
    # actor sits in every set, so remembering yesterday narrows today's. A
    # sighting or a log that names the actor outright is a rare gift, not the
    # fallback for a small roster: the record and the kind of sighting are
    # chosen together to land as close to the Day's curve as the roster allows.
    var want := _narrow_target(case_id, day, rng)
    var specific_scale := float(STAGE_THEMES.get(case_id, {}).get("specific_scale", 1.0))
    var w_specific := rng.randf() < float([0.12, 0.18, 0.24][clampi(day - 1, 0, 2)]) * specific_scale
    var e_specific := rng.randf() < float([0.05, 0.12, 0.18][clampi(day - 1, 0, 2)]) * specific_scale
    if w_specific and e_specific:
        e_specific = false
    var record_type := ""
    var record_owner := ""
    var record_backup := ""
    var w_group := {}
    var e_group := {}
    var best_cost := 99.0
    for option in record_options:
        var pick := _pick_groups(actor, active, str(option["type"]), w_specific, e_specific, want, rng)
        var left := _left_after(pick, w_specific, e_specific)
        # An incident's own log reads better than a ship-wide sensor.
        var cost := absf(float(left - want)) + (0.1 if left > want else 0.0) + (0.05 if bool(option["generic"]) else 0.0)
        if cost < best_cost:
            best_cost = cost
            record_type = str(option["type"])
            record_owner = str(option["owner"])
            record_backup = str(option["backup"])
            w_group = pick.get("w", {})
            e_group = pick.get("e", {})
    # In a small room every log may name the actor (nobody else awake shares
    # their credential). Then a second passer-by who noticed something else
    # takes the log's place: two partial sightings that only together narrow
    # the room, and testimony needs a second voice before the crew leans on it.
    var second_witness := ""
    var second_group := {}
    if not w_specific and not e_specific and best_cost >= 1.0 and want >= 2:
        var pair := _pick_second_sighting(actor, active, str(w_group.get("category", "")), want)
        if not pair.is_empty():
            for id in witness_pool:
                if str(id) != witness:
                    second_witness = str(id)
                    break
            if second_witness != "":
                if w_group.is_empty():
                    w_group = pair["first"]
                second_group = pair["second"]
                record_owner = ""
    if not w_specific and w_group.is_empty():
        w_specific = true
    if not e_specific and e_group.is_empty():
        e_specific = true
    if w_specific and e_specific and not e_group.is_empty():
        e_specific = false
    fragments.append(_fragment_witness(witness, actor, w_specific, w_group, room, time_before, locations))
    if second_witness != "":
        fragments.append(_fragment_witness(second_witness, actor, false, second_group, room, time_text, locations))
    elif record_owner != "":
        fragments.append(_fragment_record(record_owner, record_backup, record_type, actor, e_specific, e_group, room, time_text, locations))

    # ---- an expert who can say what the method really requires
    var method := AstraStageStory.method(str(incident.get("method", "manual_console")))
    for expert in method.get("experts", []):
        if str(expert) in innocents and rng.randf() < 0.72:
            fragments.append({"type":"EXPERT_INFERENCE", "owner":str(expert), "subject":"", "specific":false, "group":{},
                "room":room, "time":time_text, "record_type":"", "strength":0.22, "category":"EXPERT_INFERENCE",
                "points_to":[], "refutes":actor, "excuse":str(method.get("excuse", "remote")),
                "text":str(method.get("fact", ""))})
            break

    # ---- hearsay: the witness told someone. Retold, a detail can change:
    # the listener remembers the wrong kind of uniform (§73, Stage 3 theme).
    # Asking the witness directly is how the player finds out.
    var theme: Dictionary = STAGE_THEMES.get(case_id, {})
    var w_mates: Array = claims[witness]["companions"]
    var hearsay_pool: Array = w_mates.duplicate()
    if hearsay_pool.is_empty() and rng.randf() < float(theme.get("hearsay_overnight", 0.0)):
        for id in innocents:
            if str(id) not in [witness, record_owner]:
                hearsay_pool.append(str(id))
    if not hearsay_pool.is_empty() and rng.randf() < float(theme.get("hearsay_chance", 0.55)):
        var listener := str(hearsay_pool[rng.randi_range(0, hearsay_pool.size() - 1)])
        if listener in innocents and listener != record_owner:
            var heard_group := w_group.duplicate(true)
            var heard_points: Array = [actor] if w_specific else Array(w_group.get("members", [])).duplicate()
            var heard_subject := actor if w_specific else ""
            var distorted := false
            if not w_specific and not w_group.is_empty() and rng.randf() < float(theme.get("hearsay_distort", 0.2)):
                var category := str(w_group.get("category", ""))
                for group_id in Dictionary(AstraCrewCatalog.TRAIT_CATEGORIES.get(category, {}).get("groups", {})):
                    if str(group_id) == str(w_group.get("group", "")):
                        continue
                    var others_in := AstraCrewCatalog.group_members_in(category, str(group_id), active)
                    if others_in.size() >= 1 and actor not in others_in:
                        heard_group = {"category": category, "group": str(group_id), "members": others_in}
                        heard_points = others_in.duplicate()
                        distorted = true
                        break
            fragments.append({"type":"HEARSAY", "owner":listener, "via":witness, "subject":heard_subject,
                "specific":w_specific, "group":heard_group, "room":room, "time":time_before, "record_type":"", "strength":0.18,
                "category":"HEARSAY", "points_to":heard_points, "distorted":distorted,
                "refutes":"", "text":"%s의 전언: %s|i 그 시간쯤 %s %s 쪽으로 가는 걸 봤다고 했다." % [AstraCrewCatalog.display_name(listener), AstraCrewCatalog.display_name(witness),
                    (AstraCrewCatalog.display_name(actor) + "|i") if w_specific else witness_phrase(str(heard_group.get("category", "")), str(heard_group.get("group", ""))),
                    str(locations.get(room, room))]})

    # ---- a Null's deception: framing an innocent with a false sighting
    var framer := ""
    var scapegoat := ""
    var frame_chance := minf(0.88, 0.26 + 0.14 * day + float(theme.get("frame_bonus", 0.0)))
    if rng.randf() < frame_chance:
        framer = actor if cover == "" or rng.randf() < 0.55 else cover
        var candidates: Array = []
        for id in innocents:
            if str(id) != witness:
                candidates.append(str(id))
        if candidates.is_empty():
            candidates = innocents.duplicate()
        # A Null frames someone nobody can vouch for: an alibi-less innocent
        # is the safe target. The frame stays refutable through a record.
        var jitter := {}
        for id in candidates:
            var alone := Array(claims[id]["companions"]).is_empty()
            jitter[id] = float(heat.get(id, 0.0)) + rng.randf() * 0.2 + (0.6 if alone else 0.0)
        candidates.sort_custom(func(a, b): return float(jitter[a]) > float(jitter[b]))
        scapegoat = str(candidates[0])
        fragments.append({"type":"NULL_DECEPTION", "owner":framer, "subject":scapegoat, "specific":true, "group":{},
            "room":room, "time":time_before, "record_type":"", "strength":0.5, "category":"DIRECT_WITNESS",
            "points_to":[scapegoat], "refutes":scapegoat, "false":true,
            "text":"%s의 증언: %s쯤 %s|i %s 쪽으로 가는 것을 봤다." % [AstraCrewCatalog.display_name(framer), time_before, AstraCrewCatalog.display_name(scapegoat), str(locations.get(room, room))]})
        # A frame must be refutable. With companions it already is; alone, a
        # record keeps the scapegoat where they said they were.
        if Array(claims[scapegoat]["companions"]).is_empty():
            var keeper := _locating_keeper(scapegoat, innocents, [witness], rng)
            if keeper != "":
                var keeper_type := str(AstraCrewCatalog.RECORD_DOMAIN.get(keeper, "system"))
                if keeper_type in ["power", "system"]:
                    keeper_type = "system"
                fragments.append({"type":"ALIBI_SUPPORT", "owner":keeper, "subject":scapegoat, "specific":true, "group":{},
                    "room":str(positions[scapegoat]), "time":time_before, "record_type":keeper_type, "strength":0.45,
                    "category":"TIMELINE", "points_to":[], "supports":scapegoat, "refutes":framer,
                    "text":"%s · %s: %s|i %s에 있었다." % [str(RECORD_DEVICE.get(keeper_type, "기록")), time_before, AstraCrewCatalog.display_name(scapegoat), _place_of(scapegoat, str(positions[scapegoat]), locations)]})

    # ---- at most one innocent with a benign reason to lie
    var benign := {}
    var benign_chance := float(theme.get("benign_day1", 0.62)) if day == 1 else float(theme.get("benign_later", 0.46))
    var benign_pool: Array = []
    for id in innocents:
        if str(id) not in [witness, record_owner, scapegoat]:
            benign_pool.append(str(id))
    if not benign_pool.is_empty() and rng.randf() < benign_chance:
        var liar := str(benign_pool[rng.randi_range(0, benign_pool.size() - 1)])
        var reason := str(BENIGN_REASONS[rng.randi_range(0, BENIGN_REASONS.size() - 1)])
        var true_pos := str(positions[liar])
        var options: Array = []
        for id in others:
            if id != true_pos and id != room:
                options.append(id)
        var own_cabin := "cabin:" + liar
        if true_pos != own_cabin:
            # "I was asleep" is the lie that comes first to mind.
            options.append(own_cabin)
            options.append(own_cabin)
        if not options.is_empty():
            var fake := str(options[rng.randi_range(0, options.size() - 1)])
            var misremembered := reason == "MISREMEMBERED"
            claims[liar] = {"position": fake, "companions": [], "lie": not misremembered, "kind": "benign",
                "reason": reason, "misremembered": misremembered, "true_position": true_pos}
            benign = {"npc": liar, "reason": reason, "true_position": true_pos, "claimed": fake, "misremembered": misremembered}
            var had_mates: Array = []
            for other in innocents:
                if str(other) != liar and str(positions.get(other, "")) == true_pos:
                    had_mates.append(str(other))
            if had_mates.is_empty():
                var spotter := _alibi_keeper(liar, innocents, [witness, liar], rng)
                if spotter != "":
                    fragments.append({"type":"BENIGN_EXPOSURE", "owner":spotter, "subject":liar, "specific":true, "group":{},
                        "room":true_pos, "time":time_before, "record_type":str(AstraCrewCatalog.RECORD_DOMAIN.get(spotter, "")),
                        "strength":0.36, "category":"TIMELINE", "points_to":[liar], "refutes":liar,
                        "text":"%s의 관찰: %s쯤 %s|i %s에 있었다." % [AstraCrewCatalog.display_name(spotter), time_before, AstraCrewCatalog.display_name(liar), _place_of(liar, true_pos, locations)]})

    # ---- an honest mistake (§8): an innocent is sure they saw someone who
    # was elsewhere, a look-alike in the dark (same uniform, hair or hand as
    # the one who really went). Refutable exactly like a Null's false
    # sighting, so "the sighting turned out false" no longer names the Null.
    # One false sighting a Day at most: a Null's frame or an honest mistake.
    if framer == "" and rng.randf() < 0.2 + float(theme.get("frame_bonus", 0.0)):
        var seers: Array = []
        for id in innocents:
            if str(id) not in [witness, scapegoat, str(benign.get("npc", ""))]:
                seers.append(str(id))
        if not seers.is_empty():
            var seer := str(seers[rng.randi_range(0, seers.size() - 1)])
            var look_alikes: Array = []
            for id in innocents:
                if str(id) == seer or str(positions.get(id, "")) == room:
                    continue
                for category in ["fiber", "hair", "hand"]:
                    if AstraCrewCatalog.group_of(str(id), category) == AstraCrewCatalog.group_of(actor, category):
                        look_alikes.append(str(id))
                        break
            if not look_alikes.is_empty():
                var mistaken := str(look_alikes[rng.randi_range(0, look_alikes.size() - 1)])
                fragments.append({"type":"NULL_DECEPTION", "owner":seer, "subject":mistaken, "specific":true, "group":{},
                    "room":room, "time":time_before, "record_type":"", "strength":0.45, "category":"DIRECT_WITNESS",
                    "points_to":[mistaken], "refutes":mistaken, "false":true, "mistaken":true,
                    "text":"%s의 증언: %s쯤 %s|i %s 쪽으로 가는 것을 봤다." % [AstraCrewCatalog.display_name(seer), time_before, AstraCrewCatalog.display_name(mistaken), str(locations.get(room, room))]})
                if Array(claims[mistaken]["companions"]).is_empty():
                    var keeper := _locating_keeper(mistaken, innocents, [seer], rng)
                    if keeper != "":
                        var keeper_type := str(AstraCrewCatalog.RECORD_DOMAIN.get(keeper, "system"))
                        if keeper_type in ["power", "system"]:
                            keeper_type = "system"
                        fragments.append({"type":"ALIBI_SUPPORT", "owner":keeper, "subject":mistaken, "specific":true, "group":{},
                            "room":str(positions[mistaken]), "time":time_before, "record_type":keeper_type, "strength":0.45,
                            "category":"TIMELINE", "points_to":[], "supports":mistaken, "refutes":seer,
                            "text":"%s · %s: %s|i %s에 있었다." % [str(RECORD_DEVICE.get(keeper_type, "기록")), time_before, AstraCrewCatalog.display_name(mistaken), _place_of(mistaken, str(positions[mistaken]), locations)]})

    # ---- ordinary things people noticed a little earlier (§12): true and
    # harmless, held by anyone awake, a Null included. They lend a little
    # weight to someone's story, and keep "the one who saw nothing is the
    # Null" from being a rule.
    var routine_count := (1 if rng.randf() < 0.75 else 0) + (1 if active.size() >= 6 and rng.randf() < 0.45 else 0)
    var holders := {}
    for fragment in fragments:
        holders[str(fragment.get("owner", ""))] = true
    for _k in range(routine_count):
        # A Day stays readable: at most nine pieces in all (a covering Null's
        # trail can still follow).
        if fragments.size() >= 8:
            break
        var observers: Array = []
        for id in active:
            if not holders.has(str(id)):
                observers.append(str(id))
        if observers.is_empty():
            break
        var observer := str(observers[rng.randi_range(0, observers.size() - 1)])
        # A Null with nothing to say would stand out by its silence alone.
        for id in nulls:
            if str(id) in observers and rng.randf() < 0.5:
                observer = str(id)
                break
        var seen_options: Array = []
        for id in innocents:
            var spot := str(positions.get(id, ""))
            if str(id) == observer or spot == room or str(claims[id].get("kind", "honest")) != "honest":
                continue
            seen_options.append(str(id))
        if seen_options.is_empty():
            break
        var seen := str(seen_options[rng.randi_range(0, seen_options.size() - 1)])
        var earlier := AstraCaseCatalog.format_time(minute - rng.randi_range(9, 22))
        holders[observer] = true
        fragments.append({"type":"ROUTINE", "owner":observer, "subject":seen, "specific":true, "group":{},
            "room":str(positions[seen]), "time":earlier, "record_type":"", "strength":0.2, "category":"CORROBORATED",
            "points_to":[], "supports":seen, "refutes":"",
            "text":"%s의 관찰: %s쯤 %s|i %s 쪽으로 가는 걸 봤다." % [AstraCrewCatalog.display_name(observer), earlier, AstraCrewCatalog.display_name(seen), _place_of(seen, str(positions[seen]), locations)]})

    # ---- a covering Null leaves a thin trail of their own
    if style == "mutual" and rng.randf() < 0.6:
        var seer := _alibi_keeper(cover, innocents, [witness], rng)
        if seer != "":
            fragments.append({"type":"COVER_EXPOSURE", "owner":seer, "subject":cover, "specific":true, "group":{},
                "room":str(positions[cover]), "time":time_before, "record_type":str(AstraCrewCatalog.RECORD_DOMAIN.get(seer, "")),
                "strength":0.34, "category":"TIMELINE", "points_to":[cover], "refutes":cover,
                "text":"%s의 관찰: %s쯤 %s|i %s에 있었다." % [AstraCrewCatalog.display_name(seer), time_before, AstraCrewCatalog.display_name(cover), _place_of(cover, str(positions[cover]), locations)]})

    var index := 0
    for fragment in fragments:
        index += 1
        fragment["id"] = "D%dF%d" % [day, index]
        fragment["day"] = day
        fragment["text"] = josa_inline(str(fragment.get("text", "")))
    return {
        "version": PACKET_VERSION, "day": day, "case_id": case_id,
        "incident": incident, "time": time_text, "time_before": time_before,
        "locations": locations, "positions": positions, "claims": claims,
        "fragments": fragments, "actor": actor, "cover": cover, "cover_style": style,
        "witness": witness, "record_owner": record_owner, "record_type": record_type,
        "framer": framer, "scapegoat": scapegoat, "benign": benign
    }

# Someone other than `subject` who can honestly place them. Deterministic for
# the packet rng.
static func _alibi_keeper(subject: String, innocents: Array, exclude: Array, rng: RandomNumberGenerator) -> String:
    var options: Array = []
    for id in innocents:
        if str(id) != subject and str(id) not in exclude:
            options.append(str(id))
    if options.is_empty():
        return ""
    return str(options[rng.randi_range(0, options.size() - 1)])

# Two different things passers-by noticed (a uniform, a hand, a shift tag)
# whose groups together leave the number of people closest to `want`.
static func _pick_second_sighting(actor: String, active: Array, first_category: String, want: int) -> Dictionary:
    var best := {}
    var best_cost := 99.0
    for c1 in WITNESS_CATEGORIES:
        if first_category != "" and str(c1) != first_category:
            continue
        var m1 := AstraCrewCatalog.group_members_in(str(c1), AstraCrewCatalog.group_of(actor, str(c1)), active)
        if m1.size() < 2:
            continue
        for c2 in WITNESS_CATEGORIES:
            if str(c2) == str(c1):
                continue
            var m2 := AstraCrewCatalog.group_members_in(str(c2), AstraCrewCatalog.group_of(actor, str(c2)), active)
            if m2.size() < 2:
                continue
            var left := 0
            for id in m1:
                if id in m2:
                    left += 1
            if left > 3:
                continue
            var cost := absf(float(left - want)) + (0.1 if left > want else 0.0)
            if cost < best_cost:
                best_cost = cost
                best = {"first": {"category": str(c1), "group": AstraCrewCatalog.group_of(actor, str(c1)), "members": m1},
                    "second": {"category": str(c2), "group": AstraCrewCatalog.group_of(actor, str(c2)), "members": m2}, "cost": cost}
    if best.is_empty() or float(best["cost"]) >= 1.0:
        return {}
    return best

# How many people a pick of traces leaves together.
static func _left_after(pick: Dictionary, w_specific: bool, e_specific: bool) -> int:
    var w: Dictionary = pick.get("w", {})
    var e: Dictionary = pick.get("e", {})
    if w_specific or w.is_empty() or e_specific:
        return 1
    if e.is_empty():
        return 1
    var left := 0
    for id in w.get("members", []):
        if id in Array(e.get("members", [])):
            left += 1
    return maxi(1, left)

# How many people today's traces should leave, drawn per Day (§3, §4). The
# first Stage teaches the loop, so its Day 1 lands on one person more often.
# 1.0: a single trace rarely names one person. Two independent traces (a log
# and a sighting, held by different people) meet at the actor; connecting them
# is the reasoning the explorer does. Day 3+ still usually narrows to one.
const NARROW_CURVE := {
    1: [0.05, 0.50, 0.45],
    2: [0.20, 0.62, 0.18],
    3: [0.55, 0.45, 0.00]
}

static func _narrow_target(case_id: String, day: int, rng: RandomNumberGenerator) -> int:
    var weights: Array = NARROW_CURVE[clampi(day, 1, 3)]
    if day == 1 and AstraCaseCatalog.stage_index(case_id) <= 1:
        weights = [0.45, 0.55, 0.0]
    var roll := rng.randf()
    var acc := 0.0
    for index in range(weights.size()):
        acc += float(weights[index])
        if roll < acc:
            return index + 1
    return 1

# Witness category (what you see of someone passing) and record category (what
# a log can tell about a credential). Each group-level trace holds at least two
# people, or it would name the actor outright; together they leave the number
# of people closest to `want` (never more than three).
static func _pick_groups(actor: String, active: Array, record_type: String, w_specific: bool, e_specific: bool, want: int, rng: RandomNumberGenerator) -> Dictionary:
    var e_category := str(RECORD_CATEGORY.get(record_type, "clearance"))
    var e_members := AstraCrewCatalog.group_members_in(e_category, AstraCrewCatalog.group_of(actor, e_category), active)
    var e_spec := {"category": e_category, "group": AstraCrewCatalog.group_of(actor, e_category), "members": e_members} if e_members.size() >= 2 else {}
    if w_specific:
        return {"w": {}, "e": e_spec}
    var record_narrows := not e_specific and not e_spec.is_empty()
    var w_options: Array = WITNESS_CATEGORIES.duplicate()
    _shuffle(w_options, rng)
    var best := {}
    var best_cost := 99.0
    for category in w_options:
        var members := AstraCrewCatalog.group_members_in(str(category), AstraCrewCatalog.group_of(actor, str(category)), active)
        if members.size() < 2:
            continue
        var left := 1
        if record_narrows:
            left = 0
            for id in members:
                if id in e_members:
                    left += 1
        elif not e_specific:
            left = members.size()
        if left > 3:
            continue
        var cost := absf(float(left - want)) + (0.1 if left > want else 0.0)
        if cost < best_cost:
            best_cost = cost
            best = {"category": str(category), "group": AstraCrewCatalog.group_of(actor, str(category)), "members": members}
    if best.is_empty() and record_narrows and e_members.size() <= 3:
        # No sighting fits: the log alone narrows the room, and the witness
        # saw the actor clearly enough to name them.
        return {"w": {}, "e": e_spec}
    return {"w": best, "e": e_spec if not e_specific else {}}

static func _fragment_witness(witness: String, actor: String, specific: bool, group: Dictionary, room: String, time_text: String, locations: Dictionary) -> Dictionary:
    var room_name := str(locations.get(room, room))
    var text := ""
    if specific:
        text = "%s의 증언: %s쯤 %s|i %s 쪽으로 가는 것을 봤다." % [AstraCrewCatalog.display_name(witness), time_text, AstraCrewCatalog.display_name(actor), room_name]
    else:
        text = "%s의 증언: %s쯤 %s %s 쪽으로 가는 것을 봤다. 얼굴은 보지 못했다. 해당: %s." % [
            AstraCrewCatalog.display_name(witness), time_text, witness_phrase(str(group.get("category", "")), str(group.get("group", ""))),
            room_name, _names(group.get("members", []))]
    return {"type":"DIRECT_WITNESS", "owner":witness, "subject":actor if specific else "", "specific":specific, "group":group,
        "room":room, "time":time_text, "record_type":"", "strength":0.62 if specific else 0.34, "category":"DIRECT_WITNESS",
        "points_to":[actor] if specific else Array(group.get("members", [])).duplicate(), "refutes":actor, "text":text}

static func _fragment_record(owner: String, backup: String, record_type: String, actor: String, specific: bool, group: Dictionary, room: String, time_text: String, locations: Dictionary) -> Dictionary:
    var device := str(RECORD_DEVICE.get(record_type, "기록"))
    var room_name := str(locations.get(room, room))
    var text := ""
    if specific:
        text = "%s · %s · %s: %s의 인증이 남아 있다." % [device, time_text, room_name, AstraCrewCatalog.display_name(actor)]
    else:
        var label := AstraCrewCatalog.group_label(str(group.get("category", "")), str(group.get("group", "")))
        if str(group.get("category", "")) == "wing":
            text = "%s · %s · %s 앞 통로: %s 거주자의 태그가 지나갔다. 해당: %s." % [device, time_text, room_name, label, _names(group.get("members", []))]
        else:
            text = "%s · %s · %s: %s 인증이 남아 있다. 해당: %s." % [device, time_text, room_name, label, _names(group.get("members", []))]
    return {"type":"SYSTEM_RECORD", "owner":owner, "backup":backup, "subject":actor if specific else "", "specific":specific, "group":group,
        "room":room, "time":time_text, "record_type":record_type, "device":device, "strength":0.7 if specific else 0.4,
        "category":"HARD_RECORD", "points_to":[actor] if specific else Array(group.get("members", [])).duplicate(), "refutes":actor, "text":text}

static func _names(ids: Array) -> String:
    var names: Array = []
    for id in ids:
        names.append(AstraCrewCatalog.display_name(str(id)))
    return ", ".join(PackedStringArray(names))

# The same "Name|i" inline particle pass AstraGameSession uses, for static text.
static func josa_inline(text: String) -> String:
    var out := text
    for particle in ["eun", "i", "eul", "wa", "ro"]:
        var marker: String = "|" + str(particle)
        var guard := 0
        while out.find(marker) >= 0 and guard < 40:
            guard += 1
            var at := out.find(marker)
            var start := at
            while start > 0 and out.substr(start - 1, 1) not in [" ", "\n", "(", "“", "‘", ":"]:
                start -= 1
            var word := out.substr(start, at - start)
            out = out.substr(0, start) + AstraJosa.attach(word, str(particle)) + out.substr(at + marker.length())
    return out

# Returns a list of fairness problems; empty means the packet is fair.
static func validate_day_packet(packet: Dictionary, active: Array, living_nulls: Array) -> Array:
    var issues: Array = []
    if bool(packet.get("empty", false)):
        return issues
    var actor := str(packet.get("actor", ""))
    if actor == "" or actor not in living_nulls or actor not in active:
        issues.append("actor is not a living active Null")
        return issues
    var positions: Dictionary = packet.get("positions", {})
    var claims: Dictionary = packet.get("claims", {})
    for id in active:
        if not claims.has(str(id)):
            issues.append("missing claim " + str(id))
    var owners: Array = []
    var specific_count := 0
    var group_sets: Array = []
    var has_backup := false
    for fragment in packet.get("fragments", []):
        var text := str(fragment.get("text", ""))
        if "Null" in text or "NULL" in text or "무고" in text:
            issues.append("fragment leaks role: " + text)
        if bool(fragment.get("false", false)):
            continue
        var type := str(fragment.get("type", ""))
        if type not in ["DIRECT_WITNESS", "SYSTEM_RECORD"]:
            continue
        var owner := str(fragment.get("owner", ""))
        if owner in living_nulls or owner not in active:
            issues.append("actor evidence owned by a Null or inactive person")
            continue
        if actor not in Array(fragment.get("points_to", [])):
            issues.append("actor evidence does not include actor")
            continue
        owners.append(owner)
        if bool(fragment.get("specific", false)):
            specific_count += 1
        else:
            group_sets.append(Array(fragment.get("points_to", [])))
        if str(fragment.get("backup", "")) != "":
            has_backup = true
    if owners.is_empty():
        issues.append("A: no innocent-held evidence against the actor")
    var distinct := {}
    for owner in owners:
        distinct[owner] = true
    if distinct.size() < 2 and not has_backup:
        issues.append("B: single point of failure")
    if int(packet.get("day", 1)) == 1 and specific_count > 1:
        issues.append("C: Day 1 names the actor outright twice")
    if specific_count == 0 and group_sets.size() >= 2:
        var both: Array = []
        for id in group_sets[0]:
            if id in group_sets[1]:
                both.append(id)
        # The two traces leave the actor and at most two others (the evidence
        # curve); across Days the actor is in every set, so the room narrows
        # further for whoever remembers.
        if not (actor in both and both.size() <= 3):
            issues.append("D: group evidence does not narrow to the actor")
    elif specific_count == 0 and (group_sets.is_empty() or Array(group_sets[0]).size() > 3):
        issues.append("D: one group-level path that leaves too many people")
    for id in claims:
        var claim: Dictionary = claims[id]
        var kind := str(claim.get("kind", "honest"))
        if kind == "honest" and str(claim.get("position", "")) != str(positions.get(id, "")):
            issues.append("honest claim differs " + str(id))
        if kind == "null" and str(claim.get("position", "")) == str(positions.get(id, "")):
            issues.append("Null claim equals truth")
    var benign: Dictionary = packet.get("benign", {})
    if not benign.is_empty():
        var liar := str(benign.get("npc", ""))
        var caught := false
        for other in claims:
            if str(other) != liar and liar in Array(claims[other].get("companions", [])):
                caught = true
        for fragment in packet.get("fragments", []):
            if str(fragment.get("type", "")) == "BENIGN_EXPOSURE" and str(fragment.get("subject", "")) == liar:
                caught = true
        if not caught:
            issues.append("F: benign lie cannot be caught")
    return issues

# What a passer-by actually sees of someone in a corridor, per trait group.
const WITNESS_PHRASES := {
    "fiber": {"heatproof":"내열 작업복을 입은 누군가가", "sterile":"멸균 가운을 입은 누군가가", "tactical":"전술 조끼를 입은 누군가가", "antistatic":"정전기 방지 작업복을 입은 누군가가"},
    "hand": {"left":"왼손으로 문 패널을 누르는 누군가가", "right":"오른손으로 문 패널을 누르는 누군가가"},
    "shift": {"alpha":"알파 교대 근무 태그를 단 누군가가", "beta":"베타 교대 근무 태그를 단 누군가가"},
    "hair": {"long":"긴 머리의 누군가가", "short":"머리가 짧은 누군가가"}
}

static func witness_phrase(category: String, group: String) -> String:
    return str(WITNESS_PHRASES.get(category, {}).get(group, AstraCrewCatalog.group_label(category, group) + " 차림의 누군가가"))

# A keeper whose own records can place a person somewhere (doors, corridor
# sensors, bio tags, air sensors, terminals, comms). Engine and audit logs do
# not locate people, so their keepers are tried last.
static func _locating_keeper(subject: String, innocents: Array, exclude: Array, rng: RandomNumberGenerator) -> String:
    var preferred: Array = []
    var fallback: Array = []
    for id in innocents:
        if str(id) == subject or str(id) in exclude:
            continue
        if str(AstraCrewCatalog.RECORD_DOMAIN.get(str(id), "")) in ["door", "motion", "vitals", "environment", "terminal", "comms"]:
            preferred.append(str(id))
        else:
            fallback.append(str(id))
    var pool := preferred if not preferred.is_empty() else fallback
    if pool.is_empty():
        return ""
    return str(pool[rng.randi_range(0, pool.size() - 1)])

# "노아가 자기 선실에 있었다", not "노아가 노아의 선실에 있었다".
static func _place_of(subject: String, position: String, locations: Dictionary) -> String:
    if position == "cabin:" + subject:
        return "자기 선실"
    return str(locations.get(position, position))
