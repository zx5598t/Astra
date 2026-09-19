class_name AstraClueHelp
extends RefCounted

# Says what a piece of evidence *means*, in plain words.
#
# 0.3.1 handed the player this on the first screen of the first case:
#
#   "07:38:20, 통신실 콘솔에서 외부 구조 채널이 수동으로 닫혔다.
#    실행자 서명 칸은 비어 있다."
#
# Every noun in that sentence is doing work, and none of it is explained.
# "서명 칸이 비어 있다" means *somebody deleted their own name*, which is the
# entire reason the case exists — and a first-time player reads it as flavour.
#
# So each clue now carries a second line that states the inference the sentence
# supports, and a third that says what to do with it. The line never names a
# culprit and never resolves the case: it teaches how to read the evidence, not
# what the answer is.

# What this kind of record is, one sentence.
const KIND_MEANING := {
    "op_record": "조작이 실행된 [b]정확한 시각[/b]입니다. 이 시각에 그 장소에 있었던 사람이 실행자입니다.",
    "access_log": "그 시간대에 해당 장소를 드나든 사람의 [b]전체 명단[/b]입니다. 명단에 없는데 그곳에 있었다고 말하는 사람은, 사실과 다른 말을 한 것입니다.",
    "context": "사건이 [b]언제[/b] 일어났는지 알려 줍니다. 이 시간대 밖에 찍힌 기록은 사건과 관계가 없습니다.",
    "trace": "현장에 남은 물리적 흔적입니다. 범인의 이름이 아니라 [b]후보 명단[/b]을 줍니다.",
    "sighting": "누군가 직접 본 것을 말한 증언입니다. 기록이 아니라 [b]사람의 기억[/b]이므로 틀릴 수도, 지어낸 것일 수도 있습니다.",
    "night": "밤사이 새로 생긴 흔적입니다. 사건 당시가 아니라 [b]어젯밤[/b]의 기록입니다.",
    "slip": "본인만 알 수 있었던 사실을 말해 버린 순간입니다. [b]가장 강한 단서[/b]입니다.",
    "planted": "누군가 해석해서 건넨 자료입니다. 공식 기록으로는 확인되지 않으므로 [b]출처를 의심해야[/b] 합니다."
}

# What to do next with it.
const KIND_ACTION := {
    "op_record": "이 시각에 어디 있었는지 모두에게 물어보세요.",
    "access_log": "들은 알리바이와 이 명단을 한 줄씩 맞춰 보세요.",
    "context": "다른 기록의 시각이 이 범위 안인지부터 확인하세요.",
    "trace": "같은 조작에서 나온 다른 흔적과 명단을 겹쳐 보세요. 겹치는 한 사람이 실행자입니다.",
    "sighting": "증언한 사람이 그때 정말 그곳에 있었는지 확인해 보세요.",
    "night": "어젯밤 습격당한 사람은 실행자가 아닙니다. 그 사람이 누구를 의심했는지 떠올려 보세요.",
    "slip": "회의에서 공개하면 여론이 크게 움직입니다.",
    "planted": "건넨 사람의 알리바이부터 확인하세요."
}

# Phrases the case files use that a first-time player has no reason to know.
const GLOSSARY := {
    "서명": "기록에 남는 ‘누가 했는지’ 항목입니다. 비어 있다는 것은 실행자가 지웠다는 뜻입니다.",
    "인증 기록": "출입할 때 단말에 찍히는 기록입니다. 사람이 지나가면 자동으로 남습니다.",
    "우회": "정상 경로를 건너뛰고 직접 조작했다는 뜻입니다. 현장에 사람이 있어야 가능합니다.",
    "인터록": "위험한 조작을 막는 안전장치입니다. 풀려면 직접 해제해야 합니다.",
    "수동": "자동 시스템이 아니라 사람이 직접 했다는 뜻입니다.",
    "덮어쓰기": "원래 기록 위에 새 기록을 씌워 지웠다는 뜻입니다."
}

static func meaning(clue: Dictionary) -> String:
    return str(KIND_MEANING.get(str(clue.get("kind", "")), ""))

static func action(clue: Dictionary) -> String:
    return str(KIND_ACTION.get(str(clue.get("kind", "")), ""))

# A concrete reading of this specific clue, built from its own fields, so the
# help is about the record in front of the player rather than about its type.
static func specific(clue: Dictionary, session) -> String:
    match str(clue.get("kind", "")):
        "trace":
            var members: Array = clue.get("members", [])
            if members.is_empty():
                return ""
            if members.size() == 1:
                return "이 흔적 하나로 %s 좁혀집니다. 다른 기록으로 확인해 보세요." % AstraJosa.ro(session.names_of(members))
            return "지금 후보는 %d명입니다: %s." % [members.size(), session.names_of(members)]
        "access_log":
            var people: Array = clue.get("log_people", [])
            if people.is_empty():
                return "이 시간대에 이곳에 들어간 사람은 [b]한 명도 없습니다[/b]. 여기 있었다고 말하는 사람이 있다면 그 말은 성립하지 않습니다."
            return "이 시간대에 이곳에 있었던 사람은 %s뿐입니다. 그 외에는 아무도 없었습니다." % session.names_of(people)
        "op_record":
            var room: String = session.room_name(str(clue.get("room", "")))
            return "%s에서 %s에 일어났습니다. 이 시각의 %s 출입 기록을 찾아보세요." % [room, str(clue.get("time", "")), room]
        "context":
            return "사건 시간대는 %s입니다. 이 밖의 시각이 적힌 기록은 넘겨도 됩니다." % session.window_text()
    return ""

# Terms appearing in this clue's text that are worth a footnote.
static func terms(clue: Dictionary) -> Array:
    var text := str(clue.get("text", ""))
    var found: Array = []
    for term in GLOSSARY:
        if text.find(str(term)) >= 0:
            found.append({"term": str(term), "note": str(GLOSSARY[term])})
    return found
