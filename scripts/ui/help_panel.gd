class_name AstraHelpPanel
extends RefCounted

# Help, kept short and in plain words. Two surfaces:
#   glossary()  what each word in the game means (opened with 용어 / H)
#   how_to()    the whole Day in six lines (menu → 플레이 방법)
# No rule is explained here that the player has not already met in play.

const TERMS := [
    ["Null", "승무원의 몸으로 움직이며 기록을 지우고, 밤에는 사람을 해치는 존재. 겉으로는 구별되지 않는다. 자기가 한 일을 숨기지만 말투와 성격은 원래 그 사람 그대로다."],
    ["탐사요원", "당신. ASTRA의 기록이 다시 맞춰질 때도 기억을 잃지 않는 유일한 사람."],
    ["STAGE", "배가 한 번 깨어나 있는 동안. Stage가 끝나면 기록이 다시 맞춰지고(재동기화), 모두가 포드에서 다시 깨어난다. 그때마다 Null도 새로 정해진다. 지난 Stage의 답이 이번 답은 아니다."],
    ["DAY", "Stage 안의 하루. 아침 → 대화 → 회의 → 투표 → 밤. 매일 한 사람이 포드로 간다."],
    ["장기수면 격리 (포드)", "투표로 정한 한 사람을 수면 포드에 재운다. 죽이는 게 아니다. 그 Stage가 끝날 때까지 말하지도, 투표하지도, 움직이지도 못한다. 정체는 끝날 때까지 공개되지 않는다."],
    ["사망 (신호 두절)", "밤에 Null에게 당해 생체 신호가 끊긴 상태. 그 Stage에서는 돌아오지 않는다. 재동기화 뒤에는 다시 깨어난다 — 기억하는 건 당신뿐이다."],
    ["기록", "출입 인증, 단말 접속, 생체 태그처럼 장비에 남은 것. 담당자가 열어 봐야 알 수 있다. 대화에서 ‘기록 확인’을 고르면 함께 열어 볼 수 있다(하루 1번)."],
    ["증언 / 전해 들은 말", "누군가 직접 본 것은 증언, 다른 사람에게 들은 것은 전언. 한 사람의 말만으로는 힘이 약하다. 다른 증언이나 기록이 같은 쪽을 가리키면 모두가 믿기 시작한다."],
    ["말이 안 맞음", "두 사람의 말이 동시에 사실일 수 없는 상태. 거짓말이 곧 Null은 아니다. 창피해서, 누군가를 감싸려고, 착각해서 말이 어긋나는 사람도 있다."],
    ["개입", "회의 중 당신이 한 번 끼어드는 것. 재확인시키기, 되묻기, 감싸기, 기록 꺼내기, 지목하기 중 그 순간에 맞는 것이 나온다. 당신을 믿는 사람일수록 당신 말에 따라 표를 옮긴다."],
    ["결선 투표", "최다 득표가 같으면 그 사람들만 두고 다시 투표한다. 또 같으면 당신이 정한다. 기권은 없다."],
    ["재동기화", "Stage가 끝날 때 ASTRA가 기록을 다시 맞추는 일. 격리됐거나 쓰러졌던 사람도 다음 Stage에 다시 깨어난다."],
    ["PART II · 전문 프로토콜", "Stage 5부터 Null이 둘이 된다. 대신 복구된 보안 기능 하나를 고를 수 있다. 가디언(밤에 한 사람 지키기), 애널리스트(두 말 정밀 대조), 엠패스(한 번 더 묻거나 말하기)."],
    ["Aegis 차폐막", "가디언 프로토콜로 쓰는 비상 격벽 전력. Stage당 두 번. 막아 내면 누가 노려졌는지만 알 수 있고, 누가 노렸는지는 알 수 없다."]
]

static func glossary() -> Control:
    var box := AstraUI.vbox(10)
    for term in TERMS:
        var card := AstraUI.panel(AstraUI.PANEL_2, AstraUI.BORDER, 10, 12)
        var inner := AstraUI.vbox(4)
        card.add_child(inner)
        inner.add_child(AstraUI.label(str(term[0]), AstraUI.T_HEAD, AstraUI.CYAN))
        inner.add_child(AstraUI.prose(str(term[1]), AstraUI.T_UI, AstraUI.TEXT))
        box.add_child(card)
    return box

const HOW_TO := [
    ["목표", "승무원 사이에 숨은 Null을 찾아 장기수면 포드에 재운다. Null을 모두 재우면 이 Stage는 끝난다. 당신이 밤에 쓰러지거나, Null과 나머지의 표 수가 같아지면 실패."],
    ["아침", "밤사이 일어난 일과 오늘의 사건을 사람들이 직접 말해 준다. 끝까지 읽으면 바로 대화로 넘어간다."],
    ["대화", "얼굴을 누르면 바로 이야기가 시작된다. 오늘은 모두의 말을 다 듣지 못한다. 금색 표시는 오늘 사건과 관련된 일을 맡은 사람이다. 말이 어긋나면 그걸 들이밀 수 있다."],
    ["회의", "사람들이 한 가지씩 논쟁하고 멈춘다. 그때 한 번 끼어들 수 있다. 당신만 아는 기록이나 증언을 꺼내면 판이 바뀐다."],
    ["투표", "모두 한 표씩, 기권 없음. 가장 많이 지목된 사람이 포드로 간다. 정체는 끝까지 비밀이다."],
    ["밤", "Null이 한 사람을 노린다. PART II에서 가디언을 골랐다면 Aegis로 한 사람을 지킬 수 있다. 결과는 다음 날 아침에 사람들이 전한다."]
]

static func how_to() -> Control:
    var box := AstraUI.vbox(10)
    for row in HOW_TO:
        var card := AstraUI.panel(AstraUI.PANEL_2, AstraUI.BORDER, 10, 12)
        var inner := AstraUI.vbox(4)
        card.add_child(inner)
        inner.add_child(AstraUI.label(str(row[0]), AstraUI.T_HEAD, AstraUI.GOLD))
        inner.add_child(AstraUI.prose(str(row[1]), AstraUI.T_UI, AstraUI.TEXT))
        box.add_child(card)
    box.add_child(shortcuts())
    return box

# Kept for callers from 0.7.x (pause menu, title archive).
static func codex(_unlocked: Array) -> Control:
    var scroller := AstraUI.scroll(how_to())
    scroller.custom_minimum_size.y = 520
    return scroller

static func screen_help(_phase: String, objective: String = "", _budget: Dictionary = {}) -> Control:
    var box := AstraUI.vbox(12)
    if objective != "":
        box.add_child(AstraUI.objective_strip(objective))
    box.add_child(how_to())
    return box

static func shortcuts() -> Control:
    var box := AstraUI.vbox(6)
    box.add_child(AstraUI.label("단축키", AstraUI.T_HEAD, AstraUI.CYAN))
    for row in [
        ["Space / 클릭", "다음 대사 · 대사 넘기기"],
        ["N", "노트"],
        ["H", "용어 풀이"],
        ["Esc", "메뉴"],
        ["F11", "전체 화면"]
    ]:
        var line := AstraUI.hbox(12)
        var key := AstraUI.label(str(row[0]), AstraUI.T_META, AstraUI.GOLD)
        key.custom_minimum_size.x = 140
        line.add_child(key)
        line.add_child(AstraUI.label(str(row[1]), AstraUI.T_META, AstraUI.TEXT))
        box.add_child(line)
    return box
