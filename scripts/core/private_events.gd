class_name AstraPrivateEvents
extends RefCounted

# 0.5.0: authored private moments are a pool, not one biography dump per face.
# Counts intentionally differ by character. Conditions decide which moment is
# appropriate now; the session passes day/trust/stress instead of revealing a
# scene simply because a scalar crossed one universal threshold.

const EVENTS := {
    "mira": [
        {"scene":"미라가 새 장갑을 꺼내다 손을 멈춘다. 당신이 들어오자 한 쌍을 건넨다.","prompt":"“같이 확인해 줄래요? 제가 자꾸 같은 줄을 놓쳐요.”","choices":[{"label":"장갑을 끼고 곁에 선다.","hint":"","effect":"comfort"},{"label":"“그때 본 것부터 말해 줘요.”","hint":"","effect":"witness"}]},
        {"scene":"미라가 찬 물컵을 손바닥으로 감싸고 있다. 아직 한 모금도 마시지 않았다.","prompt":"“수면에서 깨면 목이 마른 게 정상인데… 오늘은 물 냄새가 이상하게 느껴져요.”","choices":[],"resolution":"잠시 아무 말도 하지 않는다. 미라는 컵을 내려놓고 새 물을 받으러 간다.","min_day":2},
        {"scene":"의료 단말에 같은 체온 기록이 두 번 겹쳐 있다. 미라가 한 줄씩 손가락으로 짚는다.","prompt":"“제가 잘못 옮긴 건지, 원본부터 이런 건지 같이 봐요.”","choices":[{"label":"원본과 사본을 나란히 놓는다.","hint":"","effect":"open_records"},{"label":"미라의 설명을 먼저 듣는다.","hint":"","effect":"read"}]},
        {"scene":"미라가 비어 있는 침상을 정리하다가 베개를 다시 제자리에 둔다.","prompt":"“사람이 없는데도 자꾸 습관처럼 준비하게 되네요.”","choices":[{"label":"말없이 시트를 같이 편다.","hint":"","effect":"comfort"},{"label":"“누가 가장 걱정돼요?”","hint":"","effect":"top_suspect"}],"min_stress":0.35},
        {"scene":"미라가 자신의 맥박 기록을 열어 둔 채 화면 밝기를 낮춘다.","prompt":"“제 기록도 남들 것처럼 보세요. 저만 예외면 더 이상하잖아요.”","choices":[{"label":"같은 기준으로 기록을 확인한다.","hint":"","effect":"read"},{"label":"“그 말, 회의에서도 해 주세요.”","hint":"","effect":"calm_meeting"}],"min_trust":0.1},
        {"scene":"미라가 응급 키트를 채우다 진통제 한 칸이 비어 있는 걸 발견한다.","prompt":"“쓴 사람은 괜찮겠죠. 다만 언제 썼는지는 알아야 해요.”","choices":[{"label":"사용 기록을 같이 연다.","hint":"","effect":"open_records"},{"label":"일단 사람들 상태부터 확인한다.","hint":"","effect":"witness"}],"min_day":2}
    ],
    "rho": [
        {"scene":"준이 바닥에 공구를 펼쳐 놓았다. 평소와 달리 농담을 하지 않는다.","prompt":"“내가 만진 데가 있어. 같이 봐 줘. 혼자 확인하면 또 놓칠 것 같아.”","choices":[{"label":"옆에 앉아 기록을 편다.","hint":"","effect":"open_records"}]},
        {"scene":"준이 드라이버 손잡이에 테이프를 새로 감고 있다. 색이 마음에 안 드는지 두 번 뜯었다.","prompt":"“이상하지? 이런 건 기억나는데 어제 어디 있었는지는 흐려.”","choices":[{"label":"“기억나는 것부터 순서대로 말해 봐.”","hint":"","effect":"witness"},{"label":"공구를 하나 건네준다.","hint":"","effect":"comfort_light"}]},
        {"scene":"기관실 바닥에 나사 세 개가 일렬로 놓여 있다. 준이 네 번째 자리를 비워 둔다.","prompt":"“하나가 없어. 별거 아닐 수도 있는데, 난 이런 거 못 넘겨.”","choices":[{"label":"정비 기록을 같이 뒤진다.","hint":"","effect":"open_records"},{"label":"“누가 여기 들어왔는지부터 보자.”","hint":"","effect":"top_suspect"}],"min_day":2},
        {"scene":"준이 식어 버린 커피를 한 모금 마시고 바로 얼굴을 찌푸린다.","prompt":"“이건 진짜 범죄다. 누가 내 커피를 이렇게 오래 뒀냐.”","choices":[{"label":"새로 한 잔 내려 준다.","hint":"","effect":"comfort"},{"label":"“그래도 조금 웃네.”","hint":"","effect":"comfort_light"}],"min_stress":0.3},
        {"scene":"준이 열린 패널 앞에서 손을 떼고 당신에게 먼저 보라고 비킨다.","prompt":"“내가 손대기 전에 상태 찍어 둬. 나중에 또 말 달라졌다고 하면 귀찮으니까.”","choices":[{"label":"사진 대신 기록 번호를 남긴다.","hint":"","effect":"dax_hint"},{"label":"“그 정도로 누가 못 믿겠어?”","hint":"","effect":"top_suspect"}],"min_trust":0.05}
    ],
    "eli": [
        {"scene":"루칸이 항로의 끝을 화면 밖으로 밀어 놓는다.","prompt":"“가까이만 보면 놓치는 게 있어. 사람들이 어디를 보고 있는지.”","choices":[{"label":"“회의에서 뭘 봤어?”","hint":"","effect":"flow"},{"label":"화면을 전체 보기로 바꾼다.","hint":"","effect":"top_suspect"}]},
        {"scene":"루칸이 창문과 항법 화면을 번갈아 본다. 별 하나를 손가락으로 가린다.","prompt":"“화면에서는 움직이는데, 저 별은 그대로야.”","choices":[{"label":"시간 기록을 함께 맞춘다.","hint":"","effect":"open_records"},{"label":"“확신할 때까지 말하지 않아도 돼.”","hint":"","effect":"comfort_light"}],"min_day":2},
        {"scene":"루칸이 의자 방향을 출입문 쪽으로 돌려 놓았다.","prompt":"“누가 들어오면 먼저 발소리가 들려. 오늘은 그게 편해.”","choices":[{"label":"그대로 두고 옆에 앉는다.","hint":"","effect":"comfort"},{"label":"“누구 발소리를 기다리는 거야?”","hint":"","effect":"top_suspect"}],"min_stress":0.4},
        {"scene":"항법 로그 한 줄이 지도 바깥 좌표를 가리킨다. 루칸은 확대하지 않는다.","prompt":"“숫자는 맞아. 그래서 더 이상해.”","choices":[{"label":"원본 로그를 연다.","hint":"","effect":"dax_hint"},{"label":"“회의에서 이 좌표를 보여 주자.”","hint":"","effect":"flow"}],"min_trust":0.1}
    ],
    "sena": [
        {"scene":"세나가 문고리를 확인하고 당신 옆에 선다.","prompt":"“오늘은 내가 돌게. 너까지 안 자면 내일 둘 다 늦어.”","choices":[{"label":"“한 바퀴 돌고 깨워 줘.”","hint":"","effect":"patrol"},{"label":"“같이 확인하고 쉬자.”","hint":"","effect":"procedure"}]},
        {"scene":"세나가 꺼진 보안등 아래에서 전구가 아니라 배선을 먼저 본다.","prompt":"“불이 나간 게 문제가 아냐. 누가 이 구역만 끊었는지가 문제지.”","choices":[{"label":"출입 기록을 같이 확인한다.","hint":"","effect":"open_records"},{"label":"“누가 가장 먼저 떠올라?”","hint":"","effect":"top_suspect"}]},
        {"scene":"세나가 식판을 문 옆에 둔 채 먹지 않고 있다.","prompt":"“순찰 돌다 먹으려고. 차가운 건 익숙해.”","interject":{"speaker":"rho","text":"“차가운 게 익숙한 게 자랑은 아니거든.” 준이 문밖에서 한마디 던진다."},"choices":[{"label":"“5분만 앉아서 먹어.”","hint":"","effect":"comfort"},{"label":"같이 순찰 동선을 확인한다.","hint":"","effect":"flow"}],"min_stress":0.3},
        {"scene":"세나가 당신에게 출입카드를 건넸다가 다시 가져간다.","prompt":"“아니, 네가 들고 있으면 내가 또 네 위치부터 신경 쓸 것 같아.”","choices":[{"label":"“그럼 네가 갖고 있어.”","hint":"","effect":"comfort_light"},{"label":"“절차대로 공동 기록하자.”","hint":"","effect":"procedure"}],"min_trust":0.15},
        {"scene":"보안 기록에 준의 이름이 있는 날과 없는 날이 겹쳐 있다. 세나가 화면을 오래 본다.","prompt":"“나는 같이 근무했다고 기억해. 저쪽 기록은 아니래.”","choices":[{"label":"기억과 기록을 둘 다 남긴다.","hint":"","effect":"dax_hint"},{"label":"“준에게 바로 묻기 전에 더 보자.”","hint":"","effect":"calm_meeting"}],"min_day":2}
    ],
    "vale": [
        {"scene":"소렌이 이어폰을 두 개 꺼낸다. 재생 버튼 위에서 손이 멈춘다.","prompt":"“그때 혼자 들었어요. 이번에는 같이 들어 줘요.”","choices":[{"label":"이어폰을 낀다.","hint":"","effect":"vale_record"}]},
        {"scene":"소렌이 통신 잡음을 아주 작게 틀어 놓고 파형을 손으로 따라간다.","prompt":"“목소리는 아닌데, 숨 쉬는 간격처럼 들려요.”","choices":[{"label":"같은 구간을 다시 듣는다.","hint":"","effect":"vale_record"},{"label":"“잠깐 쉬었다 들어요.”","hint":"","effect":"comfort_light"}]},
        {"scene":"소렌이 음악 파일과 통신 파일을 같은 재생 목록에 넣었다가 멈춘다.","prompt":"“둘 사이가 너무 비슷해서 싫어요. 음악까지 의심하게 되니까.”","choices":[],"resolution":"소렌은 음악 파일을 목록에서 빼고, 통신 파일만 조용히 다시 재생한다.","min_stress":0.35},
        {"scene":"소렌이 자신의 수면 중 음성을 듣고 볼륨을 내린다.","prompt":"“제가 말한 건 맞아요. 그런데 저는 그때 깨어 있지 않았어요.”","choices":[{"label":"시간대부터 다시 확인한다.","hint":"","effect":"vale_record"},{"label":"“모른다고 말해도 괜찮아요.”","hint":"","effect":"comfort_light"}],"min_day":2}
    ],
    "noa": [
        {"scene":"노아가 지우려던 문장을 그대로 둔 채 단말을 내민다.","prompt":"“읽어 줄래요? 제가 먼저 말하면 그쪽으로 보일 것 같아요.”","choices":[{"label":"소리 내지 않고 읽는다.","hint":"","effect":"noa_private"},{"label":"“같이 확인할 사람을 부를까?”","hint":"","effect":"noa_public"},{"label":"단말을 돌려주고 기다린다.","hint":"","effect":"comfort_light"}]},
        {"scene":"노아가 같은 메모를 두 장에 적고 한 장을 찢는다.","prompt":"“문장이 다르면 기억도 달라지는 것 같아서요. 하나만 남기려고 했어요.”","choices":[{"label":"두 장 모두 날짜를 적어 보관한다.","hint":"","effect":"open_records"},{"label":"“어느 쪽이 더 맞는 것 같아요?”","hint":"","effect":"read"}]},
        {"scene":"노아가 컵 밑에 작은 종이를 받쳐 놓았다. 번진 잉크가 동그랗게 남았다.","prompt":"“이건 버려도 되는데… 오늘은 뭔가 버리기가 싫네요.”","choices":[{"label":"종이를 말려 노트 사이에 넣는다.","hint":"","effect":"comfort"},{"label":"“기록도 그래서 못 지웠어요?”","hint":"","effect":"noa_private"}],"min_stress":0.3},
        {"scene":"노아가 회의 기록의 말줄임표를 전부 지우고 있다.","prompt":"“멈춘 시간이 다 달라 보여요. 말 안 한 것도 기록일까요?”","interject":{"speaker":"dax","text":"“시간은 남겨. 해석은 나중에 붙이면 돼.” 다렌이 화면 너머에서 말한다."},"choices":[{"label":"침묵도 시간과 함께 남긴다.","hint":"","effect":"flow"},{"label":"“해석은 나중에 하자.”","hint":"","effect":"procedure"}],"min_day":2},
        {"scene":"노아가 당신이 한 말을 그대로 인용한 뒤 고개를 젓는다.","prompt":"“뜻은 같은데, 제가 기억한 어순은 달라요.”","choices":[{"label":"두 표현을 나란히 적는다.","hint":"","effect":"dax_hint"},{"label":"“어느 쪽도 지우지 마요.”","hint":"","effect":"comfort_light"}],"min_trust":0.1},
        {"scene":"노아가 봉인된 로그를 열지 않고 제목만 읽는다.","prompt":"“열면 답이 나올 수도 있어요. 그런데 누가 먼저 봤는지도 같이 사라질 것 같아요.”","choices":[{"label":"공개할 사람을 먼저 정한다.","hint":"","effect":"noa_public"},{"label":"둘만 원본을 확인한다.","hint":"","effect":"noa_private"}],"min_day":2,"min_trust":0.2}
    ],
    "lyra": [
        {"scene":"마렌이 시든 가지와 살아 있는 가지를 따로 놓는다.","prompt":"“구할 수 있는 쪽에 물을 줘야 해요. 아는데, 손이 안 움직여요.”","choices":[{"label":"가위를 건네고 곁에 앉는다.","hint":"","effect":"calm_meeting"},{"label":"“누가 가장 몰리고 있어요?”","hint":"","effect":"crowd_target"},{"label":"작업대를 같이 정리한다.","hint":"","effect":"comfort_light"}]},
        {"scene":"마렌이 작은 화분 세 개의 위치를 바꾸고 다시 원래대로 놓는다.","prompt":"“빛은 똑같은데 얘들 반응이 달라요. 사람도 그렇겠죠.”","choices":[{"label":"온도와 조도를 같이 적는다.","hint":"","effect":"dax_hint"},{"label":"“사람 얘기라면 누가 떠올랐어요?”","hint":"","effect":"top_suspect"}]},
        {"scene":"온실에 젖은 흙 냄새가 난다. 마렌이 장갑을 벗고 손등을 확인한다.","prompt":"“여긴 냄새가 그대로라서 좋아요. 다른 건 자꾸 달라지는데.”","choices":[{"label":"잠깐 같이 앉아 있는다.","hint":"","effect":"comfort"},{"label":"시료 기록을 확인한다.","hint":"","effect":"open_records"}],"min_stress":0.3},
        {"scene":"마렌이 표본 봉투의 날짜를 읽다 멈춘다.","prompt":"“이 날짜면 우리가 출항하기 전이에요. 제가 적은 글씨는 맞고요.”","choices":[{"label":"원본 라벨을 따로 보관한다.","hint":"","effect":"open_records"},{"label":"“혼자 결론 내리지 말자.”","hint":"","effect":"calm_meeting"}],"min_day":2},
        {"scene":"마렌이 식사 배급표를 들고 사람 수를 다시 센다.","prompt":"“먹은 양은 거짓말을 덜 해요. 적어도 누가 여기 있었는지는요.”","choices":[{"label":"배급 기록을 같이 본다.","hint":"","effect":"witness"},{"label":"“사람 상태부터 챙겨요.”","hint":"","effect":"comfort_light"}],"min_trust":0.1}
    ],
    "dax": [
        {"scene":"다렌이 두 계산을 지우지 않고 나란히 남겨 둔다.","prompt":"“내가 틀린 쪽부터 보고 싶어. 어디가 걸리지?”","choices":[{"label":"“기록하고 다른 곳부터.”","hint":"","effect":"dax_hint"},{"label":"“지금 누구의 말이 걸려?”","hint":"","effect":"top_suspect"}]},
        {"scene":"다렌이 단말 계산기와 종이 계산의 마지막 자릿수를 비교한다.","prompt":"“답이 같다고 과정까지 같은 건 아니지.”","choices":[{"label":"중간 계산도 남긴다.","hint":"","effect":"open_records"},{"label":"“사람 진술도 그렇게 보자는 거지?”","hint":"","effect":"flow"}]},
        {"scene":"다렌이 의자 등받이에 기대 눈을 감고 숫자를 외운다.","prompt":"“화면을 오래 보면 내가 본 건지 시스템이 보여 준 건지 섞여.”","choices":[],"resolution":"당신은 말을 보태지 않는다. 다렌은 잠시 뒤 눈을 뜨고 종이에만 숫자를 옮긴다.","min_stress":0.35},
        {"scene":"다렌이 같은 로그를 다른 정렬 순서로 두 번 출력한다.","prompt":"“순서만 바꿨는데 범인이 달라 보이면 우리가 잘못 보고 있는 거야.”","choices":[{"label":"두 목록의 공통점만 표시한다.","hint":"","effect":"dax_hint"},{"label":"회의에서 두 목록을 같이 보여 준다.","hint":"","effect":"calm_meeting"}],"min_day":2},
        {"scene":"다렌이 당신이 표시한 의심표를 보고 한 칸을 손가락으로 가린다.","prompt":"“이 사람을 빼도 네 설명이 성립해?”","choices":[{"label":"가설을 처음부터 다시 읽는다.","hint":"","effect":"read"},{"label":"“네가 보는 가장 약한 고리는?”","hint":"","effect":"top_suspect"}],"min_trust":0.1}
    ]
}

static func has_event(npc_id: String) -> bool:
    return EVENTS.has(npc_id) and not Array(EVENTS[npc_id]).is_empty()

static func count_for(npc_id: String) -> int:
    return Array(EVENTS.get(npc_id, [])).size()

static func _eligible(npc_id: String, context: Dictionary) -> Array:
    var result: Array = []
    for raw in Array(EVENTS.get(npc_id, [])):
        var event: Dictionary = raw
        if int(context.get("day", 1)) < int(event.get("min_day", 1)):
            continue
        if float(context.get("trust", 0.0)) < float(event.get("min_trust", -1.0)):
            continue
        if float(context.get("stress", 0.0)) < float(event.get("min_stress", -1.0)):
            continue
        result.append(event)
    if result.is_empty() and has_event(npc_id):
        result.append(Array(EVENTS[npc_id])[0])
    return result

static func build(npc_id: String, victim: String, variant_index: int = 0, context: Dictionary = {}) -> Dictionary:
    var pool := _eligible(npc_id, context)
    if pool.is_empty():
        return {}
    var source: Dictionary = pool[posmod(variant_index, pool.size())]
    var event := source.duplicate(true)
    event["npc_id"] = npc_id
    event["event_index"] = variant_index
    event["prompt"] = AstraJosa.fill(str(source.get("prompt", "")), {"victim": victim})
    return event
