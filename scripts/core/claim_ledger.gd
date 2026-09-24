class_name AstraClaimLedger
extends RefCounted

# What each person has said out loud, in the order they said it.
#
# 0.3.1 kept one current alibi per crew member, so "Jun changed his story" was
# not a thing the game could notice — only "Jun's story does not match a log".
# The ledger stores every assertion instead, which gives the social layer the
# three moves a deduction game needs:
#
#   1. the player can look up who said what, and when   (§28)
#   2. an NPC can cite a specific earlier line as its reason for suspecting
#      someone, instead of acting on an invisible number  (§39)
#   3. a speaker can walk a statement back, and everyone remembers that they did
#
# Entries are plain dictionaries so the whole ledger drops into the save file.
# Nothing here decides guilt: a contradiction is a fact about two sentences, not
# a verdict about a person. Deciding what it means is the player's job (§28).

const SCOPE_PUBLIC := "public"
const SCOPE_PRIVATE := "private"

const KIND_POSITION := "position"     # "I was in the engine room"
const KIND_COMPANION := "companion"   # "I was with Sena"
const KIND_ALONE := "alone"           # "I was on my own"
const KIND_ACCUSE := "accuse"
const KIND_DEFEND := "defend"
const KIND_DENY := "deny"
const KIND_WITNESS := "witness"       # "I saw someone near the console"

const LABELS := {
    KIND_POSITION: "위치 주장",
    KIND_COMPANION: "동행 주장",
    KIND_ALONE: "단독 행동 주장",
    KIND_ACCUSE: "지목",
    KIND_DEFEND: "변호",
    KIND_DENY: "부인",
    KIND_WITNESS: "목격 진술"
}

# ---------------------------------------------------------------- writing

static func make_entry(speaker: String, kind: String, day: int, phase: String, scope: String, text: String, data: Dictionary = {}) -> Dictionary:
    var entry := {
        "speaker": speaker,
        "kind": kind,
        "day": day,
        "phase": phase,
        "scope": scope,
        "text": text,
        "position": str(data.get("position", "")),
        "companions": data.get("companions", []).duplicate() if data.get("companions", null) is Array else [],
        "target": str(data.get("target", "")),
        "minute": int(data.get("minute", -1)),
        # 0.8.0: which Day's incident this statement is about. A Stage has a new
        # incident every Day, so "where were you" on Day 2 is a different
        # question from Day 1 unless the speaker is retelling yesterday.
        "about_day": int(data.get("about_day", day)),
        "retracted": false,
        "retracted_day": 0
    }
    return entry

static func record(ledger: Array, entry: Dictionary) -> Dictionary:
    entry["index"] = ledger.size()
    ledger.append(entry)
    return entry

# Marks the most recent live claim of `kind` by `speaker` as withdrawn and
# returns it, so the caller can say what was taken back.
static func retract_latest(ledger: Array, speaker: String, kind: String, day: int) -> Dictionary:
    for index in range(ledger.size() - 1, -1, -1):
        var entry: Dictionary = ledger[index]
        if str(entry.get("speaker", "")) != speaker or str(entry.get("kind", "")) != kind:
            continue
        if bool(entry.get("retracted", false)):
            continue
        entry["retracted"] = true
        entry["retracted_day"] = day
        return entry
    return {}

# ---------------------------------------------------------------- reading

static func by_speaker(ledger: Array, speaker: String, scope: String = "") -> Array:
    var result: Array = []
    for entry in ledger:
        if str(entry.get("speaker", "")) != speaker:
            continue
        if scope != "" and str(entry.get("scope", "")) != scope:
            continue
        result.append(entry)
    return result

static func latest(ledger: Array, speaker: String, kind: String) -> Dictionary:
    for index in range(ledger.size() - 1, -1, -1):
        var entry: Dictionary = ledger[index]
        if str(entry.get("speaker", "")) == speaker and str(entry.get("kind", "")) == kind and not bool(entry.get("retracted", false)):
            return entry
    return {}

# Free-text search over everything that has been said, for "who said this?" (§28).
static func search(ledger: Array, needle: String) -> Array:
    var lowered := needle.strip_edges().to_lower()
    if lowered == "":
        return []
    var result: Array = []
    for entry in ledger:
        if str(entry.get("text", "")).to_lower().find(lowered) >= 0:
            result.append(entry)
    return result

static func retraction_count(ledger: Array, speaker: String) -> int:
    var count := 0
    for entry in ledger:
        if str(entry.get("speaker", "")) == speaker and bool(entry.get("retracted", false)):
            count += 1
    return count

# ---------------------------------------------------------------- consistency

# Two statements by the same person that cannot both be true. Returns a list of
# {a, b, reason, severity}. Severity is only used to sort what the player sees
# first; it is never shown as a number and never resolves to "this person lied,
# therefore they are Null".
static func self_conflicts(ledger: Array, speaker: String) -> Array:
    var statements := by_speaker(ledger, speaker)
    var conflicts: Array = []
    for i in range(statements.size()):
        for j in range(i + 1, statements.size()):
            var a: Dictionary = statements[i]
            var b: Dictionary = statements[j]
            var reason := _conflict_reason(a, b)
            if reason == "":
                continue
            conflicts.append({
                "a": a, "b": b, "reason": reason,
                "severity": 2 if str(a.get("scope", "")) == SCOPE_PUBLIC and str(b.get("scope", "")) == SCOPE_PUBLIC else 1
            })
    conflicts.sort_custom(func(x, y): return int(x["severity"]) > int(y["severity"]))
    return conflicts

static func _conflict_reason(a: Dictionary, b: Dictionary) -> String:
    if bool(a.get("retracted", false)) or bool(b.get("retracted", false)):
        return ""
    var kind_a := str(a.get("kind", ""))
    var kind_b := str(b.get("kind", ""))
    if int(a.get("about_day", a.get("day", 1))) != int(b.get("about_day", b.get("day", 1))):
        return ""
    if kind_a == KIND_POSITION and kind_b == KIND_POSITION:
        var pos_a := str(a.get("position", ""))
        var pos_b := str(b.get("position", ""))
        if pos_a != "" and pos_b != "" and pos_a != pos_b:
            return "같은 시간대에 서로 다른 장소를 말했다"
    if kind_a == KIND_ALONE and kind_b == KIND_COMPANION:
        return "혼자였다고 했다가 동행이 있었다고 했다"
    if kind_a == KIND_COMPANION and kind_b == KIND_ALONE:
        return "동행이 있었다고 했다가 혼자였다고 했다"
    if kind_a == KIND_ACCUSE and kind_b == KIND_DEFEND and str(a.get("target", "")) == str(b.get("target", "")) and str(a.get("target", "")) != "":
        return "같은 사람을 지목했다가 변호했다"
    if kind_a == KIND_DEFEND and kind_b == KIND_ACCUSE and str(a.get("target", "")) == str(b.get("target", "")) and str(a.get("target", "")) != "":
        return "같은 사람을 변호했다가 지목했다"
    return ""

# Two different people whose statements cannot both be true — "you say you were
# together, he says he was alone". This is what makes a meeting an argument
# rather than a queue of monologues.
static func cross_conflicts(ledger: Array, a_id: String, b_id: String) -> Array:
    var result: Array = []
    var a_pos := latest(ledger, a_id, KIND_POSITION)
    var b_pos := latest(ledger, b_id, KIND_POSITION)
    if a_pos.is_empty() or b_pos.is_empty():
        return result
    var a_mates: Array = a_pos.get("companions", [])
    var b_mates: Array = b_pos.get("companions", [])
    var same_room := str(a_pos.get("position", "")) == str(b_pos.get("position", "")) and str(a_pos.get("position", "")) != ""
    if b_id in a_mates and not same_room:
        result.append({"a": a_pos, "b": b_pos, "reason": "함께 있었다고 했지만 상대는 다른 장소를 말했다"})
    if a_id in b_mates and not same_room:
        result.append({"a": b_pos, "b": a_pos, "reason": "함께 있었다고 했지만 상대는 다른 장소를 말했다"})
    if same_room and not (b_id in a_mates) and not (a_id in b_mates):
        result.append({"a": a_pos, "b": b_pos, "reason": "같은 장소에 있었다면서 서로를 보지 못했다고 한다"})
    return result

# A short line an NPC can say out loud to justify itself, quoting the ledger.
# Empty when the NPC has no stated reason — callers must then stay quiet rather
# than invent one (§39: every judgement cites something).
static func citation(entry: Dictionary) -> String:
    if entry.is_empty():
        return ""
    return "DAY %d · %s" % [int(entry.get("day", 1)), str(entry.get("text", ""))]
