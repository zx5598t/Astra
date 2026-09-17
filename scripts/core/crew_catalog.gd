class_name AstraCrewCatalog
extends RefCounted

# Fixed identity of the eight crew members (docs/CHARACTERS.md).
# Hidden roles are never stored here; they are rolled per case.

const ORDER := ["mira", "rho", "eli", "sena", "vale", "noa", "lyra", "dax"]

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
        "portrait": "res://assets/portraits/mira.svg",
        "secret": "의무실 약품 재고를 몰래 다시 세고 있었어요. 진통제 수치가 맞지 않았거든요. 괜히 누군가 의심받게 하고 싶지 않아서 말하지 못했어요."
    },
    "rho": {
        "name": "Rho", "job": "기관사", "gender": "M", "accent": "ff755f",
        "concept": "직선적인 현장파", "vibe": "거칠지만 믿음직한 정비 리더",
        "speech": "banmal", "speech_note": "반말 · 짧고 직설적, 현장 경험으로 반박한다",
        "social_goal": "자기 통제권을 지키고 약해 보이지 않는다",
        "pressure_response": "의심받으면 목소리가 커지고 공격적으로 되묻는다",
        "trust": 0.45, "personality": {"calm": 0.54, "aggressive": 0.74, "social": 0.42},
        "portrait": "res://assets/portraits/rho.svg",
        "secret": "예비 부품 창고에 있었어. 지난주 냉각 펌프를 내가 잘못 조립했거든. 그 흔적을 치우고 있었다고 말하면… 다들 엔진 사고도 내 탓이라고 할 거 아냐."
    },
    "eli": {
        "name": "Eli", "job": "항법사", "gender": "M", "accent": "b88cff",
        "concept": "세련된 승부사", "vibe": "도시적이고 계산적인 파일럿",
        "speech": "banmal", "speech_note": "반말 · 농담과 비유로 긴장을 흩트린다",
        "social_goal": "회의 흐름을 먼저 읽고 유리한 쪽으로 이끈다",
        "pressure_response": "위기일수록 웃음과 빈정거림으로 거리를 둔다",
        "trust": 0.55, "personality": {"calm": 0.66, "aggressive": 0.23, "social": 0.79},
        "portrait": "res://assets/portraits/eli.svg",
        "secret": "허가 없이 항법 기록을 복사하고 있었어. 지구에 있는 가족한테 항로를 보여주고 싶었거든. 규정 위반인 건 알아. 그래도 살인이랑은 거리가 멀지."
    },
    "sena": {
        "name": "Sena", "job": "보안관", "gender": "F", "accent": "ffd15c",
        "concept": "강단 있는 프로텍터", "vibe": "단단하고 믿음직한 경호관",
        "speech": "danakka", "speech_note": "다나까체 · 절차와 책임 소재를 분명히 한다",
        "social_goal": "승무원을 보호하고 회의 질서를 지킨다",
        "pressure_response": "감정 대신 절차와 기록을 요구하며 흔들리지 않는다",
        "trust": 0.50, "personality": {"calm": 0.71, "aggressive": 0.58, "social": 0.34},
        "portrait": "res://assets/portraits/sena.svg",
        "secret": "순찰 경로를 이탈했습니다. 개인 통신이 들어왔습니다. 징계 사유라 보고하지 않았습니다. 변명은 하지 않겠습니다."
    },
    "vale": {
        "name": "Vale", "job": "통신관", "gender": "M", "accent": "57e5a5",
        "concept": "매혹적인 외교가", "vibe": "부드러운 화술의 장거리 통신 전문가",
        "speech": "haeyo_polite", "speech_note": "해요체 · 상대 이름을 부르며 부드럽게 설득한다",
        "social_goal": "모두와 최소한의 우호를 유지하며 정보를 쥔다",
        "pressure_response": "직접 부정하기보다 다른 해석을 내민다",
        "trust": 0.56, "personality": {"calm": 0.79, "aggressive": 0.28, "social": 0.84},
        "portrait": "res://assets/portraits/vale.svg",
        "secret": "그 시각엔 개인 채널로 지구에 있는 동생과 통화하고 있었어요. 규정 위반이라 말씀드리지 못했죠. 조사관님, 부탁인데 기록에는 남기지 말아 주세요."
    },
    "noa": {
        "name": "Noa", "job": "기록관", "gender": "F", "accent": "ff9ed1",
        "concept": "관찰형 분석가", "vibe": "조용하고 섬세한 기억 수집가",
        "speech": "haeyo_terse", "speech_note": "해요체 · 말수가 적고 남의 말을 정확히 인용한다",
        "social_goal": "누가 언제 말을 바꿨는지 기록하고 사실을 보존한다",
        "pressure_response": "침묵이 길어지지만 확인된 문장만 말한다",
        "trust": 0.62, "personality": {"calm": 0.69, "aggressive": 0.11, "social": 0.46},
        "portrait": "res://assets/portraits/noa.svg",
        "secret": "열람 권한이 없는 기록을 보고 있었어요. 함장님 인사 기록이요. …호기심이었어요. 들키면 기록관 자격이 박탈돼요."
    },
    "lyra": {
        "name": "Lyra", "job": "식물생태학자", "gender": "F", "accent": "8df0a4",
        "concept": "공감형 낙관주의자", "vibe": "자연과 사람을 함께 돌보는 분위기 메이커",
        "speech": "haeyo_warm", "speech_note": "해요체 · 감정을 먼저 살피고 부드럽게 묻는다",
        "social_goal": "갈등이 터지기 전에 사람들을 다시 대화하게 만든다",
        "pressure_response": "상처받아도 공격하지 않고 관계의 변화를 짚는다",
        "trust": 0.60, "personality": {"calm": 0.74, "aggressive": 0.14, "social": 0.72},
        "portrait": "res://assets/portraits/lyra.svg",
        "secret": "…혼자 울고 있었어요. 아무도 없는 곳에서요. 요즘 다들 너무 날카로워서, 약한 모습을 보이면 안 될 것 같았어요."
    },
    "dax": {
        "name": "Dax", "job": "시스템 설계사", "gender": "M", "accent": "8fa8ff",
        "concept": "냉정한 구조주의자", "vibe": "말수 적고 구조를 믿는 엔지니어",
        "speech": "hada", "speech_note": "하다체 · 원인과 결과로만 말한다",
        "social_goal": "사건을 사람보다 시스템과 행동 패턴의 문제로 본다",
        "pressure_response": "감정적 압박은 무시하고 논리의 빈틈만 되받아친다",
        "trust": 0.48, "personality": {"calm": 0.82, "aggressive": 0.21, "social": 0.26},
        "portrait": "res://assets/portraits/dax.svg",
        "secret": "승인되지 않은 진단 스크립트를 돌리고 있었다. 들키면 시스템 권한이 정지된다. 사건과의 인과관계는 없다."
    }
}

# Initial affinity nudges on top of the random roll (source -> target).
const AFFINITY_BIAS := {
    "mira:lyra": 0.18, "lyra:mira": 0.14, "noa:eli": 0.12, "eli:noa": 0.06,
    "sena:rho": -0.10, "rho:sena": -0.06, "dax:vale": -0.06, "vale:sena": 0.08
}

static func info(npc_id: String) -> Dictionary:
    return CREW.get(npc_id, {})

static func display_name(npc_id: String) -> String:
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

# Category pairs whose groups intersect to exactly this crew member.
static func identifying_pairs(npc_id: String) -> Array:
    var pairs: Array = []
    var categories: Array = TRAIT_CATEGORIES.keys()
    for a_index in range(categories.size()):
        for b_index in range(a_index + 1, categories.size()):
            var cat_a := str(categories[a_index])
            var cat_b := str(categories[b_index])
            var set_a: Array = group_members(cat_a, group_of(npc_id, cat_a))
            var set_b: Array = group_members(cat_b, group_of(npc_id, cat_b))
            var both: Array = []
            for member in set_a:
                if member in set_b:
                    both.append(member)
            if both.size() == 1 and both[0] == npc_id:
                pairs.append([cat_a, cat_b])
    return pairs

# Portrait for a display expression. uneasy/tense share the tense art.
static func portrait_path(npc_id: String, expression: String = "calm") -> String:
    var suffix := ""
    match expression:
        "warm": suffix = "_warm"
        "tense", "uneasy": suffix = "_tense"
    return "res://assets/portraits/%s%s.svg" % [npc_id, suffix]
