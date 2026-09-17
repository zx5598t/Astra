class_name AstraHelp
extends RefCounted

static func text() -> String:
    var c := AstraUI.hex(AstraUI.CYAN)
    var g := AstraUI.hex(AstraUI.GOLD)
    var m := AstraUI.hex(AstraUI.MUTED)
    var r := AstraUI.hex(AstraUI.RED)
    return "\n".join(PackedStringArray([
        "[font_size=22][color=#%s]목표[/color][/font_size]" % c,
        "승무원 8명 중 2명은 Null입니다. 두 Null은 사건 당시 서로 다른 장소에서 조작을 하나씩 실행했습니다. 최대 %d일 안에 두 명을 모두 격리하면 승리합니다. 살아남은 승무원 수가 Null과 같아지면 패배합니다." % AstraGameSession.MAX_DAYS,
        "",
        "[font_size=22][color=#%s]하루의 흐름[/color][/font_size]" % c,
        "[b]브리핑[/b] → [b]현장 조사[/b] → [b]개인 심문[/b] → [b]공개 회의[/b] → [b]격리 투표[/b] → [b]밤[/b]",
        "화면 아래 큰 버튼(또는 Space)으로 다음 단계로 넘어갑니다.",
        "",
        "[font_size=22][color=#%s]1. 현장 조사 — 흔적은 ‘후보 명단’이다[/color][/font_size]" % g,
        "구역을 조사하면 단서가 나옵니다. 흔적은 범인의 이름 대신 [b]후보 명단[/b]을 줍니다. 예: ‘내열 섬유 — Rho, Dax’, ‘기술 권한(B등급) — Rho, Vale, Eli’.",
        "같은 조작에서 나온 흔적 두 개의 명단이 [b]겹치는 한 사람[/b]이 그 조작의 실행자입니다. 오른쪽 [b]추리 노트[/b] 탭이 조작별로 교차표를 그려 줍니다.",
        "[color=#%s]주의: 기록 시각이 사건 시간대 밖인 흔적은 사건과 무관합니다. 뒤 사건일수록 이런 흔적이 섞여 있습니다.[/color]" % r,
        "",
        "[font_size=22][color=#%s]2. 개인 심문 — 알리바이와 모순[/color][/font_size]" % g,
        "알리바이(어디에, 누구와)를 모아 [b]출입 기록[/b]과 대조하세요. 같은 곳에 있었다면서 서로를 못 봤다는 두 사람도 모순입니다.",
        "모순이 생긴 사람을 [b]추궁[/b]하면, 사건과 무관한 사정을 숨긴 승무원은 신뢰가 충분할 때 털어놓고, Null은 긴장이 높을 때 [b]실언[/b]을 합니다. 실언은 결정적인 단서가 됩니다.",
        "[color=#%s]거짓말하는 사람이 모두 Null은 아닙니다. 사건마다 사정을 숨긴 무고한 승무원이 한 명 있습니다.[/color]" % m,
        "승무원이 따로 면담을 요청하기도 합니다. 고른 답에 따라 단서를 주거나, 상대가 Null이라면 교묘한 거짓 정보를 줄 수 있습니다.",
        "",
        "[font_size=22][color=#%s]3. 공개 회의 — 여론 움직이기[/color][/font_size]" % g,
        "첫 회의에서 모두가 알리바이를 공개하고, 같은 장소에 있던 사람들이 서로 반박합니다. 조사관은 발언권 2회로 [b]단서 공개[/b], [b]지목[/b], [b]변호[/b]를 할 수 있습니다.",
        "공개된 근거가 있는 지목은 설득력이 크고, 근거 없는 지목은 조사관의 신뢰를 떨어뜨립니다. 명단에는 각자의 [b]투표 의향[/b]이 실시간으로 표시됩니다.",
        "",
        "[font_size=22][color=#%s]4. 격리 투표와 추리 보고서[/color][/font_size]" % g,
        "조사관의 표는 %d표로 계산됩니다. 격리된 사람의 정체는 사건이 끝날 때까지 공개되지 않습니다(감사관 제외)." % AstraGameSession.PLAYER_VOTE_WEIGHT,
        "명단 오른쪽 버튼으로 두 명을 [b]N(Null 의심)[/b]으로 표시해 두면 투표할 때 추리 보고서가 함께 제출되고, 사건 종료 후 채점됩니다.",
        "",
        "[font_size=22][color=#%s]5. 밤[/color][/font_size]" % g,
        "Null은 밤마다 한 명을 습격하고, 자신을 가리키는 흔적을 지우려 합니다. 한 명을 [b]보호[/b]하거나 한 구역을 [b]감시[/b]하세요. 막아 내면 침입자의 흔적이 새 단서로 남습니다.",
        "밤에 습격당한 사람은 확실한 승무원입니다. 그 사람이 누구를 의심했는지도 생각해 보세요.",
        "",
        "[font_size=22][color=#%s]조사 방식[/color][/font_size]" % c,
        "[b]분석관[/b] 매일 조사 행동력 +1 · [b]공감관[/b] 매일 심문 행동력 +1, 거짓말 징후를 더 잘 읽음 · [b]감사관[/b] 검시 기록을 들고 시작, 격리한 사람의 정체를 밤마다 확인",
        "",
        "[font_size=22][color=#%s]단축키[/color][/font_size]" % c,
        "Space/Enter 다음 단계 · 1~8 승무원 선택 · M 선택한 승무원 표시 변경 · Tab 노트 탭 전환 · Esc 메뉴 · F11 전체 화면"
    ]))
