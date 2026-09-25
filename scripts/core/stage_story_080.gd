class_name AstraStageStory
extends RefCounted

# 0.8.0 CONTAINMENT — authored Stage / Day story content.
#
# Content only. AstraGameSession decides when a beat plays and fills its
# {tokens} through AstraJosa. Every beat must be safe for every hidden-role
# assignment: nobody here says or implies who the Null is, and a person who can
# be dead or isolated never speaks in a beat that plays after that can happen.
#
# Stage framing (canon, kept from 0.7.x): each Stage is one wake cycle of ASTRA.
# When a Stage ends the ship re-synchronises its records and everyone wakes in
# their pod again, one more pod opens, and only the explorer remembers what
# happened in the cycle before. That is why the isolated and the lost are back
# at the start of the next Stage, and why Null can be anyone again.

const NULL_RULE := "Null — 승무원의 몸으로 기록을 지우고, 밤에는 사람을 해치는 무언가. 당사자는 자신이 한 일을 숨기며, 겉으로는 구별되지 않는다."
const CONTAINMENT_RULE := "장기수면 격리는 죽음이 아니다. 포드에 잠긴 사람은 이 Stage가 끝날 때까지 말하지도, 투표하지도, 움직이지도 못한다."

# Scene art keys map to AstraArt.background().
const STAGE_ART := {
    "CALIBRATION":"medical", "DEAD_AIR":"bridge", "GLASS_GARDEN":"garden", "ECHO_WARD":"medical",
    "SILENT_ORBIT":"bridge", "RED_SHIFT":"garden", "LAST_LIGHT":"engine", "SECOND_WATCH":"archive",
    "BORROWED_DAYS":"lounge", "BLIND_DECK":"breach", "THREE_MINUTES_DARK":"engine", "CONTINUITY":"garden",
    "THRESHOLD":"bridge"
}

# Location names for rooms that exist only in 0.8.0 incidents or commons.
const LOCATION_NAMES := {
    "medbay":"의료실", "engine":"기관실", "comms":"통신실", "archive":"기록보관실", "lounge":"중앙 라운지",
    "quarters":"승무원 선실 구역", "galley":"식당", "security":"보안허브", "garden":"수목구역",
    "relay":"중계실", "deck":"관측 데크", "navigation":"항법실", "beacon":"비콘 제어실",
    "reactor":"심장로", "core":"코어실", "service":"정비 구역", "bridge":"함교"
}

# How an incident was done decides which expert can say something about it and
# which excuse a Null can reach for. Each method names the inference experts in
# priority order; the inference is a real, checkable limit of the equipment.
const METHODS := {
    "manual_console": {"experts":["rho","dax"], "excuse":"remote", "fact":"그 콘솔은 원격 명령을 받지 않는다. 누군가 콘솔 앞에 서서 직접 입력해야 한다."},
    "power_panel": {"experts":["rho","dax"], "excuse":"auto", "fact":"분배반은 손으로 레버를 내려야 움직인다. 자동 전환 기록은 없다."},
    "door_override": {"experts":["sena","rho"], "excuse":"card", "fact":"그 문은 안쪽 패널에서 손으로 해제해야 열린다. 카드만으로는 열리지 않는다."},
    "signal_route": {"experts":["vale","noa"], "excuse":"remote", "fact":"그 신호 승인은 중계 단말 앞에서만 가능하다. 원격 승인 경로는 막혀 있다."},
    "data_erase": {"experts":["noa","dax"], "excuse":"remote", "fact":"삭제는 로컬 단말에서 실행됐다. 원격 접속 흔적이 남지 않았다."},
    "bio_monitor": {"experts":["mira","lyra"], "excuse":"auto", "fact":"그 모니터는 의료실 안에서만 끌 수 있다. 자동 절전 기록은 없다."},
    "nav_console": {"experts":["eli","dax"], "excuse":"remote", "fact":"항법 구간은 항법실 콘솔에서만 지울 수 있다. 원격 편집 권한은 잠겨 있다."},
    "eco_system": {"experts":["lyra","mira"], "excuse":"auto", "fact":"표본 분류는 생태 단말에 직접 접속해야 바뀐다. 자동 재분류 기능은 없다."}
}

# Daily incidents. Day 1 opens the Stage; later Days rotate with a new time.
# minute = minutes after 00:00 of the incident clock. records = record types
# (AstraCrewCatalog.RECORD_DOMAIN) that can have caught the actor.
const INCIDENTS := {
    "CALIBRATION": [
        {"id":"pod_unlock", "title":"수면 포드 잠금 해제", "room":"medbay", "minute":257, "second":20, "method":"manual_console",
            "records":["terminal","vitals","system"], "stake":"잠든 네 사람 중 한 명의 생명유지 장치",
            "summary":"04:17, 의료실 포드 하나의 생명유지 잠금이 수동으로 풀렸다. 실행자 서명은 비어 있다."},
        {"id":"pod_power", "title":"포드 전원 우회", "room":"engine", "minute":168, "second":40, "method":"power_panel",
            "records":["power","system","terminal"], "stake":"수면 포드 구역 전체의 전력",
            "summary":"02:48, 기관실 분배반에서 수면 포드 구역 전력이 비상 회로로 돌려졌다. 비상 회로는 30분밖에 버티지 못한다."},
        {"id":"log_wipe", "title":"각성 로그 초기화", "room":"comms", "minute":185, "second":5, "method":"data_erase",
            "records":["terminal","system","vitals"], "stake":"각성 이후의 모든 기록",
            "summary":"03:05, 통신실 콘솔의 각성 이후 로그가 통째로 지워졌다. 누가 언제 깨어났는지부터 흐려졌다."}
    ],
    "DEAD_AIR": [
        {"id":"comms_shutdown", "title":"외부 송신 채널 차단", "room":"comms", "minute":457, "second":40, "method":"signal_route",
            "records":["comms","terminal","door"], "stake":"외부로 나가는 유일한 교신",
            "summary":"07:37, 외부 송신 채널이 절차대로 닫혔다. 사고가 아니다. 누군가 정확한 순서대로 채널을 껐다."},
        {"id":"seal_broken", "title":"목적지 문서 봉인 훼손", "room":"archive", "minute":132, "second":10, "method":"data_erase",
            "records":["terminal","door","system"], "stake":"서로 다른 목적지를 적은 두 원본",
            "summary":"02:12, 기록보관실에서 귀환 승인서 원본의 보존 봉인이 뜯겼다. 탐사 명령서는 그대로다. 누군가 한쪽만 지우려 했다."},
        {"id":"vitals_dark", "title":"생체 모니터 차단", "room":"medbay", "minute":220, "second":0, "method":"bio_monitor",
            "records":["vitals","door","terminal"], "stake":"수면 중인 동료들의 생체 기록",
            "summary":"03:40, 의료실 생체 모니터가 11분 동안 꺼졌다. 그 사이 누가 의료실에 있었는지 남은 기록이 없다."}
    ],
    "GLASS_GARDEN": [
        {"id":"security_blackout", "title":"보안 구역 전력 차단", "room":"security", "minute":1163, "second":5, "method":"power_panel",
            "records":["door","power","system"], "stake":"잠긴 보안 구역의 전력",
            "summary":"19:23, 잠긴 보안 구역의 전력이 수동으로 차단됐다. 세나의 근무 기록과 준의 배치 기록이 같은 날을 다르게 말한다."},
        {"id":"roster_erased", "title":"근무 대조본 삭제", "room":"garden", "minute":90, "second":30, "method":"data_erase",
            "records":["terminal","environment","door"], "stake":"세나와 준의 과거를 가르는 기록",
            "summary":"01:30, 수목구역 단말에서 세나와 준의 근무 대조본이 지워졌다. 어제 둘이 함께 본 바로 그 파일이다."},
        {"id":"inner_door", "title":"안쪽 문 강제 개방", "room":"security", "minute":242, "second":0, "method":"door_override",
            "records":["door","motion","system"], "stake":"보안 구역 안쪽의 보관함",
            "summary":"04:02, 잠겨 있던 보안 구역 안쪽 문이 강제로 열렸다. 손잡이에 아직 온기가 남아 있다."}
    ],
    "ECHO_WARD": [
        {"id":"signal_accept", "title":"반복 신호 수신 승인", "room":"relay", "minute":192, "second":20, "method":"signal_route",
            "records":["comms","terminal","door"], "stake":"수면 중이던 소렌의 목소리가 든 신호",
            "summary":"03:12, 중계실에서 정체불명의 반복 신호가 수신 승인됐다. 신호에는 소렌이 잠들어 있던 시각의 목소리가 섞여 있다."},
        {"id":"segment_erase", "title":"복원 구간 삭제", "room":"archive", "minute":160, "second":0, "method":"data_erase",
            "records":["terminal","comms","system"], "stake":"복원된 신호 구간",
            "summary":"02:40, 기록보관실에서 복원한 신호 구간 하나가 지워졌다. 지워진 건 아직 나누지 않은 대화가 든 구간이다."},
        {"id":"pod_history_lock", "title":"포드 기록 잠금", "room":"medbay", "minute":265, "second":0, "method":"bio_monitor",
            "records":["vitals","door","terminal"], "stake":"소렌 포드의 과거 생체 기록",
            "summary":"04:25, 의료실에서 소렌 포드의 과거 생체 기록 열람 권한이 잠겼다. 그 기록이 신호와 겹치는지 보려던 참이었다."}
    ],
    "SILENT_ORBIT": [
        {"id":"nav_erase", "title":"항법 구간 삭제", "room":"navigation", "minute":629, "second":18, "method":"nav_console",
            "records":["motion","terminal","system"], "stake":"사라진 항로 구간",
            "summary":"10:29, 항법 데이터의 한 구간이 수동으로 지워졌다. 화면은 배가 움직인다고 말하지만 창밖의 별은 며칠째 그대로다."},
        {"id":"beacon_queue", "title":"도착 비콘 재송신 시도", "room":"beacon", "minute":175, "second":0, "method":"signal_route",
            "records":["comms","door","motion"], "stake":"19년 전 도착 완료 신호",
            "summary":"02:55, 비콘 제어실에서 19년 전의 도착 완료 신호가 다시 송신 대기열에 올라갔다. 누가 보내려 했는지는 지워져 있다."},
        {"id":"relay_cut", "title":"관측 중계기 차단", "room":"relay", "minute":210, "second":0, "method":"manual_console",
            "records":["comms","motion","power"], "stake":"별 위치 관측값",
            "summary":"03:30, 관측 중계기가 차단됐다. 창밖 별의 위치를 재던 관측값이 끊겼다."}
    ],
    "RED_SHIFT": [
        {"id":"sample_reclass", "title":"표본 재분류", "room":"garden", "minute":1302, "second":9, "method":"eco_system",
            "records":["environment","terminal","door"], "stake":"출항보다 오래된 목적지 시료",
            "summary":"21:42, 생태 구역 표본 여러 개가 '정착용'으로 재분류됐다. 아직 도착하지 않았다는 배에서, 도착 이후를 위한 분류다."},
        {"id":"history_rewrite", "title":"근무 이력 재작성", "room":"archive", "minute":130, "second":0, "method":"data_erase",
            "records":["terminal","door","system"], "stake":"준과 세나의 근무 이력",
            "summary":"02:10, 기록보관실에서 두 사람의 근무 이력이 다시 쓰였다. 지난 판본에선 오래된 동료였던 두 사람이, 새 판본에선 처음 만난 사이다."},
        {"id":"sample_cooler", "title":"시료 보관고 개방", "room":"medbay", "minute":224, "second":0, "method":"bio_monitor",
            "records":["environment","vitals","door"], "stake":"목적지에서 채집됐다는 시료 두 개",
            "summary":"03:44, 의료실 시료 보관고가 열린 채 발견됐다. 목적지 시료 두 개가 사라졌다."}
    ],
    "LAST_LIGHT": [
        {"id":"power_priority", "title":"전력 우선순위 재배분", "room":"reactor", "minute":357, "second":11, "method":"power_panel",
            "records":["power","system","door"], "stake":"통신·장기수면·항법·생태·기록 중 무엇을 살릴지",
            "summary":"05:57, 심장로에서 전력 우선순위가 손으로 바뀌었다. 기록 보존 장치가 맨 뒤로 밀렸다."},
        {"id":"fragment_delete", "title":"기록 조각 삭제", "room":"archive", "minute":140, "second":0, "method":"data_erase",
            "records":["terminal","system","door"], "stake":"손상된 기록의 다음 줄",
            "summary":"02:20, 기록보관실에서 복구하던 오래된 기록 조각 하나가 지워졌다. 'ARRIVAL COMPLETE' 다음 줄이었다."},
        {"id":"core_lock", "title":"코어실 잠금", "room":"core", "minute":230, "second":0, "method":"door_override",
            "records":["door","power","motion"], "stake":"관측 코어에 남은 가장 오래된 기록",
            "summary":"03:50, 관측 코어가 안쪽에서 잠겼다. 보존 중이던 기록이 전원 차단 대기에 들어갔다."}
    ],
    "SECOND_WATCH": [
        {"id":"duty_shred", "title":"근무 일지 일부 파기", "room":"archive", "minute":611, "second":40, "method":"data_erase",
            "records":["terminal","door","system"], "stake":"도착 이후의 근무 일지",
            "summary":"10:11, 기록보관실에서 도착 이후 근무 일지 몇 장이 파쇄기에 들어갔다. 남은 장의 필체는 지금 우리 손글씨와 같다."},
        {"id":"alarm_forgery", "title":"동시 경보 기록 조작", "room":"security", "minute":150, "second":0, "method":"door_override",
            "records":["door","motion","system"], "stake":"누가 현장에 있었는지 말해 주는 경보 기록",
            "summary":"02:30, 보안허브에서 동시 경보 기록의 대응자 칸이 바뀌었다. 현장에 있던 사람과 위임받은 사람이 뒤섞였다."},
        {"id":"clinic_erase", "title":"진료 기록 삭제", "room":"medbay", "minute":195, "second":0, "method":"bio_monitor",
            "records":["vitals","terminal","door"], "stake":"도착 이후의 진료 기록",
            "summary":"03:15, 의료실에서 도착 이후 진료 기록 한 묶음이 삭제됐다. 미라가 어제 읽던 묶음이다."}
    ],
    "BORROWED_DAYS": [
        {"id":"habit_erase", "title":"습관 기록 삭제", "room":"lounge", "minute":781, "second":22, "method":"data_erase",
            "records":["terminal","environment","door"], "stake":"설명되지 않는 습관 목록",
            "summary":"13:01, 라운지 공용 기록에서 누군가의 습관 목록이 지워졌다. 노아가 어제 적어 둔 목록이다."},
        {"id":"relation_edit", "title":"관계 기록 변조", "room":"medbay", "minute":165, "second":0, "method":"bio_monitor",
            "records":["vitals","terminal","door"], "stake":"두 사람의 관계 기록 원본",
            "summary":"02:45, 의료실 관계 기록 원본에 수정 흔적이 남았다. 누군가 과거 하나를 골라 지우려 했다."},
        {"id":"roster_tear", "title":"근무표 훼손", "room":"garden", "minute":200, "second":0, "method":"eco_system",
            "records":["environment","door","motion"], "stake":"수목구역에 남은 옛 근무표",
            "summary":"03:20, 수목구역에 걸려 있던 옛 근무표가 찢겼다. 두 이름이 나란히 적혀 있던 부분만 없어졌다."}
    ],
    "BLIND_DECK": [
        {"id":"route_erase", "title":"통로 기록 삭제", "room":"service", "minute":901, "second":15, "method":"manual_console",
            "records":["motion","door","system"], "stake":"지도에서 지워진 정비 통로",
            "summary":"15:01, 정비 구역에서 막 복원한 통로 기록이 다시 지워졌다. 복원한 사람만 알던 경로다."},
        {"id":"map_tamper", "title":"지도 갱신 이력 조작", "room":"archive", "minute":125, "second":0, "method":"data_erase",
            "records":["terminal","system","door"], "stake":"통로가 언제 지워졌는지 말해 주는 이력",
            "summary":"02:05, 기록보관실의 지도 갱신 이력에서 하루치가 비어 있다. 통로가 사라진 바로 그날이다."},
        {"id":"coord_lock", "title":"좌표 잠금", "room":"navigation", "minute":215, "second":0, "method":"nav_console",
            "records":["motion","terminal","power"], "stake":"벽 너머로 이어지는 좌표",
            "summary":"03:35, 항법실에서 정비 구역 좌표가 잠겼다. 루칸이 어제 겹쳐 본 좌표다."}
    ],
    "THREE_MINUTES_DARK": [
        {"id":"triple_alarm", "title":"동시 경보 유발", "room":"reactor", "minute":131, "second":8, "method":"power_panel",
            "records":["power","door","system"], "stake":"세 구역에서 동시에 울린 경보",
            "summary":"02:11, 주전력이 흔들린 세 분 동안 동력·통신·보안에서 경보가 겹쳤다. 첫 경보는 심장로에서 손으로 일으킨 것이다."},
        {"id":"delegate_forgery", "title":"위임 판단 기록 변조", "room":"security", "minute":160, "second":0, "method":"door_override",
            "records":["door","terminal","motion"], "stake":"누가 무엇을 직접 봤는지 가르는 기록",
            "summary":"02:40, 보안허브의 위임 판단 기록에서 '직접 확인' 표시 하나가 '전달받음'으로 바뀌었다."},
        {"id":"alarm_mute", "title":"의료 경보 차단", "room":"medbay", "minute":205, "second":0, "method":"bio_monitor",
            "records":["vitals","door","power"], "stake":"수면 포드의 이상 경보",
            "summary":"03:25, 의료실 경보가 음소거됐다. 그 사이 포드 하나의 온도가 기준치를 넘었다."}
    ],
    "CONTINUITY": [
        {"id":"daily_tear", "title":"일상 기록 훼손", "room":"garden", "minute":701, "second":27, "method":"eco_system",
            "records":["environment","terminal","door"], "stake":"도착 이후의 평범한 일과 기록",
            "summary":"11:41, 수목구역에 모아 둔 일상 기록 묶음이 훼손됐다. 재난 기록이 아니라 식사표와 물 주기 표다."},
        {"id":"last_page", "title":"마지막 장 탈취", "room":"archive", "minute":150, "second":0, "method":"data_erase",
            "records":["terminal","door","system"], "stake":"일지 더미의 마지막 장",
            "summary":"02:30, 기록보관실에서 일지 더미의 마지막 장이 사라졌다. 다음 장부터 필체가 바뀌던 그 장이다."},
        {"id":"clinic_order", "title":"진료 순서 기록 삭제", "room":"medbay", "minute":190, "second":0, "method":"bio_monitor",
            "records":["vitals","terminal","environment"], "stake":"도착 이후의 진료 순서표",
            "summary":"03:10, 의료실에서 진료 순서 기록이 삭제됐다. 지금 미라가 쓰는 순서와 똑같았던 기록이다."}
    ],
    "THRESHOLD": [
        {"id":"gap_erase", "title":"공백 구간 경계 삭제", "room":"archive", "minute":1401, "second":19, "method":"data_erase",
            "records":["terminal","system","door"], "stake":"평범한 기록이 멈추는 경계",
            "summary":"23:21, 기록보관실에서 일상 기록이 멈추는 경계 한 줄이 지워졌다. 그 줄 다음이 긴 공백이다."},
        {"id":"resleep_order", "title":"재수면 명령 재입력", "room":"bridge", "minute":142, "second":0, "method":"manual_console",
            "records":["system","door","motion"], "stake":"깨어 있는 전원의 의식",
            "summary":"02:22, 함교 콘솔에 전 승무원 장기수면 재개 명령이 입력됐다. 확정 직전에 멈췄다. 누군가 우리를 다시 재우려 했다."},
        {"id":"core_seal", "title":"관측 기록 봉인", "room":"core", "minute":228, "second":0, "method":"door_override",
            "records":["door","power","motion"], "stake":"가장 오래된 관측 기록",
            "summary":"03:48, 코어실의 가장 오래된 관측 기록이 봉인됐다. 봉인 해제 권한자 칸은 비어 있다."}
    ]
}

static func incident(case_id: String, day: int) -> Dictionary:
    var list: Array = INCIDENTS.get(case_id, INCIDENTS["DEAD_AIR"])
    var index := posmod(day - 1, list.size())
    var data: Dictionary = Dictionary(list[index]).duplicate(true)
    if day > list.size():
        # A rotation repeats the kind of incident, never the same minute.
        data["minute"] = posmod(int(data["minute"]) + 37 * (day - list.size()), 1440)
        data["id"] = "%s_d%d" % [str(data["id"]), day]
        data["summary"] = "또다시 · " + str(data["summary"]).substr(7)
    data["room_name"] = location_name(str(data["room"]))
    data["day"] = day
    return data

static func location_name(room_id: String) -> String:
    return str(LOCATION_NAMES.get(room_id, room_id))

static func method(method_id: String) -> Dictionary:
    return Dictionary(METHODS.get(method_id, METHODS["manual_console"])).duplicate(true)

# ---------------------------------------------------------------- openings
#
# Each opening is a short sequence of scenes played in the first morning of a
# Stage: why this cycle started, who woke, what went wrong, what today asks.
# Speakers are always from the Stage's full roster (everyone is active on the
# first morning). {incident}, {time} and {room} are filled by the session.

const OPENINGS := {
    "CALIBRATION": [
        {"id":"open_cal_1", "art":"medical", "action":"의료실. 네 개의 포드가 열려 있고, 네 개는 아직 닫혀 있다. 방금 깨어난 사람들의 숨소리만 들린다.",
            "lines":[["rho","일어났다! 손 줘, 잡아 줄게. 다리에 힘 안 들어가는 거 정상이야."],
                ["dax","포드 표시등 하나가 꺼져 있어. 전원 문제는 아니야. 전원은 살아 있거든."],
                ["noa","각성 순서만 적을게요. 미라, 준, 다렌, 저, 그리고 탐사요원."]]},
        {"id":"open_cal_2", "art":"medical", "action":"노아가 포드 제어 패널의 기록을 띄운다. 모두의 시선이 한 줄에 멈춘다.",
            "lines":[["noa","{time}. 이 포드의 생명유지 잠금이 수동으로 풀렸어요. 실행자 칸은 비어 있어요."],
                ["dax","원격 해제 이력은 없어. 누군가 이 앞에 서서 직접 풀었다는 뜻이야."],
                ["rho","잠깐. 그 시간에 깨어 있던 건 우리 다섯뿐이잖아."],
                ["mira","…보안 규정에 나오는 말이 있어요. Null. 동료의 얼굴과 목소리 그대로 움직이면서, 기록을 지우고 밤에는 사람을 해치는 무언가요. 겉으로는 절대 구별이 안 돼요."],
                ["dax","그러니까 우리 넷 중 하나가 그거일 수 있다는 거군. …너 포함해서, 미라."],
                ["mira","네. 저도 포함이에요."]]},
        {"id":"open_cal_3", "art":"medical", "action":"미라가 비어 있는 격리 포드 하나를 가리킨다.",
            "lines":[["mira","오늘 저녁 회의가 끝나면 투표로 한 사람을 저 포드에 재워야 해요. 죽이는 게 아니에요. 이 일이 끝날 때까지 잠들어 있는 거예요."],
                ["noa","그 전에 각자 {time}에 어디 있었는지 들어 보세요. 다 듣기엔 시간이 모자라요. 말이 맞지 않는 곳이 있을 거예요."],
                ["rho","다들 서로 말 좀 맞춰 봐야겠네. …나부터 물어봐도 돼."],
                ["mira","거짓말하는 사람이 전부 Null은 아니에요. 사람은 창피해서도 숨기니까요. …누구 말을 먼저 들어 볼래요?"]]}
    ],
    "DEAD_AIR": [
        {"id":"open_dead_1", "art":"medical", "action":"다시 의료실. 다섯 번째 포드가 열린다. 보안 책임자 세나가 몸을 일으키자마자 출입문부터 본다.",
            "speaker_intro":"sena",
            "lines":[["sena","문이 열리는 쪽부터 확인할게. …다들 얼굴이 왜 그래? 무슨 일 있었어?"],
                ["mira","방금 깨어났어요. 천천히요. 무리하면 안 돼요."],
                ["","당신만 알고 있다. 지난번 이 의료실에서 누군가가 포드에 잠겼고, 누군가는 밤을 넘기지 못했다. 지금 그들은 아무렇지 않게 서 있다."],
                ["","ASTRA가 기록을 다시 맞출 때마다 모두가 처음처럼 깨어난다. Null도 다시 깨어난다. 다만 이번에도 같은 얼굴이라는 보장은 없다."]]},
        {"id":"open_dead_2", "art":"bridge", "action":"통신실 경보가 짧게 울린다. 외부 송신 채널이 닫혀 있다.",
            "lines":[["noa","{time}, 외부 송신 채널이 닫혔어요. 절차 순서가 정확해요. 실수로 누른 게 아니에요."],
                ["dax","하나 더 있어. 기록보관실에 목적지가 서로 다른 원본 문서가 두 장이야. 둘 다 진짜 서명이고."],
                ["sena","교신을 끊고, 목적지를 두 개로 만들고. 누가 우리 발을 묶으려는 거네."],
                ["rho","또 그거야? 우리 중 누가…"]]},
        {"id":"open_dead_3", "art":"bridge", "action":"세나가 팔짱을 끼고 사람들을 한 명씩 본다.",
            "lines":[["sena","규정은 알아. 오늘 안에 한 명 격리. 대신 몰아가기는 안 돼. 말을 듣고 정하자."],
                ["mira","세나 말이 맞아요. 누가 어디 있었는지부터 들어요."]]}
    ],
    "GLASS_GARDEN": [
        {"id":"open_glass_1", "art":"medical", "action":"여섯 번째 포드. 통신관 소렌이 눈을 뜨자마자 경보음과 수신음을 따로 줄인다.",
            "speaker_intro":"vale",
            "lines":[["vale","지금 나는 건 경보예요. 누가 말하는 신호랑은 달라요. …다들 제 목소리를 처음 듣는 얼굴이네요."],
                ["noa","처음이에요. 적어 둘게요. 소렌, 통신관."],
                ["","당신은 기억한다. 이 배가 두 개의 목적지를 동시에 품고 있었다는 것을. 다른 사람들에겐 그 기록이 아직 처음이다."]]},
        {"id":"open_glass_2", "art":"garden", "action":"보안 구역 쪽 조명이 꺼져 있다. 세나가 출입 패널을 확인한다.",
            "lines":[["sena","{time}, 잠긴 보안 구역 전력이 수동으로 내려갔어. 내 근무 기록엔 준이랑 여기서 일한 날이 있는데…"],
                ["rho","내 배치 기록엔 그날이 없어. 세나, 난 그 일 진짜 기억 안 나."],
                ["vale","기록 두 개가 서로 다른 소리를 내고 있네요. 둘 다 잡음은 아니에요."],
                ["dax","과거 얘기는 나중에. 지금은 누가 전력을 내렸는지가 먼저야."]]}
    ],
    "ECHO_WARD": [
        {"id":"open_echo_1", "art":"medical", "action":"일곱 번째 포드가 열린다. 항법사 루칸이 난간을 잡고 창과 항로 화면을 번갈아 본다.",
            "speaker_intro":"eli",
            "lines":[["eli","서두르지 마. 화면 시각부터 맞추자. …지금 몇 시야, 진짜로."],
                ["noa","{time}이 지난 지 얼마 안 됐어요."],
                ["","당신은 기억한다. 지난 주기에 안쪽에서 먼저 열렸던 문을. 루칸에게 그건 없었던 일이다."]]},
        {"id":"open_echo_2", "art":"medical", "action":"소렌이 헤드셋을 벗지 못한다. 중계실에서 수신된 신호가 스피커로 흘러나온다.",
            "lines":[["vale","이 목소리… 저예요. 그런데 이 시간에 전 포드 안에 있었어요."],
                ["mira","생체 기록상 소렌은 분명 자고 있었어요. 그 시간 내내요."],
                ["dax","그럼 누가 이 신호를 받아들였는지부터 보자. 수신 승인은 사람 손이 필요해."],
                ["eli","시간이 두 개로 갈라진 것처럼 말하지 마. 하나씩 맞추면 돼."]]}
    ],
    "SILENT_ORBIT": [
        {"id":"open_orbit_1", "art":"medical", "action":"마지막 포드가 열린다. 생태학자 마렌이 물컵을 받아 들고 생태 구역 상태표부터 찾는다. 이제 여덟 명이 모두 깨어 있다.",
            "speaker_intro":"lyra",
            "lines":[["lyra","물은 조금이면 돼요. 시료 보관 상태도 같이 볼까요? …왜들 그렇게 조용해요?"],
                ["sena","깨어나자마자 미안한데, 요즘 이 배는 조용한 날이 없어."],
                ["","여덟 개의 포드가 모두 열렸다. 그리고 ASTRA의 보안 체계가 경고를 띄운다. Null 신호가 두 갈래로 갈라졌다."]]},
        {"id":"open_orbit_2", "art":"bridge", "action":"항법실. 화면 속 항로는 움직이는데 창밖의 별은 며칠째 그대로다.",
            "lines":[["eli","{time}, 항법 구간 하나가 손으로 지워졌어. 지워진 자리 옆에 남은 문장이 하나 있어."],
                ["dax","'ASTRA — 목적지 도착 완료.' 서명은 살아 있어. 날짜는 지금보다 19년 전이야."],
                ["lyra","19년이요? 그럼 우리가 지나온 시간은…"],
                ["mira","지금은 사람부터 봐요. 둘이라면, 오늘 한 명만 찾아서는 끝나지 않아요."]]},
        {"id":"open_orbit_3", "art":"bridge", "action":"ASTRA 보안 체계가 탐사요원에게 추가 권한을 연다.",
            "lines":[["","전문 프로토콜이 열렸다. 오늘부터 하나를 장착할 수 있다. 어떤 프로토콜도 누가 Null인지 알려 주지는 않는다."]]}
    ],
    "RED_SHIFT": [
        {"id":"open_red_1", "art":"garden", "action":"다시 깨어난 아침. 생태 구역의 식물 일부가 이유 없이 시들어 있다.",
            "lines":[["lyra","공기가 한동안 달랐던 것 같아요. 그리고 이 시료들… 목적지에서 채집됐다고 적혀 있어요."],
                ["noa","채집일이 출항일보다 빨라요. 입력 오류는 아니에요. 보관 장치 기록도 같아요."],
                ["","당신은 기억한다. 19년 전의 도착 기록을. 여기 있는 사람들은 오늘 그 말을 처음 듣는다."]]},
        {"id":"open_red_2", "art":"garden", "action":"생태 단말에 '정착용' 분류표가 줄지어 떠 있다.",
            "lines":[["lyra","{time}, 표본들이 '정착용'으로 재분류됐어요. 도착하지도 않았는데 도착 이후 분류라니."],
                ["eli","분류표만 틀렸다고 보긴 어려워. 채집 장비 기록도 같은 날짜를 말하고 있어."],
                ["mira","누군가 오늘 그걸 바꿔 놓았다면, 그 사람은 이 시료가 뭘 말하는지 알고 있는 거예요."]]}
    ],
    "LAST_LIGHT": [
        {"id":"open_last_1", "art":"engine", "action":"전력 계통이 불안정하게 오르내린다. 모든 시스템을 동시에 살릴 수는 없다.",
            "lines":[["rho","전력이 계속 흔들려. 통신, 장기수면, 항법, 생태, 기록 보존. 다 같이 못 살려."],
                ["dax","{time}, 누가 우선순위를 손으로 바꿨어. 기록 보존이 맨 뒤로 밀렸고."],
                ["noa","지금까지 모은 도착 기록들이 전부 그 보존 장치에 있어요."],
                ["","당신은 기억한다. 서로 다른 목적지, 19년 전 도착, 출항보다 오래된 시료. 그 모든 기록이 한곳에서 꺼지려 한다."]]},
        {"id":"open_last_2", "art":"engine", "action":"미라가 사람들 사이에 선다.",
            "lines":[["mira","둘이에요. 두 사람을 찾기 전까지 우리는 계속 무언가를 잃을 거예요. 기록이든, 사람이든."],
                ["sena","그럼 오늘부터 하나씩 확실하게 가자."]]}
    ],
    "SECOND_WATCH": [
        {"id":"open_second_1", "art":"archive", "action":"지난 주기에 지켜 낸 기록 보존 장치 아래에서, 도착 이후 날짜가 찍힌 근무 일지 전체가 나온다.",
            "lines":[["noa","필체가… 낯설지 않아요. 제 약어 쓰는 습관이 그대로예요."],
                ["sena","교대표에 우리 이름이 정상 근무자로 반복돼. 몇 주나."],
                ["","당신은 기억한다. 지난 주기에 끝까지 지켜 낸 기록을. 그 아래에 있던 건 재난이 아니라 생활이었다."]]},
        {"id":"open_second_2", "art":"archive", "action":"파쇄기 입구에 종이 조각이 걸려 있다.",
            "lines":[["noa","{time}, 일지 몇 장이 파쇄기에 들어갔어요. 우리가 막 읽으려던 장들이에요."],
                ["dax","누군가는 우리가 이 시간을 기억해 내는 걸 원치 않는 거야."],
                ["mira","아니면 기억하면 안 되는 이유가 있거나요."]]}
    ],
    "BORROWED_DAYS": [
        {"id":"open_borrowed_1", "art":"lounge", "action":"라운지. 세나가 묻지도 않고 준에게 정확한 공구를 건넨다. 둘 다 그걸 알아차리지 못한다.",
            "lines":[["noa","지금 기록엔 두 분이 이번 항해에서 처음 만났다고 되어 있어요."],
                ["rho","근데 방금… 뭐 달라고 하기도 전에 받았어. 이상하게 놀랍지가 않네."],
                ["","당신은 기억한다. 누군가 기록을 고쳐 쓰던 밤을. 고쳐지지 않은 건 사람들의 손이었다."]]},
        {"id":"open_borrowed_2", "art":"lounge", "action":"라운지 공용 기록 창이 비어 있다.",
            "lines":[["noa","{time}, 제가 적어 둔 습관 목록이 지워졌어요. 누가 누구 컵을 어디 두는지까지 적었던 거예요."],
                ["lyra","그런 걸 왜 지워요? 그건 그냥 사는 모습인데."],
                ["sena","사는 모습이 증거가 되니까 지우는 거겠지."]]}
    ],
    "BLIND_DECK": [
        {"id":"open_blind_1", "art":"breach", "action":"루칸이 옛 지도와 지금 지도를 반투명하게 겹친다. 통로 하나만 사라져 있다.",
            "lines":[["eli","좌표는 벽 뒤로 계속돼. 통로가 없는 게 아니라 지도만 여기서 끝나."],
                ["noa","정비 기록은 안 끊겨요. 지도에서 사라진 뒤에도 점검 서명이 계속 있어요."],
                ["","당신은 기억한다. 몸이 기억하던 습관들을. 그 사람들이 오가던 길이 지금 지도에만 없다."]]},
        {"id":"open_blind_2", "art":"breach", "action":"막 복원한 통로 기록이 다시 비어 있다.",
            "lines":[["eli","{time}, 내가 복원한 통로가 다시 지워졌어. 나 말고 아는 사람이 없던 경로야."],
                ["sena","그럼 루칸이 한 말을 들은 사람이 범위겠네."],
                ["eli","…그렇게 좁혀도 돼. 나까지 포함해서."]]}
    ],
    "THREE_MINUTES_DARK": [
        {"id":"open_dark_1", "art":"engine", "action":"비상등 아래 세 개의 경보가 동시에 떠 있다. 당신은 한 곳만 직접 볼 수 있다.",
            "lines":[["eli","난 동력 쪽 갈게. 내가 직접 보는 것만 확정해서 말할 거야."],
                ["noa","직접 확인, 시스템 기록, 전달받은 판단. 세 가지를 섞지 않을게요."],
                ["vale","전달된 말은 한 번 거칠 때마다 조금씩 달라져요. 원본 음성이 남아 있으면 제가 찾을게요. …누가 먼저 말했는지까지요."],
                ["","당신은 기억한다. 지도 밖의 길을. 이번에는 길이 아니라 판단이 지워지려 한다."]]},
        {"id":"open_dark_2", "art":"engine", "action":"심장로 패널에 손으로 내린 레버가 그대로 남아 있다.",
            "lines":[["rho","{time}, 첫 경보는 누가 손으로 일으켰어. 레버가 이렇게 내려가 있을 리 없어."],
                ["mira","오늘은 누가 무엇을 직접 봤는지가 제일 중요해요. 들은 말과 본 것을 구분해요."]]}
    ],
    "CONTINUITY": [
        {"id":"open_cont_1", "art":"garden", "action":"한 상자 가득한 평범한 기록. 식사 배급표, 진료 순서, 청소 확인, 정원 관리 일지. 전부 도착 이후 날짜다.",
            "lines":[["mira","진료 순서가… 지금이랑 거의 같아요. 급한 사람 먼저, 늦게 온 사람은 기다리고."],
                ["lyra","정원 기록엔 물 양까지 적혀 있어요. 특별한 날이 아니라 계속 이어진 일이에요."],
                ["","당신은 기억한다. 세 줄로 나뉘어 남은 판단들을. 이번 상자에는 판단이 아니라 하루하루가 들어 있다."]]},
        {"id":"open_cont_2", "art":"garden", "action":"기록 묶음 한쪽이 찢겨 있다.",
            "lines":[["lyra","{time}, 누가 이 묶음을 훼손했어요. 재난 기록도 아닌데. 그냥 물 주기 표예요."],
                ["noa","평범한 기록이 제일 많이 겹쳐요. 겹치는 게 싫은 사람이 있나 봐요."]]}
    ],
    "THRESHOLD": [
        {"id":"open_threshold_1", "art":"bridge", "action":"평범한 기록은 어느 날 갑자기 끝난다. 마지막 배급 기록 뒤에는 긴 공백, 그리고 장기수면 재개 명령이 있다.",
            "lines":[["noa","마지막 기록도 평범해요. 식사 배급표 다음이… 이 줄이에요."],
                ["dax","장기수면 재개. 서명 유효, 형식 정상. 사이 공백도 실제야."],
                ["","당신은 기억한다. 열두 번의 깨어남을. 그리고 이제 안다. 우리는 한 번도 안 깬 게 아니라, 살다가 다시 잠든 것이다."]]},
        {"id":"open_threshold_2", "art":"bridge", "action":"기록보관실에서 경계선 한 줄이 비어 있다.",
            "lines":[["noa","{time}, 공백이 시작되는 경계 한 줄이 지워졌어요. 누가 잠을 시작했는지 말해 줄 줄이었어요."],
                ["mira","누가 우리를 재웠는지 알면… 왜 재웠는지도 알 수 있을까요."],
                ["sena","오늘은 그걸 지운 손부터 찾자."]]}
    ]
}

static func opening(case_id: String) -> Array:
    return Array(OPENINGS.get(case_id, [])).duplicate(true)

# ---------------------------------------------------------------- resolutions
#
# Played after the last Null is contained, before the result screen. The ship
# re-synchronises first, so everyone in the Stage roster is present again and
# can speak; only the explorer remembers the cycle. The existing 0.7.x
# RESOLUTION_BEATS (AstraVoyageContent) supply the choice scene in between.

const RESOLUTION_OPEN := {
    "CALIBRATION":"마지막 포드 잠금이 닫히자, ASTRA의 기록이 한 번 깜빡인다. 다시 켜진 의료실에는 네 사람이 모두 서 있다.",
    "DEAD_AIR":"외부 채널이 다시 열린다. 재동기화가 끝난 통신실에는 다섯 사람이 모두 있다.",
    "GLASS_GARDEN":"보안 구역의 조명이 돌아온다. 기록이 다시 맞춰지고, 여섯 사람이 문 앞에 모인다.",
    "ECHO_WARD":"반복 신호가 멈춘다. 재동기화 뒤 중계실에는 일곱 사람의 숨소리만 남는다.",
    "SILENT_ORBIT":"두 번째 포드가 잠긴다. 항법 화면이 한 번 꺼졌다 켜지고, 여덟 사람이 모두 창가에 서 있다.",
    "RED_SHIFT":"생태 구역의 공기 순환이 다시 돈다. 재동기화가 끝나자 여덟 사람이 시료대 앞에 모인다.",
    "LAST_LIGHT":"전력 계통이 안정된다. 기록 보존 장치에 불이 들어오고, 여덟 사람이 코어 앞에 선다.",
    "SECOND_WATCH":"파쇄기가 멈춘다. 재동기화 뒤 기록보관실에는 여덟 사람과 남은 근무 일지가 있다.",
    "BORROWED_DAYS":"라운지 조명이 평소 밝기로 돌아온다. 여덟 사람이 각자 늘 앉던 자리에 앉는다.",
    "BLIND_DECK":"지워졌던 통로가 지도에 다시 그려진다. 여덟 사람이 그 앞에 모인다.",
    "THREE_MINUTES_DARK":"비상등이 정상색으로 돌아온다. 세 줄의 기록이 서로 다른 표식을 단 채 남는다.",
    "CONTINUITY":"찢긴 묶음이 다시 붙는다. 여덟 사람이 평범한 기록 앞에 둘러앉는다.",
    "THRESHOLD":"재수면 명령이 취소된다. 함교의 긴 공백 앞에 여덟 사람이 깨어 있다."
}

# Extra authored beats after the choice scene: what the local answer means to
# the people, and the larger question it leaves. Two to four lines each.
const RESOLUTION_AFTER := {
    "CALIBRATION":[["noa","실행자 칸은 여전히 비어 있어요. 그런데 이 날짜, 하루 전이에요. 제가 방금 적은 날짜랑 달라요."],
        ["mira","괜찮아요? …당신, 방금 우리를 처음 보는 얼굴이 아니었어요."],
        ["dax","전원 문제는 아니었어. 사람 손이었지. 그런데 그 손이 누구였는지는 기록이 기억하지 못해."]],
    "DEAD_AIR":[["sena","목적지가 두 개인 배라니. 경비 교대표도 이렇게 꼬이진 않아."],
        ["mira","전 지구 귀환을 기억해요. 그 기억이 틀렸다는 서류는 없어요. 맞다는 서류도 두 장이고요."],
        ["noa","통신이 잠깐 열렸을 때 들어온 문장이 있어요. 탐사요원 목소리예요. 아직 하지 않은 말이요."]],
    "GLASS_GARDEN":[["rho","세나. 그날 기억 안 나는 거, 미안해. 근데 네가 틀렸다고 생각하진 않아."],
        ["sena","됐어. 기억 하나 지워서 맞출 일은 아니잖아."],
        ["vale","문 안쪽 손잡이, 아직 따뜻했어요. 이 배엔 우리가 모르는 시간이 하나 더 흐르고 있어요."]],
    "ECHO_WARD":[["vale","적어도 이제 어디까지가 제 목소리인지는 알아요. …아직 하지 않은 말까지 제 목소리였어요."],
        ["eli","시간이 갈라진 게 아니라면, 누군가 순서를 바꿔 놓은 거야."],
        ["dax","항법 기록 쪽에서도 비슷한 게 보여. 다음은 루칸 쪽이겠네."]],
    "SILENT_ORBIT":[["eli","창밖 별이 안 움직이는 이유가 이제야 맞아. 우린 이미 도착해 있었어."],
        ["lyra","19년이면… 씨앗이 세 번은 세대를 바꿨을 시간이에요."],
        ["mira","그런데 우리 몸은 그 시간을 지나지 않았어요. 제가 매일 확인하는 수치가 그래요."]],
    "RED_SHIFT":[["lyra","이 시료는 그 시간을 실제로 지나왔어요. 우리가 기억 못 한다고 없어지는 건 아니죠."],
        ["sena","준이랑 내가 처음 만난 사이라는 기록. 그것도 진짜 서명이야. 그러니까 더 이상한 거지."],
        ["noa","라벨의 필체… 탐사요원 거예요. 저는 그 습관을 알아요."]],
    "LAST_LIGHT":[["noa","서로 다른 사본이 딱 한 문장만 같아요. '도착 완료.'"],
        ["dax","Null 사건만으로는 이 모순이 설명 안 돼. 이건 더 오래된 문제야."],
        ["rho","…농담이 하나도 안 나오더라. 그게 제일 무서웠어. 다들 알지? 나 원래 이런 거 잘 못 버텨."],
        ["mira","그래도 오늘은 아무것도 버리지 않았어요. 기록도, 사람도."]],
    "SECOND_WATCH":[["sena","우리가 잃은 건 사건 하나가 아니라, 근무하던 시간 전체네."],
        ["noa","이게 몇 주나 반복돼요. 사고 직전의 하루가 아니라… 생활이었어요."],
        ["noa","…기록은 거짓말을 안 한다고 적어 왔어요. 그런데 맥락 없는 기록도 진실의 절반밖에 안 되네요. 그것도 적어 둘게요."],
        ["mira","살았던 시간을 기억 못 하는 게, 이렇게 아플 줄은 몰랐어요."]],
    "BORROWED_DAYS":[["rho","우리… 원래 이랬어? 세나가 뭘 건넬지 난 알고 있었어."],
        ["sena","나도 몰라. 근데 몸은 확신하더라."],
        ["sena","…나 원래 다 혼자 막으려고 했잖아. 오늘은 너희한테 맡겼어. 이상하게, 그게 덜 무서웠어."],
        ["noa","기록은 하나를 고르는데, 몸은 둘 다 기억해요."]],
    "BLIND_DECK":[["eli","막아 둔 길이 아니라, 한동안 계속 다니던 길이었어."],
        ["noa","그 안에 있던 건 재난 흔적이 아니라 누가 머물던 흔적이에요."],
        ["dax","누가 왜 지도에서 지웠는지는 아직이야. 하지만 지운 날짜는 찾았어."]],
    "THREE_MINUTES_DARK":[["noa","직접 본 것, 기록, 전해 들은 것. 무게가 다르다는 걸 이제 다들 알아요."],
        ["eli","틀렸다는 게 아니야. 알고 싶어서 물어본 거지."],
        ["mira","오늘 우리가 서로 믿은 건, 근거를 말해 줬기 때문이에요."]],
    "CONTINUITY":[["lyra","이건 버티던 흔적보다… 그냥 살던 흔적에 가까워요."],
        ["mira","누가 살았는지 증명하는 게 재난 기록뿐일 필요는 없네요."],
        ["noa","다음 장부터 필체가 바뀌어요. 그 다음이… 공백이에요."]],
    "THRESHOLD":[["noa","우리는 한 번도 안 깬 게 아니에요. 깨어서 살았고, 그다음에 다시 잠들었어요."],
        ["dax","왜 다시 잠들었는지는 여기 없어. 그 빈칸은 아직 답이 아니야."],
        ["mira","…그래도 이번엔 다 같이 깨어 있어요. 그건 기록이 아니라 지금이에요."]]
}

static func resolution_open(case_id: String) -> String:
    return str(RESOLUTION_OPEN.get(case_id, RESOLUTION_OPEN["DEAD_AIR"]))

static func resolution_after(case_id: String) -> Array:
    return Array(RESOLUTION_AFTER.get(case_id, [])).duplicate(true)

# CALIBRATION had no 0.7.x resolution choice (its first-panel choice lived in
# the removed exploration). This is its local answer in the same format.
const CALIBRATION_RESOLUTION := {
    "payoff_type":"FACTUAL", "participants":["noa","dax"],
    "action":"노아가 포드 잠금 기록의 원본과 사본을 나란히 띄운다. 다렌은 실행자 칸만 확대한다.",
    "lines":[["noa","원본에도 사본에도 실행자 칸은 비어 있어요. 지운 흔적이 아니라, 처음부터 비어 있었어요."],
        ["dax","그럼 잠금을 푼 손은 있었는데, 그 손을 기록할 권한이 없었다는 거야. 이상하지."]],
    "choices":[
        {"label":"두 기록을 함께 보존한다.","effect":"record","memory_tag":"calibration_keep_both"},
        {"label":"네 사람이 모두 이 공백을 보게 한다.","effect":"share","memory_tag":"calibration_share_blank"},
        {"label":"날짜가 어긋난 노아의 메모를 따로 보관한다.","effect":"keep_copy","memory_tag":"calibration_keep_date"}
    ]
}

# ---------------------------------------------------------------- failure

const FAILURE := {
    "player_killed": {
        "title":"재구성 실패 · 신호 두절",
        "action":"복도 조명이 꺼진다. 누군가의 발소리가 선실 앞에서 멈춘다. 당신의 생체 신호가 끊긴다.",
        "lines":[["","…"],["","다시 눈을 뜬다. 같은 의료실. 같은 포드. 같은 목소리가 괜찮냐고 묻는다."],
            ["","당신만 기억한다. 누가 무엇을 말했는지, 그리고 누가 당신을 노렸는지. 하지만 이번 주기의 Null이 같은 사람이라는 보장은 없다."]]
    },
    "null_control": {
        "title":"재구성 실패 · 표에서 밀렸다",
        "action":"회의실에 남은 사람의 수가 맞지 않는다. 포드 격리 절차가 거꾸로 돌아가기 시작한다.",
        "lines":[["","깨어 있는 사람 중 Null 쪽 표가 나머지와 같아졌다. 이제 누구도 포드로 보낼 수 없다."],
            ["","기록이 흔들린다. 다시 눈을 뜬다. 같은 의료실, 같은 아침."],
            ["","당신만 기억한다. 이번에는 누구의 말을 더 오래 들어야 했는지."]]
    }
}

# From Stage 9 the ship itself is part of the mystery: a lost reconstruction
# does not come back cleanly (§31 of the campaign brief). Same rules, a
# heavier scene; never a hint about the next reconstruction's Nulls.
const FAILURE_LATE := {
    "player_killed": {
        "title":"재구성 실패 · 균열",
        "action":"선실 문이 열린다. ASTRA의 안내 음성이 한 박자 늦게 따라온다. 탐사요원 생체 신호 소실.",
        "lines":[["","…"],
            ["","어둠 속에서 기록이 넘어가는 소리가 들린다. 당신이 알던 순서가 아니다. 같은 날짜가 두 번 지나간다."],
            ["","다시 눈을 뜬다. 같은 의료실. 그런데 벽시계가 몇 초 늦다. 전에는 이러지 않았다."],
            ["","당신만 기억한다. 누가 무엇을 말했는지, 그리고 이번 재구성이 어디서 무너졌는지. 다음 주기의 Null이 같은 사람이라는 보장은 없다."]]
    },
    "null_control": {
        "title":"재구성 실패 · 균열",
        "action":"마지막 투표가 끝나기도 전에 회의실 조명이 흔들린다. ASTRA가 재동기화를 강제로 시작한다.",
        "lines":[["","깨어 있는 사람 중 Null 쪽 표가 나머지와 같아졌다. 포드 격리 절차가 거꾸로 돌아간다."],
            ["","기록이 겹친다. 두 개의 아침이 같은 시각에 시작된다."],
            ["","다시 눈을 뜬다. 같은 의료실. 당신만 기억한다. 이번에는 누구의 말을 더 오래 들어야 했는지."]]
    }
}

static func failure(reason: String, stage: int = 1) -> Dictionary:
    if stage >= 9 and FAILURE_LATE.has(reason):
        return Dictionary(FAILURE_LATE[reason]).duplicate(true)
    return Dictionary(FAILURE.get(reason, FAILURE["null_control"])).duplicate(true)

# The re-sync after a cleared Stage, told a little differently each time
# (§21): the dead and the isolated come back and remember nothing; only the
# explorer does. {lost} / {iso} are names; lines without them are skipped when
# nobody was lost or isolated.
const RESYNC_LOST := [
    "방금까지 신호가 끊겨 있던 {lost}|i 아무렇지 않게 서 있다. 그 밤을 기억하는 건 당신뿐이다.",
    "눈을 뜨자 {lost}|i 벌써 컵을 들고 있다. 어젯밤을 기억하는 건 당신뿐이다.",
    "{lost}|i 당신에게 잘 잤냐고 묻는다. 대답을 고르는 데 시간이 걸린다.",
    "{lost}|i 복도 끝에서 걸어온다. 걸음은 평소와 같다. 그 복도에서 무슨 일이 있었는지는 당신만 안다.",
    "벽시계가 몇 초 어긋나 있다. {lost}|i 그 시계를 올려다보다가 어깨를 으쓱한다."
]
const RESYNC_ISOLATED := [
    "포드에서 나온 {iso}|i 기지개를 켠다. 자신이 왜 거기 있었는지는 기억하지 못한다.",
    "{iso}|i 포드 덮개를 밀고 나오며 하품을 한다. 누가 자신을 보냈는지 묻지 않는다. 기억이 없으니까.",
    "{iso}|i 당신을 보고 가볍게 손을 든다. 당신은 그 손을 어제와 다르게 본다."
]
const RESYNC_QUIET := [
    "재동기화가 끝난다. 모두가 같은 아침에서 다시 시작한다. 달라진 건 당신의 기억뿐이다.",
    "같은 의료실, 같은 조명. 누군가 커피 이야기를 한다. 당신만 조금 늦게 웃는다.",
    "ASTRA가 재동기화 완료를 알린다. 이번에는 아무도 잃지 않았다. 그래도 기록 한 줄이 어긋나 있다."
]

static func resync_line(pool: Array, stage: int) -> String:
    if pool.is_empty():
        return ""
    return str(pool[posmod(stage * 7 + 3, pool.size())])

# Residual Echo (§16-19, §23): after a re-sync nobody remembers what happened,
# but a little of how it felt stays — a hesitation, an unexplained ease or
# wariness around the explorer. At most one per Stage, never a fact, never a
# role. Keys: fell (lost at night last Stage), sent_by_you (an innocent the
# explorer voted into a pod), shielded (Aegis turned an attack away from
# them), defended (the explorer stood up for them).
const ECHO_LINES := {
    "fell": {
        "mira": ["미라가 의료실 문 앞에서 잠깐 멈춘다. 손이 문틀을 짚는다.", "…아니에요. 그냥, 여기가 조금 추운 것 같아서요."],
        "rho": ["준이 기관실 복도 한가운데서 걸음을 멈추고 뒤를 돌아본다.", "뭐지. 방금 누가 부른 줄 알았는데."],
        "dax": ["다렌이 자기 선실 문 잠금을 두 번 확인한다. 평소엔 한 번이면 끝나는 일이다.", "습관이 하나 늘었네. 언제부터였는지 모르겠어."],
        "noa": ["노아가 메모 첫 장을 넘기다 멈춘다. 빈 줄 하나를 한참 본다.", "여기에 뭔가 적었던 것 같은데… 아니에요. 원래 비어 있었어요."],
        "sena": ["세나가 순찰 경로를 평소와 반대로 돈다. 스스로도 이유를 설명하지 못한다.", "그냥. 오늘은 이쪽이 싫어."],
        "vale": ["소렌이 헤드셋을 벗었다가 다시 쓴다. 조용한 게 싫은 얼굴이다.", "…너무 조용하면, 뭔가 끊긴 것 같아서요."],
        "eli": ["루칸이 복도 시계를 자기 시계와 맞춰 본다. 세 번째다.", "맞아. 맞는데. …이상하게 늦은 느낌이야."],
        "lyra": ["마렌이 시든 잎 하나를 오래 들여다본다.", "이 아이, 어제까지 멀쩡했던 것 같은데요. …어제가 언제였더라."]
    },
    "sent_by_you": {
        "mira": ["미라가 당신과 눈이 마주치자 반 박자 늦게 웃는다.", "…미안해요. 처음 보는 얼굴이 아닌 것 같아서, 조금 긴장했나 봐요."],
        "rho": ["준이 당신에게 손을 내밀다 멈칫한다.", "어, 아니 그냥. 너랑은 왠지 말을 조심해야 할 것 같은 기분? 이상하지."],
        "dax": ["다렌이 당신 쪽으로 반 걸음 떨어져 선다.", "근거 없는 경계야. 알아. 그래도 오늘은 거리를 좀 둘게."],
        "noa": ["노아가 당신 이름을 적다가 펜을 멈춘다.", "…왜인지 모르겠어요. 이 이름 옆에 물음표를 적고 싶어요."],
        "sena": ["세나가 당신을 위아래로 훑어본다. 평소보다 오래.", "처음 보는데 왜 이렇게 신경이 쓰이지. 기분 나쁜 뜻은 아니야. …아마."],
        "vale": ["소렌이 당신 목소리가 들리자 이어폰을 귀에서 뗀다.", "…이상해요. 당신 목소리가 들리면 몸이 먼저 굳어요."],
        "eli": ["루칸이 당신과 출입구 사이에 선다. 의식한 것 같지는 않다.", "습관이야. 신경 쓰지 마."],
        "lyra": ["마렌이 당신에게 물을 건네다 잔을 한 번 더 닦는다.", "어머, 제가 왜 이러죠. 긴장할 일이 없는데."]
    },
    "shielded": {
        "mira": ["미라가 당신 옆자리를 자연스럽게 비워 둔다.", "이상하죠. 당신이 근처에 있으면 숨이 좀 편해요."],
        "rho": ["준이 당신 어깨를 툭 친다. 처음 만난 사람한테 하는 동작이 아니다.", "왠지 너 있으면 든든하다? 이유는 묻지 마. 나도 몰라."],
        "dax": ["다렌이 선실 잠금 확인을 건너뛴다. 당신이 보는 앞에서.", "…오늘은 그냥 괜찮을 것 같아. 계산은 안 되지만."],
        "noa": ["노아가 당신 이름 옆에 작은 점 하나를 찍는다.", "안심이라는 뜻이에요. 왜인지는… 적지 않을게요."],
        "sena": ["세나가 순찰 중에 당신 선실 앞을 한 번 더 지나간다.", "빚진 기분이야. 뭘 빚졌는지는 모르겠는데."],
        "vale": ["소렌이 당신에게만 헤드셋 한쪽을 건넨다.", "같이 들어요. …이상하게 그러고 싶었어요."],
        "eli": ["루칸이 당신 걸음에 맞춰 속도를 줄인다.", "너랑 걸으면 동선 계산이 편해. 그뿐이야."],
        "lyra": ["마렌이 새로 난 잎을 당신에게 먼저 보여 준다.", "당신한테 제일 먼저 보여 주고 싶었어요. 왜인지는 저도 몰라요."]
    },
    "defended": {
        "mira": ["미라가 당신에게 물을 먼저 건넨다.", "처음 보는 사이 같지 않네요. …좋은 뜻으로요."],
        "rho": ["준이 당신에게 공구 하나를 맡긴다. 아무렇지 않게.", "너라면 잃어버리지 않을 것 같아서. 감이야."],
        "dax": ["다렌이 당신 의견을 먼저 묻는다. 평소 순서가 아니다.", "네 판단부터 듣고 싶어. 이유는 설명 못 해."],
        "noa": ["노아가 자기 메모를 당신 쪽으로 돌려 놓는다.", "보셔도 돼요. …보통은 안 보여 주는데."],
        "sena": ["세나가 당신 뒤가 아니라 옆에 선다.", "등 뒤는 맡겨도 될 것 같아서. 됐지?"],
        "vale": ["소렌이 당신에게 먼저 말을 건다. 드문 일이다.", "…당신한테는 먼저 말해도 될 것 같았어요."],
        "eli": ["루칸이 당신에게 자기 시계를 보여 준다.", "기준 시각이야. 너도 이걸로 맞춰."],
        "lyra": ["마렌이 당신 자리에 작은 화분 하나를 놓아 둔다.", "거기 두면 잘 자랄 것 같았어요."]
    }
}

static func echo_line(tag: String, npc_id: String) -> Array:
    return Array(ECHO_LINES.get(tag, {}).get(npc_id, [])).duplicate()

# ---------------------------------------------------------------- mornings

# One line of ship mood for the second and later mornings, by Stage. Keeps the
# Stage's mystery present while the Day's incident takes the foreground.
const MORNING_MOOD := {
    "CALIBRATION":"의료실 포드 네 개가 여전히 닫혀 있다. 누구의 기록도 아직 믿을 수 없다.",
    "DEAD_AIR":"두 장의 목적지 문서가 아직 나란히 놓여 있다. 외부 채널은 조용하다.",
    "GLASS_GARDEN":"보안 구역 쪽 복도가 어둡다. 맞지 않는 두 근무 기록이 단말에 나란히 남아 있다.",
    "ECHO_WARD":"중계실 스피커가 가끔 한 박자씩 늦게 운다. 헤드셋에서는 아직 잡음이 새어 나온다.",
    "SILENT_ORBIT":"창밖의 별은 오늘도 그대로다. 항로 화면만 움직인다.",
    "RED_SHIFT":"생태 구역의 잎이 조금 더 시들었다. 급수량을 고친 메모가 화분 옆에 붙어 있다.",
    "LAST_LIGHT":"전력 계통이 낮게 운다. 기록 보존 장치의 표시등이 불안하게 깜빡인다.",
    "SECOND_WATCH":"근무 일지 더미가 반쯤 줄었다. 남은 장의 필체가 낯익다.",
    "BORROWED_DAYS":"라운지 컵 두 개가 늘 같은 자리에 놓여 있다. 아무도 치우지 않는다.",
    "BLIND_DECK":"지도에서 끊긴 통로 앞 바닥에 닳은 자국이 선명하다.",
    "THREE_MINUTES_DARK":"비상등이 가끔 깜빡인다. 사람들은 들은 말과 본 것을 구분해 말하기 시작했다.",
    "CONTINUITY":"식사표 옆의 컵 자국이 오늘도 그대로다. 평범함이 오히려 무겁다.",
    "THRESHOLD":"함교의 긴 공백 표시가 꺼지지 않는다. 누군가 우리를 다시 재우려 했다."
}

static func morning_mood(case_id: String) -> String:
    return str(MORNING_MOOD.get(case_id, ""))

# Small human scenes for later mornings (§24-§26): someone who was suspected
# yesterday, someone whose vote sent an innocent to a pod, or just a habit.
# No evidence in any of them. At most one per morning; each person's
# conditional scene once per Stage, a habit scene once per Stage.
const VIGNETTES := {
    "suspected": {
        "mira": ["미라가 의료 단말 앞에서 같은 페이지를 세 번째 넘긴다.", "…괜찮아요. 어제 일로 기분 상한 거 아니에요. 확인할 게 많아서 그래요."],
        "rho": ["준이 공구함을 쾅 닫았다가, 스스로 놀란 얼굴을 한다.", "아, 미안. 어제 그 소리 들은 뒤로 손이 좀 거칠어졌나 봐."],
        "dax": ["다렌이 화이트보드에 자기 이름을 적고, 그 옆에 물음표를 그린다.", "나를 변수에서 빼 달라는 게 아니야. 똑같이 계산하라는 거지."],
        "noa": ["노아가 어제 자기 발언을 메모에서 찾는다. 줄을 긋지 않고 그대로 둔다.", "지우지 않을 거예요. 의심받은 날도 기록이에요."],
        "sena": ["세나가 순찰을 한 바퀴 더 돈다. 누가 보라는 듯이.", "숨을 거 없으니까. 볼 테면 봐."],
        "vale": ["소렌이 헤드셋을 벗고, 한참 동안 아무것도 듣지 않는다.", "…어제는 모두의 목소리가 저를 향해 있었어요. 오늘은 조금 조용했으면 해요."],
        "eli": ["루칸이 어제의 자기 동선을 종이에 다시 그린다. 선이 흔들리지 않는다.", "증명할 수 있는 건 증명해 둘게. 필요하면 가져가."],
        "lyra": ["마렌이 어제 자기를 지목한 사람 자리에도 물 한 잔을 놓아 둔다.", "원망 안 해요. 다들 무서웠잖아요."]
    },
    "voted_wrong": {
        "mira": ["미라가 포드 격리 기록 앞에 오래 서 있다.", "어제 제 표도 거기 있었어요. …잊지 않을게요."],
        "rho": ["준이 평소보다 말이 적다. 농담이 한 번도 나오지 않는다.", "내가 너무 빨랐어. 또 그랬어."],
        "dax": ["다렌이 어제 계산을 처음부터 다시 적는다.", "틀린 변수를 찾을 때까지 다시 할 거야. 이번엔 사람을 변수로 두지 않고."],
        "noa": ["노아가 어제 투표 기록 옆에 작은 글씨로 무언가를 적는다.", "‘기록만 믿었다.’ …다음엔 사람도 볼게요."],
        "sena": ["세나가 포드 앞을 지나가다 걸음을 멈춘다. 손을 들었다가 내린다.", "지키겠다고 해 놓고 내가 보냈네. 됐어, 오늘 만회해."],
        "vale": ["소렌이 녹음 하나를 반복해서 듣는다. 어제 투표 직전의 녹음이다.", "…너무 늦게 말했어요. 이번에도요."],
        "eli": ["루칸이 시계를 보다가 짧게 숨을 내쉰다.", "물리적으로는 맞았는데. 사람이 틀렸어. 내가."],
        "lyra": ["마렌이 포드실 앞 화분을 옮겨 놓는다. 잠든 사람이 보이는 자리로.", "깨어나면 제일 먼저 보이라고요. 사과는 그때 할게요."]
    },
    "habit": {
        "mira": ["미라가 누군가의 손목 붕대를 아무 말 없이 다시 감아 준다.", "꽉 조이면 말해요. 참지 말고요."],
        "rho": ["준이 흔들리던 컵 받침대를 고치고 있다. 아무도 부탁하지 않았다.", "이거 흔들리는 거 계속 신경 쓰였거든. 이제 됐다."],
        "dax": ["다렌이 자판기 오류 코드를 해석해서 종이에 붙여 둔다.", "원인은 단순해. 사람들이 설명을 안 읽을 뿐이지."],
        "noa": ["노아가 메모에 쓴 문장 하나를 지웠다가, 다시 쓴다.", "…맞는 문장인데, 쓰고 나니까 차가워 보여서요."],
        "sena": ["세나가 라운지 의자 배치를 바꾼다. 모든 자리가 문을 볼 수 있게.", "습관이야. 신경 쓰지 마."],
        "vale": ["소렌이 통신 잡음을 듣다가 손을 멈춘다.", "…방금 누가 제 이름을 부른 것 같았어요. 잡음이겠죠."],
        "eli": ["루칸이 같은 좌표를 세 번째로 확인한다.", "두 번 맞으면 우연, 세 번 맞으면 기준이야."],
        "lyra": ["마렌이 새잎을 들여다보다 고개를 갸웃한다.", "이 잎, 지난번이랑 다르게 났어요. 반대쪽으로요. …기분 탓일까요."]
    }
}

static func vignette(kind: String, npc_id: String) -> Array:
    return Array(VIGNETTES.get(kind, {}).get(npc_id, [])).duplicate()

# ---------------------------------------------------------------- finale

# After the last Stage is cleared (§32-§36 of the campaign brief): one human
# decision about the unsigned re-sleep order, an epilogue in the tone that
# decision sets (TRUST / FRACTURE / DISCOVERY), a few callbacks to what the
# explorer actually did across the campaign, ASTRA's last message, credits.
# One strong answer (we arrived, lived, and were put back to sleep) and one
# question left open (who was awake after everyone slept).
const FINALE_CHOICE := {
    "id": "finale_choice", "art": "bridge",
    "action": "함교 화면에 재수면 명령이 떠 있다. 서명 칸은 비어 있다. 실행 대기 · 전원.",
    "lines": [["noa", "명령은 아직 대기 중이에요. 누군가 확인만 누르면, 우리는 또 잠들어요."],
        ["dax", "지울 수도 있어. 하지만 지우면, 왜 이 명령이 있었는지도 같이 사라져."],
        ["mira", "…탐사요원님이 정해요. 당신만 전부 기억하니까."]],
    "choices": [
        {"label": "명령과 기록을 모두에게 보여 준다", "effect": "finale:share"},
        {"label": "명령을 지우고, 깨어 있기로 한다", "effect": "finale:wake"},
        {"label": "명령은 봉인하고 기록만 남긴다", "effect": "finale:keep"}
    ]
}

const EPILOGUES := {
    "TRUST": {"id": "epilogue_trust", "art": "lounge",
        "action": "라운지. 여덟 명이 한 화면 앞에 모여 있다. 명령과 기록이 그대로 떠 있다.",
        "lines": [["sena", "숨길 거 없으면 다 같이 보는 거야. 문 잠그는 것보다 이게 낫네."],
            ["rho", "…그러니까 우리가 도착해서 살았고, 누가 다시 재웠다는 거지. 좋아. 이번엔 같이 깨어 있자."],
            ["noa", "기록은 제가 지킬게요. 이번엔 모두가 읽을 수 있게요."],
            ["", "아무도 명령의 주인을 모른다. 그래도 오늘은, 누구도 혼자 그 화면을 보지 않는다."]]},
    "FRACTURE": {"id": "epilogue_fracture", "art": "bridge", "dark": true,
        "action": "명령이 지워진다. 함교 조명이 한 번 깜빡이고, 다시 켜진다.",
        "lines": [["dax", "지웠어. 이제 되돌릴 수 없어. 이유도 같이 지워졌을 수 있고."],
            ["eli", "항로는 그대로야. 우리가 멈춘 거지, 배가 멈춘 게 아니야."],
            ["mira", "…괜찮아요. 깨어 있기로 한 건 우리니까. 무서운 건 같이 무서워해요."],
            ["", "당신은 안다. 몇 번의 재구성 동안 누구를 잃고 누구를 잘못 보냈는지. 그들은 모른다. 그 무게는 당신 몫이다."]]},
    "DISCOVERY": {"id": "epilogue_discovery", "art": "archive",
        "action": "기록보관실. 명령은 봉인되고, 사본 한 부가 노아의 메모 옆에 놓인다.",
        "lines": [["noa", "원본은 봉인, 사본은 여기. 누가 이 명령을 입력했는지 알게 되면, 그때 열어요."],
            ["vale", "…명령 신호, 한 번만 더 들어 볼게요. 이상한 게 있어요. 입력 시각이 우리가 모두 잠든 뒤예요."],
            ["lyra", "그동안 물은 제가 줄게요. 기다리는 동안에도 자라는 건 있으니까요."],
            ["", "답 하나는 손에 쥐었다. 우리는 도착했고, 살았고, 다시 잠들었다. 남은 질문도 하나다. 모두가 잠든 뒤, 누가 깨어 있었나."]]}
}

const FINALE_TONE := {"share": "TRUST", "wake": "FRACTURE", "keep": "DISCOVERY"}

# What each person says at the end about what the explorer did for or to them
# across the campaign. They do not remember it; it stays as feeling (echo).
const FINALE_CALLBACKS := {
    "defended": {
        "mira": "이상하죠. 당신이 제 편에 서 줬던 날들이 기억나는 것 같아요. 그럴 리 없는데.",
        "rho": "너한테 빚진 기분이야. 언제 빚졌는지는 모르겠는데, 꽤 여러 번인 것 같아.",
        "dax": "계산에 없는 신뢰가 하나 있어. 너한테. 근거는 못 대겠어.",
        "noa": "당신 이름 옆에 ‘믿을 수 있음’이라고 적혀 있어요. 제 필체예요. 언제 적었는지 모르겠어요.",
        "sena": "등 뒤를 맡겨도 될 것 같은 사람이 있다는 거. 처음 보는 얼굴인데도.",
        "vale": "…당신 목소리가 들리면 안심이 돼요. 이유는 저도 몰라요.",
        "eli": "너는 기준 시각 같아. 흔들려도 돌아갈 데가 있다는 거.",
        "lyra": "당신이 옆에 있으면 잎이 잘 자라요. 진짜예요."},
    "sent_wrong": {
        "mira": "…당신을 보면 가끔 이유 없이 숨이 멎어요. 괜찮아요. 오늘은 그게 무섭지 않아요.",
        "rho": "가끔 너랑 눈 마주치면 발이 무거워져. 신경 쓰지 마. 이제 괜찮아.",
        "dax": "설명 안 되는 경계심이 하나 남아 있어. 너한테. 지울게. 오늘부터.",
        "noa": "당신 이름 옆 물음표를 오늘 지웠어요. 왜 있었는지는 모르겠지만요.",
        "sena": "너 처음 봤을 때 괜히 날이 섰었어. 이제 알겠어. 그럴 필요 없었다는 거.",
        "vale": "…당신 목소리에 몸이 굳던 게 오늘은 안 그래요. 다행이에요.",
        "eli": "너랑 출입구 사이에 서던 버릇, 오늘은 안 했어. 알아챘어?",
        "lyra": "잔을 두 번 닦던 버릇이요. 오늘은 한 번만 닦았어요."},
    "saved": {
        "mira": "…고마워요. 뭐가 고마운지는 모르겠지만요. 그냥 그 말을 하고 싶었어요.",
        "rho": "야, 고맙다. 뭐가인지는 묻지 마. 그냥 그래야 할 것 같아.",
        "dax": "고맙다는 말을 할 근거가 없는데, 해야 할 것 같아. 고마워.",
        "noa": "‘고마움’이라고 적어 둘게요. 대상은… 당신이에요.",
        "sena": "밤에 문 앞이 조용했던 날들. 그게 네 덕인 것 같아.",
        "vale": "…어젯밤들이 조용했던 거, 당신 덕분인 거 알아요. 어떻게 아는지는 몰라도요.",
        "eli": "동선상 내가 여기 서 있는 게 네 덕이야. 계산은 끝났어.",
        "lyra": "누가 지켜 줬다는 느낌이 이렇게 따뜻한 줄 몰랐어요."}
}

const FINALE_ASTRA := {"id": "finale_astra", "art": "bridge", "dark": true, "action": "ASTRA 상태 표시",
    "lines": [["", "ASTRA · 재구성 완료. 승무원 여덟 명 · 각성 유지."],
        ["", "ASTRA · 기억 보존 대상 · 1명 · 유지."],
        ["", "…당신은 그 한 줄을 오래 본다."]]}

static func finale_callback(kind: String, npc_id: String) -> String:
    return str(Dictionary(FINALE_CALLBACKS.get(kind, {})).get(npc_id, ""))
