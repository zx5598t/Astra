class_name AstraHelpPanel
extends RefCounted

# Builds the two help surfaces the player can open.
#
# 0.3.1 had exactly one: a single scrolling page covering every rule in the
# game, offered to a player who had not yet pressed a button. It was accurate
# and nobody could use it. These two replace it:
#
#   screen_help(phase)  answers "what is this screen and what can I do here"
#   codex(unlocked)     is the reference, filtered to what has actually appeared
#
# Neither of them explains the whole game at once, and neither of them uses a
# term the player has not met in play.

static func screen_help(phase: String, objective: String = "") -> Control:
    var info := AstraCodex.screen(phase)
    var box := AstraUI.vbox(14)
    if objective != "":
        box.add_child(AstraUI.objective_strip(objective))
    box.add_child(AstraUI.label(str(info.get("purpose", "")), AstraUI.T_HEAD, AstraUI.CYAN))
    for point in info.get("points", []):
        var row := AstraUI.hbox(10)
        row.add_child(AstraUI.label("·", AstraUI.T_BODY, AstraUI.DIM))
        row.add_child(AstraUI.prose(str(point), AstraUI.T_BODY, AstraUI.TEXT))
        box.add_child(row)
    box.add_child(AstraUI.label("전체 도움말은 메뉴 → 기록 보관소에서 볼 수 있습니다.", AstraUI.T_META, AstraUI.DIM))
    return box

static func codex(unlocked: Array) -> Control:
    var topics := AstraCodex.topics(unlocked)
    var box := AstraUI.vbox(16)
    box.add_child(AstraUI.prose("지금까지 등장한 내용만 보입니다. 새로운 시스템을 만나면 항목이 늘어납니다.", AstraUI.T_META, AstraUI.DIM))
    for topic in topics:
        var card := AstraUI.panel(AstraUI.PANEL_2, AstraUI.BORDER, 10, 14)
        var inner := AstraUI.vbox(6)
        card.add_child(inner)
        inner.add_child(AstraUI.label(str(topic.get("title", "")), AstraUI.T_HEAD, AstraUI.CYAN))
        inner.add_child(AstraUI.prose(str(topic.get("body", "")), AstraUI.T_BODY, AstraUI.TEXT))
        box.add_child(card)
    var scroller := AstraUI.scroll(box)
    scroller.custom_minimum_size.y = 520
    return scroller

# Keyboard reference, shown alongside the codex rather than mixed into it.
static func shortcuts() -> Control:
    var box := AstraUI.vbox(6)
    box.add_child(AstraUI.label("단축키", AstraUI.T_HEAD, AstraUI.CYAN))
    for row in [
        ["Space / 클릭", "다음으로"],
        ["1 ~ 8", "승무원 선택"],
        ["N", "조사 노트"],
        ["M", "내 판단 표시"],
        ["H", "이 화면 도움말"],
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
