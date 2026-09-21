class_name AstraCrewCatalog
extends RefCounted

# Fixed identity of the eight crew members (docs/CHARACTERS.md).
# Hidden roles are never stored here; they are rolled per case.

const ORDER := ["mira", "rho", "dax", "noa", "sena", "vale", "eli", "lyra"]
const ASSET_IDS := {"mira":"mira", "rho":"jun", "dax":"daren", "noa":"noa", "sena":"sena", "vale":"soren", "eli":"lucan", "lyra":"maren"}
const INITIAL := ["mira", "rho", "dax", "noa"]
const AWAKENING_ORDER := ["sena", "vale", "eli", "lyra"]
const JOIN_DAY := {"mira":1,"rho":1,"dax":1,"noa":1,"sena":2,"vale":3,"eli":4,"lyra":5}

static func joined_on_day(campaign_day: int) -> Array:
    return ORDER.filter(func(id): return int(JOIN_DAY[id]) <= campaign_day)


# Physical / procedural traits used by trace clues. Every crew member is
# uniquely identified by at least one pair of categories, so each saboteur
# can always be narrowed down to exactly one person.
const TRAIT_CATEGORIES := {
    "clearance": {
        "label": "권한 등급",
        "groups": {
            "command": {"label": "지휘 권한(A등급)", "members": ["sena", "dax", "mira"]},
            "technical": {"label": "기술 권한(B등급)", "members": ["rho", "vale", "eli"]},
            "research": {"label": "연구 권한(C등급)", "members": ["noa", "lyra"]}
        }
    },
    "fiber": {
        "label": "작업복 섬유",
        "groups": {
            "heatproof": {"label": "내열 섬유", "members": ["rho", "dax"]},
            "sterile": {"label": "멸균 섬유", "members": ["mira", "lyra"]},
            "tactical": {"label": "전술 섬유", "members": ["sena", "eli"]},
            "antistatic": {"label": "정전기 방지 섬유", "members": ["vale", "noa"]}
        }
    },
    "shift": {
        "label": "근무 교대",
        "groups": {
            "alpha": {"label": "알파 교대", "members": ["mira", "eli", "noa", "dax"]},
            "beta": {"label": "베타 교대", "members": ["rho", "sena", "vale", "lyra"]}
        }
    },
    "hand": {
        "label": "조작 습관",
        "groups": {
            "left": {"label": "왼손 조작", "members": ["eli", "noa", "rho"]},
            "right": {"label": "오른손 조작", "members": ["mira", "sena", "vale", "lyra", "dax"]}
        }
    },
    "terminal": {
        "label": "개인 단말",
        "groups": {
            "t3": {"label": "구형 T-3 단말", "members": ["rho", "lyra", "vale"]},
            "t7": {"label": "신형 T-7 단말", "members": ["mira", "sena", "dax"]},
            "custom": {"label": "개조 단말", "members": ["eli", "noa"]}
        }
    }
}

const CREW := {
    "mira": {
        "name": "Mira", "job": "의무관", "gender": "F", "accent": "63d7ff",
        "concept": "차분한 이상주의자", "vibe": "정제된 프로페셔널, 부드러운 카리스마",
        "speech": "haeyo", "speech_note": "해요체 · 짧고 정확하지만 상대를 안심시킨다",
        "social_goal": "불필요한 희생을 막고 믿을 수 있는 연합을 만든다",
        "pressure_response": "압박받을수록 감정을 숨기고 사실 확인을 요구한다",
        "trust": 0.60, "personality": {"calm": 0.86, "aggressive": 0.12, "social": 0.57},
        "portrait": "res://assets/art050/heads/mira.webp",
        "secret": "약품 재고가 맞지 않아서 혼자 다시 세고 있었어요. 확인 전에 다른 사람 이름이 거론되는 게 싫었어요."
    },
    "rho": {
        "name": "Jun", "job": "기관 엔지니어", "gender": "M", "accent": "ff755f",
        "concept": "밝고 장난기 많은 행동파", "vibe": "도구를 챙겨 먼저 움직인다",
        "speech": "banmal", "speech_note": "반말 · 평소 빠르고 가볍게, 위험할 때 짧고 단호하게",
        "social_goal": "고장 난 설비와 동료를 함께 돌본다",
        "pressure_response": "실제 위험 앞에서는 농담이 사라진다",
        "trust": 0.45, "personality": {"calm": 0.76, "aggressive": 0.25, "social": 0.78},
        "portrait": "res://assets/art050/heads/jun.webp",
        "secret": "예비 부품을 빌려 쓰고 대장에 안 적었어. 먼저 돌려놓으면 될 줄 알았지. 내 실수야."
    },
    "eli": {
        "name": "Lucan", "job": "항법사", "gender": "M", "accent": "b88cff",
        "concept": "신중하고 독립적인 항법사", "vibe": "방 전체와 출구를 먼저 살핀다",
        "speech": "banmal", "speech_note": "절제된 반말 · 짧고 구체적으로",
        "social_goal": "항로 선택의 책임을 감당한다",
        "pressure_response": "말이 더 짧아지지만 위험한 곳에는 직접 간다",
        "trust": 0.55, "personality": {"calm": 0.84, "aggressive": 0.22, "social": 0.3},
        "portrait": "res://assets/art050/heads/lucan.webp",
        "secret": "항법 사본을 따로 만들었어. 원본을 믿을 수 없어서. 허가를 기다리면 늦을 것 같았고."
    },
    "sena": {
        "name": "Sena", "job": "보안 책임자", "gender": "F", "accent": "ffd15c",
        "concept": "적극적인 보호자", "vibe": "자신감과 경쟁심",
        "speech": "banmal", "speech_note": "자연스러운 반말 · 위급할 때 명확한 지시",
        "social_goal": "승무원의 안전을 확보한다",
        "pressure_response": "상대보다 먼저 위험한 쪽으로 움직인다",
        "trust": 0.50, "personality": {"calm": 0.65, "aggressive": 0.53, "social": 0.71},
        "portrait": "res://assets/art050/heads/sena.webp",
        "secret": "순찰 경로를 벗어났어. 문 안쪽에서 소리가 났거든. 아무것도 없었는데, 잘못 들었다고 인정하기 싫었어."
    },
    "vale": {
        "name": "Soren", "job": "통신관", "gender": "M", "accent": "57e5a5",
        "concept": "차분한 통신관", "vibe": "조용한 거리감과 신호에 대한 집중",
        "speech": "haeyo_polite", "speech_note": "짧은 해요체 · 잡음 앞에서는 말 대신 손짓",
        "social_goal": "들은 신호의 출처를 확인한다",
        "pressure_response": "대답을 미루고 같은 구간을 다시 듣는다",
        "trust": 0.56, "personality": {"calm": 0.84, "aggressive": 0.18, "social": 0.29},
        "portrait": "res://assets/art050/heads/soren.webp",
        "secret": "개인 채널에 들어온 신호를 듣고 있었어요. 제 이름을 불렀어요. 다른 사람이 듣기 전에 출처를 찾고 싶었어요."
    },
    "noa": {
        "name": "Noa", "job": "기록관", "gender": "F", "accent": "ff9ed1",
        "concept": "관찰형 분석가", "vibe": "조용하고 섬세한 기억 수집가",
        "speech": "haeyo_terse", "speech_note": "해요체 · 말수가 적고 남의 말을 정확히 인용한다",
        "social_goal": "누가 언제 말을 바꿨는지 기록하고 사실을 보존한다",
        "pressure_response": "침묵이 길어지지만 확인된 문장만 말한다",
        "trust": 0.62, "personality": {"calm": 0.69, "aggressive": 0.11, "social": 0.46},
        "portrait": "res://assets/art050/heads/noa.webp",
        "secret": "제 배치 기록을 열어 봤어요. 날짜가 기억과 달랐어요. 확인할 때까지 말하고 싶지 않았어요."
    },
    "lyra": {
        "name": "Maren", "job": "생태학자", "gender": "F", "accent": "8df0a4",
        "concept": "따뜻하고 표현이 풍부한 생태학자", "vibe": "작은 생명도 살피되 생존 판단은 냉정하다",
        "speech": "haeyo_warm", "speech_note": "밝은 해요체 · 자원을 나눌 때는 단호하게",
        "social_goal": "한정된 자원으로 살아 있는 것을 지킨다",
        "pressure_response": "포기할 것을 직접 고르고 책임진다",
        "trust": 0.60, "personality": {"calm": 0.69, "aggressive": 0.27, "social": 0.83},
        "portrait": "res://assets/art050/heads/maren.webp",
        "secret": "격리한 모종에 물을 줬어요. 폐기 결정이 난 건 알아요. 살아 있는 걸 그냥 두기 어려웠어요."
    },
    "dax": {
        "name": "Daren", "job": "시스템 설계자", "gender": "M", "accent": "8fa8ff",
        "concept": "경험 많은 설계자", "vibe": "침착한 판단과 건조한 유머",
        "speech": "hada", "speech_note": "자연스러운 반말 · 모르는 것은 인정한다",
        "social_goal": "동료와 함께 판단의 오류를 확인한다",
        "pressure_response": "같은 계산을 다시 하고 다른 사람 의견을 듣는다",
        "trust": 0.48, "personality": {"calm": 0.86, "aggressive": 0.2, "social": 0.43},
        "portrait": "res://assets/art050/heads/daren.webp",
        "secret": "승인 전에 진단을 돌렸어. 내가 만든 설정이 틀렸을까 봐. 남한테 보이기 전에 확인하려고 했지."
    }
}

# Baseline proximity only — who tends to cross paths, not who is already
# close. The actual shape of a relationship (were they ever partners, did one
# fail the other) belongs to PAIR_HISTORY below; a pair's affinity is this
# bias plus that history's delta, so this table stays small.
const AFFINITY_BIAS := {
    "mira:lyra": 0.08, "lyra:mira": 0.06, "noa:eli": 0.05, "eli:noa": 0.03,
    "sena:rho": -0.04, "rho:sena": -0.02, "dax:vale": -0.03, "vale:sena": 0.03
}

# Every kind of past two crewmates can share, keyed by a short id. `summary`
# is what a "pair" scene or a records check can surface in prose; `tone`
# colors how a scene plays it; the deltas nudge affinity/trust once, on top
# of AFFINITY_BIAS, when the history is (re)rolled.
const PAIR_HISTORY := {
    "first_mission": {"summary": "이번 항해에서 처음 함께 일한다.", "tone": "neutral", "affinity_delta": 0.0, "trust_delta": 0.0},
    "old_colleagues": {"summary": "오래전부터 함께 일해 온 동료다.", "tone": "warm", "affinity_delta": 0.16, "trust_delta": 0.06},
    "former_partners": {"summary": "예전에 같은 조로 묶여 일한 적이 있다.", "tone": "warm", "affinity_delta": 0.11, "trust_delta": 0.05},
    "shared_accident": {"summary": "이전에 사고를 함께 겪었다.", "tone": "complicated", "affinity_delta": 0.09, "trust_delta": 0.04},
    "saved_each_other": {"summary": "서로를 구한 적이 있다.", "tone": "warm", "affinity_delta": 0.20, "trust_delta": 0.10},
    "professional_conflict": {"summary": "업무 방식으로 크게 부딪힌 적이 있다.", "tone": "tense", "affinity_delta": -0.12, "trust_delta": -0.04},
    "past_failure": {"summary": "한쪽의 판단 때문에 문제가 생긴 적이 있다.", "tone": "tense", "affinity_delta": -0.08, "trust_delta": -0.06},
    "once_close": {"summary": "가까웠지만 지금은 멀어졌다.", "tone": "complicated", "affinity_delta": -0.05, "trust_delta": 0.0},
    "shared_secret": {"summary": "서로의 비밀을 하나씩 알고 있다.", "tone": "complicated", "affinity_delta": 0.08, "trust_delta": 0.08},
    "record_only_history": {"summary": "기록상으로는 함께 근무했지만 정작 두 사람 다 기억하지 못한다.", "tone": "uncanny", "affinity_delta": 0.0, "trust_delta": -0.02},
    "shared_patient_or_ecology_case": {"summary": "예전에 함께 다룬 응급 환자 혹은 생태 사고가 있었다.", "tone": "complicated", "affinity_delta": 0.10, "trust_delta": 0.05},
    "shared_signal_route": {"summary": "같은 통신·항로 임무를 여러 번 함께 맡았다.", "tone": "warm", "affinity_delta": 0.13, "trust_delta": 0.05},
    "quiet_trust": {"summary": "말은 거의 나누지 않았지만 서로를 신뢰해 왔다.", "tone": "warm", "affinity_delta": 0.09, "trust_delta": 0.07}
}

# Which histories are plausible for a given unordered pair (§21 of the design
# notes). A pair not listed here draws from CANDIDATES_DEFAULT instead of
# every entry in PAIR_HISTORY, so a medic and a navigator do not roll a
# "shared signal route" they never plausibly had.
const PAIR_CANDIDATES := {
    "rho:sena": ["first_mission", "old_colleagues", "shared_accident", "saved_each_other", "professional_conflict"],
    "lyra:mira": ["old_colleagues", "shared_patient_or_ecology_case", "professional_conflict", "once_close"],
    "dax:noa": ["old_colleagues", "professional_conflict", "shared_secret", "record_only_history"],
    "eli:vale": ["old_colleagues", "former_partners", "shared_signal_route", "first_mission"],
    "dax:rho": ["professional_conflict", "old_colleagues", "past_failure"],
    "mira:sena": ["saved_each_other", "professional_conflict", "old_colleagues"],
    "dax:lyra": ["professional_conflict", "past_failure", "first_mission"],
    "noa:vale": ["shared_secret", "quiet_trust", "record_only_history"]
}
const CANDIDATES_DEFAULT := ["first_mission", "old_colleagues", "professional_conflict", "record_only_history"]

# Canonical, order-independent key so "A's history with B" and "B's history
# with A" are always the same lookup — the single biggest bug in the old
# per-direction random past (§9 of the design notes).
static func pair_key(a: String, b: String) -> String:
    return (a + ":" + b) if a < b else (b + ":" + a)

static func pair_candidates(a: String, b: String) -> Array:
    return PAIR_CANDIDATES.get(pair_key(a, b), CANDIDATES_DEFAULT)

static func pair_history_info(history_id: String) -> Dictionary:
    return PAIR_HISTORY.get(history_id, PAIR_HISTORY["first_mission"])

static func info(npc_id: String) -> Dictionary:
    return CREW.get(npc_id, {})

# The name shown everywhere in the game. 0.4.0 uses the Korean reading: eight
# Latin names inside Korean sentences meant the player had to transliterate each
# one before they could even start remembering who does what. The Latin spelling
# stays in CREW["name"] for logs, asset paths and the AI contract.
static func display_name(npc_id: String) -> String:
    if NAME_KO.has(npc_id):
        return str(NAME_KO[npc_id])
    return str(CREW.get(npc_id, {}).get("name", npc_id))

static func latin_name(npc_id: String) -> String:
    return str(CREW.get(npc_id, {}).get("name", npc_id))

static func accent(npc_id: String) -> Color:
    return Color(str(CREW.get(npc_id, {}).get("accent", "ffffff")))

static func group_members(category: String, group: String) -> Array:
    return TRAIT_CATEGORIES.get(category, {}).get("groups", {}).get(group, {}).get("members", [])

static func group_label(category: String, group: String) -> String:
    return str(TRAIT_CATEGORIES.get(category, {}).get("groups", {}).get(group, {}).get("label", group))

static func category_label(category: String) -> String:
    return str(TRAIT_CATEGORIES.get(category, {}).get("label", category))

static func group_of(npc_id: String, category: String) -> String:
    var groups: Dictionary = TRAIT_CATEGORIES.get(category, {}).get("groups", {})
    for group_id in groups.keys():
        if npc_id in groups[group_id].get("members", []):
            return str(group_id)
    return ""

static func traits_of(npc_id: String) -> Dictionary:
    var result := {}
    for category in TRAIT_CATEGORIES.keys():
        result[category] = group_of(npc_id, str(category))
    return result

static func affinity_bias(source_id: String, target_id: String) -> float:
    return float(AFFINITY_BIAS.get("%s:%s" % [source_id, target_id], 0.0))

# Members of a trait group, optionally narrowed to the crew taking part in this
# case. A four-person calibration roster must not print names who are not there.
static func group_members_in(category: String, group: String, roster: Array = []) -> Array:
    var members: Array = group_members(category, group)
    if roster.is_empty():
        return members.duplicate()
    var result: Array = []
    for member in members:
        if member in roster:
            result.append(member)
    return result

# Category pairs whose groups intersect to exactly this crew member, within the
# roster actually present. Pairs where either trace would already name one
# person on its own are ranked last, so a case prefers evidence that has to be
# crossed rather than evidence that hands over the answer.
static func identifying_pairs(npc_id: String, roster: Array = []) -> Array:
    var strong: Array = []
    var weak: Array = []
    var categories: Array = TRAIT_CATEGORIES.keys()
    for a_index in range(categories.size()):
        for b_index in range(a_index + 1, categories.size()):
            var cat_a := str(categories[a_index])
            var cat_b := str(categories[b_index])
            var set_a: Array = group_members_in(cat_a, group_of(npc_id, cat_a), roster)
            var set_b: Array = group_members_in(cat_b, group_of(npc_id, cat_b), roster)
            var both: Array = []
            for member in set_a:
                if member in set_b:
                    both.append(member)
            if both.size() != 1 or both[0] != npc_id:
                continue
            if set_a.size() >= 2 and set_b.size() >= 2:
                strong.append([cat_a, cat_b])
            else:
                weak.append([cat_a, cat_b])
    return strong if not strong.is_empty() else weak

# Square bust used in lists, cards and the meeting feed.
const EXPRESSION_ALIASES := {"calm":"neutral", "warm":"smile", "uneasy":"suspicious", "tense":"determined"}

static func asset_id(npc_id: String) -> String:
    return str(ASSET_IDS.get(npc_id, ""))

# Audited 2026-09-21: these supplied crops contain half/two faces. Use the
# same person's intact neutral portrait until corrected originals arrive.
const DAMAGED_CROPS := {"vale":["angry","sad","shocked","suspicious","tired"],"dax":["tired"]}

static func portrait_path(npc_id: String, expression: String = "neutral") -> String:
    if not CREW.has(npc_id):
        return ""
    var mood := str(EXPRESSION_ALIASES.get(expression, expression))
    if mood in DAMAGED_CROPS.get(npc_id,[]): mood = "neutral"
    if npc_id == "lyra" and mood == "neutral":
        return "res://assets/art050/portraits/maren.webp"
    var path := "res://assets/art050/expressions/%s/%s.webp" % [asset_id(npc_id), mood]
    return path if ResourceLoader.exists(path) else "res://assets/art050/portraits/%s.webp" % asset_id(npc_id)

static func cast_path(npc_id: String, expression: String = "neutral", full: bool = false) -> String:
    if not CREW.has(npc_id):
        return ""
    if full:
        return "res://assets/art050/cast/%s.webp" % asset_id(npc_id)
    return portrait_path(npc_id, expression)

# ---------------------------------------------------------------- 0.4.0 identity
#
# Eight Latin names in a Korean sentence is eight things to transliterate while
# also trying to remember who does what. 0.4.0 shows the Korean reading, the job
# and a sprite together, everywhere a name appears.

const NAME_KO := {
    "mira": "미라", "rho": "준", "eli": "루칸", "sena": "세나",
    "vale": "소렌", "noa": "노아", "lyra": "마렌", "dax": "다렌"
}

# One-word role, shorter than the job title, for tight rows.
const ROLE_SHORT := {
    "mira": "의무", "rho": "기관", "eli": "항법", "sena": "보안",
    "vale": "통신", "noa": "기록", "lyra": "생태", "dax": "시스템"
}

static func name_ko(npc_id: String) -> String:
    return str(NAME_KO.get(npc_id, display_name(npc_id)))

static func role_short(npc_id: String) -> String:
    return str(ROLE_SHORT.get(npc_id, ""))

# "노아 (기록관)" — the form used in prose and on buttons.
static func labelled(npc_id: String, short: bool = false) -> String:
    var job := role_short(npc_id) if short else str(CREW.get(npc_id, {}).get("job", ""))
    if job == "":
        return name_ko(npc_id)
    return "%s (%s)" % [name_ko(npc_id), job]

# Small sprite used beside a name so people are told apart by face, not by
# spelling. Falls back to the square bust if the sprite is missing.
static func dot_path(npc_id: String) -> String:
    if not CREW.has(npc_id):
        return ""
    var path := "res://assets/art050/heads/%s.webp" % asset_id(npc_id)
    return path if ResourceLoader.exists(path) else portrait_path(npc_id)

static func sprite_path(npc_id: String) -> String:
    return dot_path(npc_id)
