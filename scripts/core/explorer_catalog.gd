class_name AstraExplorerCatalog
extends RefCounted

# The six explorers (0.9.0 HUMAN VARIABLE). Identity changes how the explorer
# asks, how people first take them, and how they speak in a meeting. It never
# enters the case generator or the session RNG, never changes roles, clues,
# suspicion weights or votes, and grants no mechanical advantage.
#
# explorer_id (who) and art_id (which drawings) are separate: art_id names a
# pixel sheet made by tools/import_pixel_090.gd from the user's sheets in
# 미니 도트 캐릭/<이름>.png, and portraits come from tools/import_explorers_090.gd
# (플레이어/<이름>.png and the four expression sheets). Legacy saves keep their
# temporary look p1-p6 and their typed name, as a neutral explorer.
const ORDER := ["serin", "mika", "jace", "rael", "logan", "sia"]
const LEGACY_ART := ["p1", "p2", "p3", "p4", "p5", "p6"]
const ART_IDS := ["serin_a", "mika_a", "jace_a", "rael_a", "logan_a", "sia_a"]
const CARD_SPECIALTIES := {"serin": "신호·공간 분석", "mika": "장비 개조·현장 수리", "jace": "선발 진입·조종", "rael": "응급의료·생태 조사", "logan": "생존·구조", "sia": "지형·샘플 조사"}
const CARD_SUMMARIES := {"serin": "답을 끝까지 찾는 관찰자", "mika": "농담 뒤에 숨은 진지함", "jace": "먼저 나서는 책임감", "rael": "안전 앞에서는 단호하게", "logan": "말보다 귀환을 챙기는 사람", "sia": "계획 밖으로 향하는 호기심"}
const EXPLORERS := {
    "serin": {"name": "세린", "latin": "SERIN", "art_id": "serin_a",
        "specialty": "신호 분석 · 공간 스캔 · 미지 구조 해석",
        "summary": "남들이 넘긴 잡음에서도 반복되는 규칙을 찾는다.",
        "background": "혼자 포착한 신호는 장비 오류로 종결됐다. 세린은 그 기록을 지우지 않았다.",
        "reason": "모르는 채로 돌아오는 게 더 싫어서.",
        "selection": "이상하네. 분명 처음 보는 곳인데… 익숙해.",
        "approach": "말을 끝까지 듣고 모순을 찾는다. 답이 없으면 사람보다 확인을 앞세우기도 한다.",
        "first_impression": "조용한데, 너무 많이 보고 있다.",
        "opening": "우선 서로 기억하는 순서를 맞춰 보자. 안 맞는 부분은 남겨 두고.",
        "questions": ["{time}, 어디 있었는지 순서대로 들려줘.", "직접 본 것과 전해 들은 걸 나눠 줄래?", "누구 쪽 설명이 안 맞아? 이유도 듣고 싶어.", "결론부터 묻지 않을게. 천천히 말해 줘."]},
    "mika": {"name": "미카", "latin": "MIKA", "art_id": "mika_a",
        "specialty": "드론 운용 · 장비 개조 · 현장 수리",
        "summary": "농담으로 다가가지만 실제 장비 사고 앞에서는 진지해진다.",
        "background": "훈련소 드론 세 대를 무단 분해해 징계를 받았다. 다음 날 세 대 모두 성능이 나아졌다.",
        "reason": "새로운 곳에는 새로운 장난감이 있잖아?",
        "selection": "걱정 마. 폭발하면 실패고, 안 터지면 성공이지.",
        "approach": "농담으로 거리를 좁힌다. 무거운 얘기를 피하다가도 위험이 닥치면 손부터 움직인다.",
        "first_impression": "사고 칠 것 같은데, 이상하게 믿음직하다.",
        "opening": "멀쩡해 보이는 패널도 안쪽은 모르지. 사람 말도 열어 봐야겠네.",
        "questions": ["{time}엔 어디 있었어? 일단 동선부터 맞춰 보자.", "그때 마주친 사람 있어? 들은 얘기면 그것도 말해 줘.", "누가 걸려? 감 말고, 어디서 걸렸는지.", "잠깐 쉬자. 농담할 기분 아닌 거 알아. 기다릴게."]},
    "jace": {"name": "제이스", "latin": "JACE", "art_id": "jace_a",
        "specialty": "선발 진입 · 고속 기동 · 탐사선 조종",
        "summary": "먼저 들어가고, 다른 사람의 위험까지 자기 책임으로 떠안는다.",
        "background": "훈련 최단 귀환 기록에는 다른 대원 한 명을 업고 돌아왔다는 사실이 잘 드러나지 않는다.",
        "reason": "아무도 안 가봤다면 누군가는 첫 번째가 되어야지.",
        "selection": "길이 없다고? 아직 내가 안 가봤다는 뜻이겠지.",
        "approach": "먼저 행동하며 상대를 이끈다. 자기 때문에 누군가 다치는 일을 견디기 어렵다.",
        "first_impression": "이 사람 옆에 있으면 일이 빨리 움직인다.",
        "opening": "서두르다 사람을 놓치진 말자. 누가 어디 있었는지부터 듣겠어.",
        "questions": ["{time}, 어디까지 갔어? 네 동선부터 듣자.", "지나가면서 마주친 사람은? 직접 본 게 아니어도 구분해서 말해 줘.", "누구를 먼저 확인해야 할까? 네 이유도 알려 줘.", "지금 당장 답 안 해도 돼. 여기서 기다릴게."]},
    "rael": {"name": "라엘", "latin": "RAEL", "art_id": "rael_a",
        "specialty": "응급의료 · 생체환경 분석 · 외계 생태 조사",
        "summary": "작은 표정 변화부터 살피며 안전 문제에서는 물러서지 않는다.",
        "background": "철수 명령 뒤 부상자를 찾으러 혼자 돌아갔다. 기록에는 명령 불복종으로 남아 있다.",
        "reason": "살아 돌아와야 발견도 의미가 있으니까.",
        "selection": "다친 곳 없어? 좋아. 그럼 이제 위험한 얘기를 해보자.",
        "approach": "상태와 경계를 먼저 살핀다. 보호하려는 마음이 상대의 선택을 가릴 때도 있다.",
        "first_impression": "내가 숨기는 것까지 알아챌 것 같다.",
        "opening": "다들 일어났다고 괜찮은 건 아니야. 얘기는 한 사람씩 듣자.",
        "questions": ["말할 수 있겠어? {time}에 어디 있었는지 듣고 싶어.", "그때 본 사람이 있어? 다른 사람에게 들은 거면 그렇게 말해 줘.", "누가 마음에 걸려? 어떤 일 때문인지 같이 짚어 보자.", "널 몰아세우려는 게 아니야. 숨 고르고 말해도 돼."]},
    "logan": {"name": "로건", "latin": "LOGAN", "art_id": "logan_a",
        "specialty": "극한환경 생존 · 구조 · 위험지역 개척",
        "summary": "말보다 귀환 경로와 동료의 장비 잠금을 먼저 확인한다.",
        "background": "구조 요청 뒤 11일 동안 연락이 끊겼다가 혼자 돌아왔다. 그 시간에 대해서는 말하지 않는다.",
        "reason": "돌아올 방법이 없는 곳은 없어.",
        "selection": "들어가는 건 어렵지 않아. 문제는 나오는 쪽이지.",
        "approach": "필요한 말과 행동으로 신뢰를 쌓는다. 자기 약점과 과거는 좀처럼 내놓지 않는다.",
        "first_impression": "말은 없는데, 이미 최악의 경우까지 생각했다.",
        "opening": "출구부터 봤다. 이제 사람을 확인하지.",
        "questions": ["{time}. 위치와 동선은?", "목격자는? 전해 들었다면 출처도.", "누가 걸리지. 근거는?", "기다리지. 말할 수 있을 때 해."]},
    "sia": {"name": "시아", "latin": "SIA", "art_id": "sia_a",
        "specialty": "지형 조사 · 샘플 채취 · 미개척지 탐색",
        "summary": "먼저 말을 걸고 직접 확인한다. 호기심 때문에 계획을 벗어나기도 한다.",
        "background": "첫 실전에서 구역을 벗어나 발견한 동굴은 이후 핵심 조사 지점이 됐다. 규정 위반 감점은 남았다.",
        "reason": "이미 아는 곳을 보러 가는 건 여행이지. 탐사는 아니잖아?",
        "selection": "저 너머에 뭐가 있는지 궁금하지 않아?",
        "approach": "함께 확인하자고 손을 내민다. 거짓말은 서툴지만 중요한 보고를 빼먹을 수 있다.",
        "first_impression": "한눈팔면 사라져 있을 것 같다.",
        "opening": "처음 보는 곳인데 확인할 게 많네. 먼저 다녀온 사람부터 찾아보자.",
        "questions": ["{time}엔 어디 가 있었어? 거기서부터 얘기해 줘.", "거기서 누구 봤어? 전해 들은 얘기도 따로 듣고 싶어.", "넌 누구 쪽이 궁금해? 뭐가 걸렸는지 듣고 싶어.", "잠깐, 너무 빨리 물었지. 네 속도로 얘기해 줘."]}
}

# Which of the four drawn expressions carries each mood. The sheets hold, in
# order, the greeting smile, a strong reaction, a determined face, and a soft
# or tired one; each explorer's reaction is their own (Logan annoyed, Mika
# panicked, Serin puzzled, Sia flustered, Jace cocky, Rael startled-glad).
const MOODS := {
    "serin": {"neutral": 1, "smile": 1, "happy": 4, "suspicious": 3, "annoyed": 3, "embarrassed": 4, "shocked": 2, "sad": 2, "angry": 3, "determined": 3, "afraid": 2, "tired": 3},
    "mika": {"neutral": 1, "smile": 1, "happy": 1, "suspicious": 4, "annoyed": 4, "embarrassed": 4, "shocked": 3, "sad": 4, "angry": 4, "determined": 3, "afraid": 2, "tired": 4},
    "jace": {"neutral": 1, "smile": 2, "happy": 3, "suspicious": 2, "annoyed": 4, "embarrassed": 4, "shocked": 3, "sad": 4, "angry": 3, "determined": 3, "afraid": 4, "tired": 4},
    "rael": {"neutral": 1, "smile": 1, "happy": 4, "suspicious": 3, "annoyed": 3, "embarrassed": 4, "shocked": 2, "sad": 2, "angry": 3, "determined": 3, "afraid": 2, "tired": 4},
    "logan": {"neutral": 1, "smile": 1, "happy": 1, "suspicious": 2, "annoyed": 2, "embarrassed": 4, "shocked": 3, "sad": 4, "angry": 3, "determined": 3, "afraid": 3, "tired": 4},
    "sia": {"neutral": 1, "smile": 1, "happy": 3, "suspicious": 2, "annoyed": 2, "embarrassed": 2, "shocked": 2, "sad": 2, "angry": 3, "determined": 3, "afraid": 2, "tired": 4},
}

# How a crew member first takes a given explorer: a short exchange on the
# first conversation of a Stage. It is the starting tone of the relationship,
# not an affinity bonus — what the explorer does next matters more. Tags name
# the tone for tests and docs. Registers follow docs/CHARACTERS.md.
const FIRST_CONTACT := {
    "serin": {
        "vale": ["intellectual_resonance", "잡음이 네 박자마다 조금씩 비는 거, 너도 들었어?", "…그걸 들은 사람은 처음이에요. 보통은 여기서 결론부터 물어요. 순서부터 같이 봐 줄래요?"],
        "mira": ["concern_about_overwork", "난 괜찮아. 기록부터 보면 돼.", "눈 밑이 그렇지 않다고 하는데요. 답을 찾더라도 쉬는 건 잊지 말아요. 지금은 한 가지씩요."],
        "dax": ["pattern_vs_proof", "같은 오차가 세 번 반복됐어. 우연치고는 너무 가지런해.", "세 번이면 표본이 부족해. 네 번째를 보여 주면 그때 내 계산을 의심하지."],
        "noa": ["source_first", "기록에 없는 틈이 있어. 거기부터 보고 싶어.", "보는 건 좋아요. 그 틈을 누가 처음 말했는지도 같이 적어 두세요."],
        "rho": ["", "그 패널, 소리가 규칙적으로 튀어.", "어? 그걸 귀로 잡았어? …나중에 같이 열어 보자. 지금은 네 얘기부터."],
        "sena": ["", "문 기록이랑 사람 위치가 한 칸씩 어긋나.", "어긋난 칸 말고 사람부터 봐. 거기 누가 혼자 있었는지."],
        "eli": ["", "항로 표시가 네 기억이랑 같아?", "…같다고 말하려다 멈췄다. 그 질문은 나중에 다시 하지."],
        "lyra": ["", "잎 색이 날짜보다 오래돼 보여.", "그걸 먼저 보셨어요? 조용한 분인 줄 알았는데, 보는 건 누구보다 많네요."]},
    "mika": {
        "rho": ["tool_rivalry", "그 공구, 손잡이 테이프 네가 감은 거지? 방향 반대로 감았네.", "공구부터 찾는 눈이네? 좋아, 패널 뜯는 건 이따 같이 하고. 지금은 내 얘기부터 들어."],
        "dax": ["mutual_irritation", "시스템 로그 말고 실물부터 보면 안 돼? 뜯어 보면 금방인데.", "뜯기 전에 설계도부터 봐. …네가 고친 거라면 기록은 남겼겠지?"],
        "noa": ["record_friction", "고친 건 있는데, 적는 건 좀 이따 할게.", "지금 적어요. '이따'는 기록이 아니에요."],
        "mira": ["", "다친 데? 없어 없어. 손가락 하나 찍힌 거 빼고.", "그게 다친 거예요. 이리 줘 봐요. 농담은 붕대 감고 해요."],
        "sena": ["", "보안 문 잠금장치, 소리가 좀 이상하던데.", "장난이면 지금 말해. …진지하네. 그럼 위치부터 말해."],
        "vale": ["", "헤드셋 잡음, 케이블 쪽이면 내가 봐 줄 수 있는데.", "고마워요. …그런데 케이블이 아니면, 그땐 조용히 같이 들어 주세요."],
        "eli": ["", "지도 화면 좀 느리지 않아? 한 대 치면 빨라지던데.", "치지 마. 느린 게 아니라 다시 계산하는 중이다."],
        "lyra": ["", "이 물 순환 펌프, 소리 좋네. 누가 손봤어?", "제가 매일 닦아 줘요. 소리까지 들어 주는 사람은 처음이에요."]},
    "jace": {
        "sena": ["competitive_respect", "문까지는 내가 먼저 가 볼게.", "앞장서는 건 좋아. 대신 혼자 뛰어가진 마. 내가 볼 쪽도 남겨 둬."],
        "mira": ["no_heroics", "위험한 쪽은 내가 맡을게. 다들 뒤에 있어.", "영웅놀이는 의료실에서 제일 많이 봐요. 다치면 제가 제일 먼저 화낼 거예요."],
        "eli": ["route_trust", "최단 경로 말고, 돌아올 수 있는 경로로 알려 줘.", "그런 질문을 먼저 하는 선발대는 드물다. 좋아. 두 개 알려 주지."],
        "rho": ["", "엔진실 진동, 조종석에서도 느껴졌어.", "진짜? 그 정도면 꽤 큰데. 몇 시쯤이었어? …아니, 네 얘기부터 하자."],
        "dax": ["", "고민할 시간에 가 보면 되잖아.", "가 보기 전에 돌아올 조건부터 정해. 넌 그게 제일 빠르다고 생각 안 하겠지만."],
        "noa": ["", "기록은 나중에 봐도 되지 않아?", "나중에 보면 이미 늦은 기록이 돼요. 지금 봐요."],
        "vale": ["", "신호 따라가면 어디가 나와?", "…따라가기 전에, 한 번만 더 들어 봐요. 같은 자리에서 두 번 울렸어요."],
        "lyra": ["", "생태 구역은 내가 먼저 확인해도 돼?", "잎은 안 밟아 주시면요. 앞서 가는 분들은 발밑을 잘 안 보시거든요."]},
    "rael": {
        "mira": ["professional_respect", "요즘 수면 기록, 다들 괜찮아?", "상태부터 물어봐 주네요. 고마워요. 그래도 제 답도 다른 사람과 똑같이 확인해요."],
        "sena": ["protective_friction", "어깨, 안 좋은 거 같은데.", "…언제 봤어? 괜찮아. 그 얘긴 여기서 하지 마."],
        "noa": ["consent_first", "기록에 남기기 싫은 건 말 안 해도 돼.", "그렇게 말해 주는 사람은 드물어요. 대신 남겨도 되는 건 정확하게 남길게요."],
        "rho": ["", "손 떨리네. 커피 몇 잔째야?", "세 잔… 아니 네 잔. 알았어, 알았어. 그래도 말은 멀쩡해."],
        "dax": ["", "잠은 몇 시간 잤어?", "숫자로 물으면 대답하기 쉽지. 네 시간. …더 묻지 마."],
        "vale": ["", "귀가 아플 때까지 듣는 건 아니지?", "…아파지기 전에 벗어요. 가끔은요."],
        "eli": ["", "시계 자주 보네. 뭐가 걱정돼?", "걱정이 아니라 확인이다. …둘이 비슷하다는 건 알아."],
        "lyra": ["", "식물 쪽 공기, 네 호흡엔 괜찮아?", "제 걱정을 먼저 해 주시네요. 괜찮아요. 오늘은 잎이 더 걱정이에요."]},
    "logan": {
        "eli": ["quiet_trust", "출구 두 개. 하나는 막혔다.", "봤다. 좋아. 그럼 동선부터 맞추지."],
        "sena": ["quick_roles", "문은 내가 본다.", "그럼 난 사람. …말 안 해도 되는 사이는 편하네."],
        "rho": ["earned_trust", "공구는 손 닿는 데 둬라.", "잔소리 같은데… 맞는 말이라 할 말이 없네. 알았어."],
        "mira": ["hardest_patient", "문제없다.", "그 말 하는 사람이 제일 문제예요. 손목 줘 봐요."],
        "dax": ["", "대체 전원 경로는.", "두 개. 하나는 내가 안 믿는 거고. …네가 먼저 물을 줄은 몰랐네."],
        "noa": ["", "기록 사본은 어디 있지.", "두 군데요. 한 군데는 저만 알아요. 필요할 때 말할게요."],
        "vale": ["", "통신이 끊기면 대체 수단은.", "손으로 두드리는 신호가 있어요. …그걸 묻는 사람은 처음이에요."],
        "lyra": ["", "물은 며칠 치 남았지.", "스무 날이요. 식물 몫까지 넣으면 열여섯 날. 그걸 먼저 물어보시네요."]},
    "sia": {
        "lyra": ["shared_curiosity", "이 잎, 태그 날짜랑 색이 안 맞지 않아?", "보고 싶은 게 많죠? 하나씩 같이 봐요. 본 것과 아직 안 본 것도 나누고요."],
        "sena": ["protective_friction", "저쪽 복도 끝, 잠깐만 보고 올게!", "궁금한 건 알겠는데, 어디 가는지는 말하고 가. 찾으러 다니게 하지 말고."],
        "noa": ["report_friction", "아까 잠깐 저쪽 다녀왔어. 별거 없었어.", "그 '잠깐'이 몇 분이었는지, 어디였는지부터 말해 줘요."],
        "dax": ["exception_maker", "지도에 없는 통로가 있던데.", "…지도에 없는 건 내 설계에도 없다는 뜻이야. 어디였는지 정확히 말해."],
        "rho": ["", "저 환풍구 안쪽, 들어가 봐도 돼?", "안 돼. …아니, 나랑 같이면 돼. 혼자는 절대 안 돼."],
        "mira": ["", "나 멀쩡해! 봐, 뛸 수도 있어.", "뛰지 말고요. 앉아요. 멀쩡한지는 제가 볼게요."],
        "vale": ["", "그 신호, 처음 잡힌 장소부터 가 보자.", "…같이 가요. 혼자 가면 신호보다 당신을 찾느라 바빠질 거예요."],
        "eli": ["", "이 구역 너머엔 뭐가 있어?", "지금은 아무것도. …아무것도 없어야 맞는 곳이다."]},
}

# Rotation: a Stage features a few of the pairs, so the same exchange does not
# open every Stage of a campaign. Deterministic from the Stage index alone.
static func first_contact(id: String, crew_id: String, stage: int) -> Array:
    var pairs: Dictionary = FIRST_CONTACT.get(id, {})
    if not pairs.has(crew_id):
        return []
    var entry: Array = pairs[crew_id]
    var order := AstraCrewCatalog.ORDER.find(crew_id)
    # Tagged pairs (the relationships that define the explorer) come up in the
    # first two Stages and then every third; the rest rotate.
    if str(entry[0]) != "" and (stage <= 2 or (stage + order) % 3 == 0):
        return entry
    if str(entry[0]) == "" and (stage + order) % 3 == 1:
        return entry
    return []

# Each explorer's own public voice for the meeting moves. Same placeholders,
# in the same order, as the default line the session passes in.
const MEETING_VOICE := {
    "serin": {"present": "내가 들은 걸 순서대로 놓을게. %s", "defend": "%s|eul 보내기엔 빈칸이 너무 많아. 확인된 것부터 다시 보자.",
        "compare": "%s, %s. 두 사람 다 %s에 어디 있었는지 한 번 더. 순서가 어디서 갈리는지 보고 싶어.",
        "support": "나도 %s 쪽 설명에서 한 칸이 비어. 거기를 채워 줘.", "press": "%s, 그 시간 동선을 처음부터. 빠진 칸 없이.",
        "hearsay": "%s, 직접 본 사람한테 듣고 싶어. 들은 말은 한 번 옮길 때마다 조금씩 달라져.", "clarify": "잠깐. 확인된 말과 아직 추측인 말을 나눠 놓자.",
        "coax": "%s, 사건과 상관없는 일이면 지금 말해도 돼. 그걸로 널 보내진 않아.", "basis": "잠깐. %s, %s|eul 의심하는 근거를 처음부터 다시."},
    "mika": {"present": "자, 들은 거 풀어 볼게. %s", "defend": "%s|eul 보내기엔 부품이 모자라. 확인된 것부터 조립하자.",
        "compare": "%s, %s. 둘 다 %s에 어디 있었는지 다시 말해 봐. 한쪽은 분명 어디가 헐거울 거야.",
        "support": "나도 %s 쪽이 걸려. 설명 좀 더 줘.", "press": "%s, 그 시간 동선 처음부터. 농담 아니야.",
        "hearsay": "%s, 직접 본 사람 누구야? 건너 들은 거면 나사 하나씩 빠져 있을걸.", "clarify": "잠깐만. 확인된 거랑 추측인 거, 따로 놓자.",
        "coax": "%s, 사건이랑 상관없는 거면 지금 말해. 그걸로 아무도 너 안 보내.", "basis": "잠깐. %s, %s|eul 의심하는 근거 다시 말해 줄래?"},
    "jace": {"present": "내가 들은 거 먼저 꺼낼게. %s", "defend": "%s|eul 보내기엔 근거가 부족해. 내가 틀리면 그건 내가 질게.",
        "compare": "%s, %s. 둘 다 %s에 어디 있었는지 다시 말해 줘. 지금 여기서 맞춰 보자.",
        "support": "나도 %s 쪽이 걸려. 설명 더 들어야겠어.", "press": "%s, 그 시간 동선 처음부터 다시. 천천히.",
        "hearsay": "%s, 직접 본 사람한테 듣자. 네가 뭘 봤는지 정확히.", "clarify": "잠깐, 확인된 거랑 아직 추측인 거 나눠서 가자.",
        "coax": "%s, 사건이랑 상관없는 일이면 지금 말해. 그걸로 널 보내게 두진 않아.", "basis": "잠깐. %s, %s|eul 의심하는 근거부터 다시 들려줘."},
    "rael": {"present": "들은 걸 말할게. 누굴 몰려는 게 아니라, 다 같이 보자고. %s", "defend": "%s|eul 몰아가기엔 근거가 부족해. 확인된 것부터 봐.",
        "compare": "%s, %s. 두 사람 다 %s에 어디 있었는지 다시 말해 줄래? 천천히 해도 돼.",
        "support": "나도 %s 쪽이 마음에 걸려. 설명을 더 듣고 싶어.", "press": "%s, 그 시간 동선을 처음부터 말해 줘. 숨 고르고.",
        "hearsay": "%s, 직접 본 사람한테 듣고 싶어. 정확히 뭘 봤는지.", "clarify": "잠깐. 확인된 말과 아직 추측인 부분을 나눠 보자.",
        "coax": "%s, 사건이랑 상관없는 일이면 지금 말해도 괜찮아. 그걸로 아무도 널 보내지 않아.", "basis": "잠깐. %s, %s|eul 의심하는 근거부터 다시 말해 줄래?"},
    "logan": {"present": "들은 거다. %s", "defend": "%s. 근거 부족. 확인된 것부터.",
        "compare": "%s, %s. %s. 둘 다 위치.", "support": "%s. 나도 걸린다. 설명해.", "press": "%s. 그 시간 동선. 처음부터.",
        "hearsay": "%s. 직접 봤나. 뭘.", "clarify": "잠깐. 확인된 것과 추측을 나눈다.",
        "coax": "%s. 사건과 상관없으면 지금 말해. 그걸로 널 보내진 않는다.", "basis": "%s. %s|eul 의심하는 근거."},
    "sia": {"present": "나 이거 들었어! 다 같이 들어 봐. %s", "defend": "%s|eul 보내기엔 아직 못 본 데가 많아. 확인된 것부터 보자.",
        "compare": "%s, %s! 둘 다 %s에 어디 있었는지 다시 말해 줘. 지도 펴 놓고 보자.",
        "support": "나도 %s 쪽이 궁금해. 설명 더 해 줘.", "press": "%s, 그 시간 어디부터 어디까지 갔는지 처음부터 말해 줘.",
        "hearsay": "%s, 직접 본 거야? 누구한테 들은 거면 그 사람한테 가서 물어보자.", "clarify": "잠깐! 확인된 거랑 추측인 거 나눠 보자.",
        "coax": "%s, 사건이랑 상관없는 거면 지금 말해도 돼. 그걸로 아무도 너 안 보내.", "basis": "잠깐, %s. %s|eul 의심하는 이유 다시 말해 줄래?"},
}

static func data(id: String) -> Dictionary:
    return Dictionary(EXPLORERS.get(id, {})).duplicate(true)

static func normalize(profile: Dictionary) -> Dictionary:
    var id := str(profile.get("explorer_id", ""))
    if id not in ORDER:
        id = "neutral"
    var art := str(profile.get("art_id", profile.get("preset", "p1")))
    if art not in LEGACY_ART:
        art = "p1"
    var name := str(profile.get("name", "")).strip_edges().left(10)
    if id in ORDER:
        art = str(EXPLORERS[id]["art_id"])
        name = str(EXPLORERS[id]["name"])
    return {"explorer_id": id, "art_id": art, "preset": art, "name": name}

static func profile_for(id: String) -> Dictionary:
    return normalize({"explorer_id": id})

static func art_dir(id: String) -> String:
    return "res://assets/explorers/%s/" % id

static func full_path(id: String) -> String:
    var path := art_dir(id) + "full.webp"
    return path if id in ORDER and ResourceLoader.exists(path) else ""

static func bust_path(id: String, mood: String = "neutral") -> String:
    if id not in ORDER:
        return ""
    var index := int(MOODS.get(id, {}).get(mood, 1))
    var path := art_dir(id) + "bust_%d.webp" % index
    return path if ResourceLoader.exists(path) else ""

# The explorer's illustrated portrait (for cards and larger frames).
static func portrait_path(id: String) -> String:
    return bust_path(id, "neutral")

static func head_path(id: String) -> String:
    var path := art_dir(id) + "head.webp"
    return path if id in ORDER and ResourceLoader.exists(path) else ""

# The small face used next to the explorer's lines: the illustrated head for
# the six, the pixel face for a legacy look.
static func face_path(profile: Dictionary) -> String:
    var p := normalize(profile)
    var head := head_path(str(p["explorer_id"]))
    return head if head != "" else "res://assets/pixel080/player/%s_face.png" % p["art_id"]

static func question(id: String, intent: String, fallback: String) -> String:
    if id not in ORDER:
        return fallback
    var index := ["STATEMENT", "WITNESS", "SUSPECT", "REASSURE"].find(intent)
    return str(EXPLORERS[id]["questions"][index]) if index >= 0 else fallback

# What the explorer actually says for the moves that are not question
# buttons (the button keeps its own label, e.g. which log is opened).
const SPOKEN := {
    "serin": {"RECORD": "그 기록, 같이 열어 보자. 시각부터 맞춰 보고 싶어.", "PRESSURE": "지금 말 안 하면 회의에서 내가 순서대로 꺼낼 거야."},
    "mika": {"RECORD": "그 기록, 지금 열어 보자. 뜯어 보면 금방이야.", "PRESSURE": "농담 아니야. 지금 말 안 하면 회의에서 내가 말할게."},
    "jace": {"RECORD": "그 기록, 지금 같이 열자. 미룰 이유 없잖아.", "PRESSURE": "지금 말 안 하면 회의에서 내가 꺼낼 거야. 그 책임은 내가 질게."},
    "rael": {"RECORD": "그 기록, 같이 봐도 될까? 네가 괜찮다면.", "PRESSURE": "몰아세우고 싶진 않아. 그래도 지금 말 안 하면 회의에서 말할 수밖에 없어."},
    "logan": {"RECORD": "기록. 지금 연다.", "PRESSURE": "지금 말해. 아니면 회의에서 내가 한다."},
    "sia": {"RECORD": "그 기록 지금 열어 볼 수 있어? 같이 보자!", "PRESSURE": "지금 말 안 하면 회의에서 내가 다 말해 버릴 거야."},
}

static func spoken(id: String, intent: String, fallback: String) -> String:
    if id in ORDER and SPOKEN[id].has(intent):
        return str(SPOKEN[id][intent])
    return question(id, intent, fallback)

static func meeting_line(id: String, key: String, fallback: String) -> String:
    return str(MEETING_VOICE.get(id, {}).get(key, fallback))

# Kept for 0.9.0 callers: the crew's side of a first contact, any Stage.
static func first_tone(id: String, crew_id: String) -> String:
    var entry: Array = FIRST_CONTACT.get(id, {}).get(crew_id, [])
    return str(entry[2]) if entry.size() > 2 else ""
