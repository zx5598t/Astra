class_name AstraStorylets053
extends RefCounted

# ASTRA 0.5.3 — HEARTBEAT
# The 0.5.2 Living Crew systems already know *what* changed. This registry gives
# those systems authored moments that make the change visible. Most content is
# mid/late-game so the first thirty minutes stay light.

const MID_CHAPTERS := ["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]
const LATE_CHAPTERS := ["SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]

# [group, tag, category, family, action, line, metadata]
const MIRA_PACKS := [
    ["CARE","player","PLAYER","mira_wrist_first","당신이 기록 단말을 열자 미라가 화면보다 손목 센서를 먼저 본다.","기록은 도망 안 가요. 심박부터요.",{"player_specific":true,"tone_lines":{"WARM":"또 기록부터 보려고 했죠? 심박부터요.","PROFESSIONAL":"기록 전에 상태 확인할게요.","STRAINED":"앉아요. 검사만 하고 갈게요."},"requires":{"player_axis":"evidence_first"}}],
    ["CARE","danger","CRISIS","mira_after_danger","경보가 멎자 미라는 주변 장비가 아니라 당신 얼굴부터 확인한다.","괜찮아요? …아니, 그건 제가 확인할게요.",{"player_specific":true,"rarity":"uncommon"}],
    ["CARE","player","PLAYER","mira_sensor_back","모두의 수치를 적은 미라가 자기 센서는 켜지 않은 채 서랍을 닫는다.","저는 괜찮— …알았어요.",{"player_specific":true,"choices":[{"label":"센서를 미라에게 건넨다.","effect":"protect","memory_tag":"checked_on_mira"},{"label":"말없이 옆에 놓아 둔다.","effect":"wait"}]}],
    ["CARE","reaction","PLAYER","mira_same_answer","미라는 대답이 나오기 전에 작은 센서를 꺼낸다. 당신이 괜찮다고 말할 걸 예상한 듯하다.","이번에는 ‘괜찮다’부터 말하지 마요.",{"player_specific":true,"requires":{"choice_effect":"withhold","choice_count_min":2},"rarity":"uncommon"}],
    ["CARE","work","WORK","mira_patient_before_log","미라는 오류가 난 의료 단말을 그대로 둔 채 옆 침상의 호흡부터 센다.","기계는 잠깐 기다려도 돼요. 사람은 아닐 수도 있어요.",{}],

    ["DAILY","everyday","DAILY","mira_tea_long","미라는 찻잔을 들었다가 너무 진해진 색을 보고 뜨거운 물을 더 붓는다.","또 너무 오래 우렸네요. 생각할 때마다 이래요.",{}],
    ["DAILY","everyday","DAILY","mira_piano_volume","의료실 피아노 곡이 평소보다 아주 조금 작다. 미라는 볼륨 표시를 보고 고개를 갸웃한다.","이 정도가 편한 것 같아서요. 이유는 잘 모르겠지만.",{"requires":{"min_loop":1},"rarity":"uncommon","deviation_reason":"MEMORY_MISMATCH","source_event":"player_lowered_music","possible_followup":"mira_music_recognition"}],
    ["DAILY","echo","ECHO","mira_cup_left","처음 받은 당신의 컵이 의료실 왼쪽 끝, 손이 가장 쉽게 닿는 자리에 놓여 있다.","…제가 거기 뒀어요?",{"player_specific":true,"requires":{"min_loop":1},"rarity":"rare","deviation_reason":"MEMORY_MISMATCH","source_event":"cup_motif","possible_followup":"mira_cup_again"}],
    ["DAILY","silence","MOOD","mira_quiet_charts","미라는 차트를 정리하고 당신은 기록을 읽는다. 한동안 둘 다 말을 하지 않는다.","",{"player_specific":true,"tone_actions":{"WARM":"같은 방의 침묵이 굳이 채울 필요 없는 것처럼 느껴진다.","PROFESSIONAL":"서로 자기 일을 하는 조용한 시간이 흐른다.","STRAINED":"침묵이 길다. 둘 다 먼저 말을 꺼내지 않는다."}}],

    ["MEDICAL","work","MEDICAL","mira_triage","미라는 남은 산소와 침상 수를 보고 치료 순서를 직접 바꾼다.","먼저 살릴 수 있는 쪽부터 할게요. 좋아서 고르는 건 아니에요.",{"agency":true}],
    ["MEDICAL","personal","MEDICAL","mira_privacy","미라는 환자 기록 한 줄을 가리고 나머지만 당신에게 돌려 준다.","필요한 정보는 드릴게요. 이 부분은 아직 그 사람 것이에요.",{"agency":true,"choices":[{"label":"가린 부분은 묻지 않는다.","effect":"promise","memory_tag":"respected_medical_privacy"},{"label":"“사건과 관련 있으면 알아야 해요.”","effect":"confront","memory_tag":"challenged_medical_privacy"}]}],
    ["MEDICAL","mystery","MYSTERY","mira_body_nineteen","19년 전 도착 기록을 본 미라는 날짜보다 현재 신체 검사표를 먼저 띄운다.","그럼 우리 몸은요? 기록대로면 이 수치가 이렇게 남아 있을 수 없어요.",{"chapters":["SILENT_ORBIT","LAST_LIGHT"]}],
    ["MEDICAL","work","MEDICAL","mira_med_stock","미라는 진통제 수량보다 사용 시각을 먼저 맞춘다.","누가 가져갔는지는 나중이에요. 먹은 사람이 지금 괜찮은지가 먼저예요.",{}],

    ["PLAYER","player","PLAYER","mira_style_read","미라는 손이 먼저 향하는 곳을 보고 다음 장비를 미리 꺼내 둔다.","",{"player_specific":true,"tone_lines":{"WARM":"또 기록부터 갈 거죠? 저는 사람 쪽 볼게요.","PROFESSIONAL":"당신은 기록을 보세요. 저는 상태를 확인할게요.","STRAINED":"각자 맡은 것부터 해요. 그게 지금은 빠르겠어요."}}],
    ["PLAYER","personal","PLAYER","mira_promise_injury","미라는 새 붕대를 꺼내며 포장지를 접어 당신 쪽에 밀어 둔다.","다치면 말하기. 그것만 약속해요.",{"player_specific":true,"choices":[{"label":"“약속할게요.”","effect":"promise","promise":"tell_injury"},{"label":"“그럴 일 없게 할게요.”","effect":"withhold"}],"rarity":"uncommon"}],
    ["PLAYER","reaction","PLAYER","mira_broken_injury_promise","미라는 숨겨 둔 상처를 본 뒤 바로 치료한다. 다 끝난 뒤에야 당신을 본다.","말하기로 했잖아요.",{"player_specific":true,"requires":{"memory_tag":"promise_broken:tell_injury"},"rarity":"rare"}],
    ["PLAYER","conflict","CONFLICT","mira_accused_by_player","미라는 화면에 남은 자신의 의심 표시를 보고도 지우라고 하지 않는다.","믿어 달라고 하진 않을게요. 대신 제가 안 했다는 증거도 같이 찾아봐요.",{"player_specific":true,"requires":{"memory_tag":"accused_mira"},"rarity":"uncommon"}],
    ["PLAYER","reaction","PLAYER","mira_defended_by_player","회의 뒤 미라는 고맙다는 말보다 당신의 근거부터 다시 읽는다.","저라서 믿은 건 아니죠? …그랬으면 좋겠어요.",{"player_specific":true,"requires":{"memory_tag":"defended_mira"},"rarity":"uncommon"}],
    ["PLAYER","personal","PLAYER","mira_return_last_light","미라는 의료실 문을 열어 둔 채 당신이 나갈 준비를 하는 걸 본다.","",{"player_specific":true,"chapters":["LAST_LIGHT"],"rarity":"uncommon","tone_lines":{"WARM":"이번에도 기록부터 보러 갈 거예요? …알아요. 그래도 돌아와요.","PROFESSIONAL":"끝나면 의료실 들러요. 검사 하나 남았어요.","STRAINED":"다치면 적어도 말은 해요. 그건 별개니까."}}],

    ["RELATIONSHIP","personal","RELATIONSHIP","mira_people_first_callback","미라는 기록보다 사람을 먼저 확인했던 당신의 선택을 기억하고 있다.","그때 기록보다 사람부터 본 거, 저는 기억해요.",{"player_specific":true,"requires":{"player_axis":"people_first"},"rarity":"uncommon"}],
    ["RELATIONSHIP","conflict","CONFLICT","mira_record_over_person","미라는 부상자를 뒤로 두고 기록을 가져온 결정을 비난하지 않는다. 대신 목소리가 평소보다 조용하다.","틀렸다고 말하려는 건 아니에요. 저라면 그렇게 못 했을 것 같아서.",{"player_specific":true,"requires":{"player_axis":"evidence_first"},"rarity":"rare","deviation_reason":"RECENT_CONFLICT","source_event":"record_over_person","possible_followup":"mira_value_repair"}],
    ["RELATIONSHIP","personal","RELATIONSHIP","mira_secret_kept","미라는 당신에게만 보여 줬던 의료 메모가 그대로 봉인되어 있는 걸 확인한다.","말하지 않은 것도 선택이었다는 건 알아요. 이번엔 그 선택을 믿을게요.",{"player_specific":true,"requires":{"memory_tag":"respected_medical_privacy"},"rarity":"rare"}],

    ["ECHO","echo","ECHO","mira_protection_device","산소 경보 속에서 당신이 기록 장치를 챙기려 하자 미라가 전원부터 꺼 버린다.","그건 다시 켤 수 있어요. 당신은 아니고.",{"player_specific":true,"requires":{"min_loop":1,"echo_axis":"protection","echo_min":0.28},"rarity":"rare","deviation_reason":"PROTECTION_ECHO","source_event":"prior_protection","possible_followup":"mira_protection_after"}],
    ["ECHO","echo","ECHO","mira_grief_breath","당신이 들어오자 미라의 호흡이 아주 잠깐 멈춘다. 본인도 그 사실을 알아차린 듯 시선을 피한다.","…아니에요.",{"player_specific":true,"requires":{"min_loop":1,"echo_axis":"grief","echo_min":0.25},"rarity":"rare","deviation_reason":"GRIEF_ECHO","source_event":"previous_loss","possible_followup":"mira_grief_quiet"}],
    ["ECHO","echo","ECHO","mira_conflict_careful","미라는 낯선 사람을 대하듯 예의를 갖추지만, 질문을 하기 전 한 번 더 단어를 고른다.","상태부터 볼게요. 다른 이야기는… 그다음에 해요.",{"player_specific":true,"requires":{"min_loop":1,"echo_axis":"conflict","echo_min":0.25},"rarity":"rare","deviation_reason":"RECENT_CONFLICT","source_event":"previous_conflict","possible_followup":"mira_conflict_softens"}],

    ["CONFLICT","conflict","CONFLICT","mira_stop_risk","당신이 위험 구역 문을 다시 열려 하자 미라가 문 옆 차단 스위치를 먼저 내린다.","그만해요. 사람이 없어지면 시간이 남아도 소용없어요.",{"player_specific":true,"agency":true}],
    ["CONFLICT","conflict","CONFLICT","mira_withheld_medical","미라는 사건과 관련된 의료 기록 일부를 늦게 공유했다는 질문을 피하지 않는다.","말하지 않을 이유가 있었어요. 그게 옳았는지는 지금도 모르겠고요.",{"player_specific":true,"agency":true,"role_lines":{"NULL":"확정되지 않은 내용을 퍼뜨리면 치료도 조사도 망가져요. 필요한 부분은 이미 말했어요.","CREW":"환자 비밀이었어요. 사건과 연결된 걸 확인하고 나서야 말할 수 있었어요."},"rarity":"uncommon"}]
]

# Four compact callbacks per other crewmate: enough to make player memory feel
# systemic without stealing each chapter's established spotlight.
const CREW_PACKS := {
    "rho":[
        ["PLAYER","reaction","RELATIONSHIP","rho_repeat_direct","준이 질문이 나오기도 전에 공구 하나를 당신 쪽으로 밀어 준다.","또 직접 뜯어볼 거지? 이번엔 이거부터 써.",{"requires":{"player_axis":"confrontational"}}],
        ["DAILY","everyday","DAILY","rho_bandage_bill","준이 새 붕대를 손목에 감고 의료실 쪽을 힐끗 본다.","이번엔 진짜 긁힌 것뿐이야. 미라한텐 그렇게 말해 줘.",{}],
        ["RELATIONSHIP","pair","PAIR","rho_sena_defense_callback","준은 세나가 지난 회의에서 자기 편을 들었던 말을 농담으로 넘기지 않는다.","그때 말해 준 건… 기억해.",{"requires":{"memory_tag":"sena_defended_rho"},"rarity":"uncommon","target":"sena"}],
        ["WORK","work","WORK","rho_share_tendency","준은 확인된 배선 상태를 근처 사람들에게 먼저 보여 준다.","이건 숨길 이유 없어. 손댈 사람은 다 알아야 해.",{"knowledge_share":"work"}]
    ],
    "noa":[
        ["PLAYER","reaction","RELATIONSHIP","noa_pattern_record","노아의 노트 한쪽에 당신이 기록을 먼저 보는 순서가 짧게 적혀 있다.","이번에도 같네요. 기록, 사람, 현장.",{"requires":{"player_axis":"evidence_first"}}],
        ["PLAYER","reaction","RELATIONSHIP","noa_secretive_callback","노아는 아직 공개되지 않은 당신의 파일을 보며 질문을 줄인다.","공개할 준비가 되면 먼저 알려 주세요. 지금은 경로만 남길게요.",{"requires":{"player_axis":"secretive"}}],
        ["WORK","work","WORK","noa_verified_share","노아는 검증이 끝난 페이지에만 작은 공개 표시를 붙인다.","확인 안 된 건 제 노트에. 확인된 건 모두에게.",{"knowledge_share":"verified"}],
        ["CONFLICT","conflict","CONFLICT","noa_vote_memory","노아는 어제의 투표표와 오늘 기록을 나란히 둔다.","어제 판단이 틀렸다면 이유까지 같이 고쳐야 해요.",{}]
    ],
    "sena":[
        ["PLAYER","reaction","RELATIONSHIP","sena_protective_player","세나는 다른 사람을 먼저 빼낸 당신의 선택을 보고 다음 문을 먼저 연다.","사람부터 빼는 건 나도 동의해.",{"requires":{"player_axis":"protective"}}],
        ["DAILY","everyday","DAILY","sena_bandage_again","세나의 손목에 의료실 붕대가 또 감겨 있다.","말 안 해도 미라는 알아채더라.",{}],
        ["RELATIONSHIP","pair","PAIR","sena_rho_defense_memory","세나는 준에게 별말 없이 출입 권한을 먼저 열어 준다.","어제 네 말은 들었어. 오늘은 작업부터 해.",{"requires":{"memory_tag":"rho_defended_sena"},"rarity":"uncommon","target":"rho"}],
        ["WORK","work","WORK","sena_security_share","세나는 공개 경보는 즉시 띄우지만 보안 코드 자체는 화면에서 가린다.","위험은 알려야 해. 방법까지 다 보여 줄 필요는 없고.",{"knowledge_share":"security"}]
    ],
    "dax":[
        ["PLAYER","reaction","RELATIONSHIP","dax_evidence_pattern","다렌은 기록부터 보는 당신의 습관을 예상해 비교표의 빈칸을 남겨 둔다.","여긴 네가 채워. 사람 쪽은 내가 다시 물어볼게.",{"requires":{"player_axis":"evidence_first"}}],
        ["DAILY","everyday","DAILY","dax_meal_math","다렌이 식사량을 정확히 반으로 나누다가 마지막 한 조각은 그냥 준다.","이건 계산 안 해도 되겠네.",{}],
        ["RELATIONSHIP","work","WORK","dax_rho_respect_callback","다렌은 준이 들었다는 소리를 이번에는 계산표의 입력값으로 먼저 넣는다.","관측이면 관측이지. 출처가 준이라고 버릴 이유는 없어.",{}],
        ["WORK","work","WORK","dax_share_model","다렌은 결론보다 계산 조건을 먼저 공유한다.","결과만 퍼지면 다음 사람이 같은 실수를 해.",{"knowledge_share":"system"}]
    ],
    "vale":[
        ["PLAYER","reaction","RELATIONSHIP","vale_patient_player","소렌은 재촉하지 않았던 당신을 기억한 듯 재생 버튼에서 손을 뗀다.","조금만 있다가 같이 들어요.",{"requires":{"player_axis":"patient"}}],
        ["DAILY","everyday","DAILY","vale_ear_rest","소렌은 한쪽 이어폰을 빼고 귀 뒤를 천천히 문지른다.","미라 말이 맞았어요. 계속 들으면 진짜 소리도 잡음처럼 돼요.",{}],
        ["RELATIONSHIP","pair","PAIR","vale_eli_quiet_callback","소렌은 루칸이 준 좌표만 적고 그 이유는 묻지 않는다.","설명은 나중에 들어도 돼요. 위치는 지금 필요하니까.",{"target":"eli"}],
        ["WORK","work","WORK","vale_share_signal","소렌은 확인되지 않은 음성은 보내지 않고 반복 간격만 공유한다.","제가 들은 말은 아직 제 거예요. 간격은 모두가 써도 되고요.",{"knowledge_share":"signal"}]
    ],
    "eli":[
        ["PLAYER","reaction","RELATIONSHIP","eli_skeptical_player","루칸은 한 번 더 확인하는 당신을 보고 이미 두 번째 경로를 띄워 둔다.","비교할 거면 이쪽도 봐.",{"requires":{"player_axis":"skeptical"}}],
        ["DAILY","everyday","DAILY","eli_blank_window","루칸은 화면을 끄고 한동안 창밖 별만 본다.","가끔은 업데이트 안 되는 걸 봐야 해.",{}],
        ["RELATIONSHIP","pair","PAIR","eli_vale_callback","루칸은 소렌의 신호 시각을 들은 뒤 말없이 지도 한 점을 확대한다.","여기면 설명 하나는 줄어.",{"target":"vale"}],
        ["WORK","work","WORK","eli_share_route","루칸은 위험 경로는 즉시 공유하지만 아직 계산 중인 목적지는 남겨 둔다.","가야 할 데랑 갈 수도 있는 데는 다르니까.",{"knowledge_share":"route"}]
    ],
    "lyra":[
        ["PLAYER","reaction","RELATIONSHIP","lyra_people_first","마렌은 사람부터 확인하는 당신을 보고 시료 상자를 잠시 내려놓는다.","그럼 저는 환경 볼게요. 나중에 서로 바꿔 봐요.",{"requires":{"player_axis":"people_first"}}],
        ["DAILY","everyday","DAILY","lyra_mira_plant","마렌은 미라에게 보낼 작은 화분의 마른 잎만 떼어 낸다.","미라는 분명 물 주는 걸 또 잊을 테니까요.",{}],
        ["RELATIONSHIP","work","WORK","lyra_dax_survival","마렌은 생존 확률표 옆에 실제 잎 상태를 붙인다. 표는 다렌이 만든 것이다.","살아남는다는 숫자에 이 상태도 들어가야 해요.",{}],
        ["WORK","work","WORK","lyra_share_risk","마렌은 생존에 직접 영향을 주는 표본 이상은 망설이지 않고 공개한다.","이건 비밀로 두면 안 돼요. 숨 쉬는 문제니까.",{"knowledge_share":"survival"}]
    ]
}

const SOCIAL_SCENES := [
    {"id":"053_mira_lyra_oxygen","speaker":"lyra","target":"mira","tag":"pair","category":"PAIR","family":"mira_lyra_resources","intent":"conflict","action":"의료실 산소 배분표와 생태실 환기표가 같은 자원을 요구한다.","lines":[["lyra","이쪽을 더 줄이면 내일 공기 질이 떨어져요."],["mira","알아요. 오늘 밤을 넘길 사람도 있어요."],["lyra","그럼 두 시간만. 그 뒤엔 다시 돌려요."],["mira","좋아요. 제가 시간 적을게요."]],"line_relations":["anchor","challenge","proposal","agreement"],"chapters":MID_CHAPTERS},
    {"id":"053_mira_lyra_plant","speaker":"mira","target":"lyra","tag":"pair","category":"PAIR","family":"mira_lyra_daily","intent":"relationship","action":"미라는 마렌이 준 화분의 흙을 손가락으로 눌러 보고 물컵을 든다.","lines":[["mira","오늘은 안 잊었어요."],["lyra","제가 아직 아무 말도 안 했는데요."],["mira","그래서 더 뿌듯한데요."]],"line_relations":["anchor","tease","reply"],"chapters":MID_CHAPTERS},
    {"id":"053_mira_lyra_grief","speaker":"lyra","target":"mira","tag":"pair","category":"RELATIONSHIP","family":"mira_lyra_grief","intent":"support","action":"마렌은 미라가 빈 침상을 정리하는 동안 시든 잎을 버리지 않고 옆에 둔다.","lines":[["lyra","정리한다고 없던 일이 되는 건 아니죠."],["mira","네. 그래도 다음 사람이 누울 자리는 있어야 해요."]],"line_relations":["support","reply"],"chapters":MID_CHAPTERS,"rarity":"uncommon"},
    {"id":"053_mira_lyra_silence","speaker":"mira","target":"lyra","tag":"pair","category":"MOOD","family":"mira_lyra_silence","intent":"silence","action":"미라가 의료 차트를 정리하고 마렌은 화분의 마른 잎을 떼어 낸다. 둘은 한동안 서로에게 말을 걸지 않는다.","lines":[],"line_relations":[],"chapters":MID_CHAPTERS},

    {"id":"053_mira_sena_priority","speaker":"sena","target":"mira","tag":"pair","category":"CONFLICT","family":"mira_sena_priority","intent":"conflict","action":"경보가 울리자 세나가 출입문을 막고 미라는 안쪽 침상을 가리킨다.","lines":[["sena","위험부터 끊어."],["mira","안에 사람이 있어요."],["sena","내가 길 열게. 넌 사람 데리고 나와."],["mira","그럼 그렇게 해요."]],"line_relations":["anchor","challenge","proposal","agreement"],"chapters":MID_CHAPTERS},
    {"id":"053_mira_sena_bandage","speaker":"sena","target":"mira","tag":"pair","category":"DAILY","family":"mira_sena_bandage","intent":"humor","action":"미라는 세나가 또 가져가려는 붕대 상자를 한 칸 위로 옮긴다.","lines":[["sena","거기 둬도 닿아."],["mira","알아요. 다음엔 영수증 끊어 드리려고요."],["sena","그건 됐어."]],"line_relations":["anchor","tease","reply"],"chapters":MID_CHAPTERS},
    {"id":"053_mira_sena_isolation","speaker":"mira","target":"sena","tag":"pair","category":"RELATIONSHIP","family":"mira_sena_isolation","intent":"decision","action":"격리 결정 뒤 세나는 문 앞에 서 있고 미라는 포드의 생체 표시를 다시 확인한다.","lines":[["sena","결정은 끝났어."],["mira","결정이 끝나도 사람 상태는 안 끝나요."],["sena","…그래. 그건 네가 봐."]],"line_relations":["anchor","challenge","accept"],"chapters":LATE_CHAPTERS,"rarity":"uncommon"},

    {"id":"053_mira_rho_injury","speaker":"mira","target":"rho","tag":"pair","category":"DAILY","family":"mira_rho_injury","intent":"relationship","action":"준은 손등의 상처를 뒤로 숨기지만 미라는 이미 소독제를 꺼내고 있다.","lines":[["rho","이 정도는 긁힌 거야."],["mira","그 문장 세 번째 들었어요."],["rho","이번엔 진짜인데."],["mira","그 말도 두 번째예요."]],"line_relations":["anchor","reply","deflect","reply"],"chapters":MID_CHAPTERS},
    {"id":"053_mira_rho_device","speaker":"rho","target":"mira","tag":"pair","category":"WORK","family":"mira_rho_device","intent":"work","action":"준이 작은 의료 센서의 뒷판을 열자 미라는 환자용 예비기를 먼저 꺼낸다.","lines":[["mira","수리 끝날 때까지 이걸 쓸게요."],["rho","내가 금방 고쳐."],["mira","그래서 예비기를 ‘금방’ 쓰는 거예요."],["rho","…합리적이라 더 짜증 나네."]],"line_relations":["anchor","reply","clarify","accept"],"chapters":MID_CHAPTERS},
    {"id":"053_mira_rho_quiet","speaker":"rho","target":"mira","tag":"pair","category":"RELATIONSHIP","family":"mira_rho_quiet","intent":"care","action":"준의 농담이 멈춘 걸 본 미라는 상처 대신 먼저 경보 기록을 닫는다.","lines":[["mira","오늘은 안 웃네요."],["rho","웃을 타이밍이 아니잖아."],["mira","네. 그래서 물어본 거예요."]],"line_relations":["anchor","reply","clarify"],"chapters":MID_CHAPTERS,"rarity":"uncommon"},

    {"id":"053_mira_noa_privacy","speaker":"noa","target":"mira","tag":"pair","category":"CONFLICT","family":"mira_noa_privacy","intent":"conflict","action":"노아는 의료 기록의 빈칸을 가리키고 미라는 화면을 닫지 않는다.","lines":[["noa","이 시간대만 비어 있어요."],["mira","환자 개인 기록이에요."],["noa","사건과 관련 있을 수도 있어요."],["mira","그걸 확인하면 필요한 부분만 공개할게요."]],"line_relations":["anchor","reply","challenge","boundary"],"chapters":MID_CHAPTERS},
    {"id":"053_mira_noa_consent","speaker":"noa","target":"mira","tag":"pair","category":"RELATIONSHIP","family":"mira_noa_consent","intent":"work","action":"미라는 환자 이름을 가린 사본을 노아에게 건넨다.","lines":[["mira","이 정도면 시간은 확인할 수 있어요."],["noa","이름은 없어도 돼요. 지금 필요한 건 순서니까."],["mira","그럼 원본은 제가 보관할게요."]],"line_relations":["proposal","accept","resolution"],"chapters":MID_CHAPTERS},
    {"id":"053_mira_noa_memory","speaker":"noa","target":"mira","tag":"pair","category":"MYSTERY","family":"mira_noa_memory","intent":"record","action":"노아는 미라가 기억하는 귀환 날짜와 실제 의료 재고 정리 날짜를 나란히 적는다.","lines":[["noa","날짜는 같아요."],["mira","그래서 더 진짜처럼 느껴져요."],["noa","느낌은 기록하지 않을게요. 날짜는 남길게요."]],"line_relations":["anchor","reply","boundary"],"chapters":["DEAD_AIR","ECHO_WARD","SILENT_ORBIT"],"rarity":"uncommon"},

    {"id":"053_mira_dax_probability","speaker":"dax","target":"mira","tag":"pair","category":"CONFLICT","family":"mira_dax_probability","intent":"decision","action":"다렌의 생존 확률표와 미라의 치료 우선순위가 한 사람에서 갈린다.","lines":[["dax","자원을 여기 쓰면 전체 생존율이 내려가."],["mira","그 사람은 지금 치료하면 살 수 있어요."],["dax","알아. 그래서 계산이 어려운 거야."],["mira","저도 알아요. 그래도 제 판단은 이쪽이에요."]],"line_relations":["anchor","challenge","acknowledge","decision"],"chapters":LATE_CHAPTERS},
    {"id":"053_mira_dax_body","speaker":"dax","target":"mira","tag":"pair","category":"MYSTERY","family":"mira_dax_body","intent":"mystery","action":"미라는 19년 전 기록 옆에 현재 신체 수치를 놓고 다렌에게 화면을 돌린다.","lines":[["mira","기록이 맞다면 몸이 안 맞아요."],["dax","몸이 맞다면 기록이 안 맞고."],["mira","둘 다 맞을 가능성은요?"],["dax","그걸 계산하려면 가정부터 바꿔야 해."]],"line_relations":["anchor","support","question","reply"],"chapters":["SILENT_ORBIT","LAST_LIGHT"]},
    {"id":"053_mira_dax_rest","speaker":"dax","target":"mira","tag":"pair","category":"DAILY","family":"mira_dax_rest","intent":"care","action":"다렌은 미라의 마지막 검사 시간이 비어 있는 걸 보고 계산표 맨 아래에 한 줄을 추가한다.","lines":[["dax","네 검사 시간은?"],["mira","다 끝나고 할게요."],["dax","그 답은 입력값이 아니야. 시간을 줘."],["mira","…20분 뒤요."]],"line_relations":["question","deflect","challenge","answer"],"chapters":MID_CHAPTERS},

    {"id":"053_mira_vale_sleep","speaker":"mira","target":"vale","tag":"pair","category":"MEDICAL","family":"mira_vale_sleep","intent":"care","action":"미라는 소렌의 헤드셋보다 눈 밑의 피로부터 본다.","lines":[["mira","몇 시간 잤어요?"],["vale","신호가 다시 와서요."],["mira","그건 수면 시간이 아니에요."],["vale","…세 시간쯤이요."]],"line_relations":["question","deflect","clarify","answer"],"chapters":MID_CHAPTERS},
    {"id":"053_mira_vale_silence","speaker":"vale","target":"mira","tag":"pair","category":"RELATIONSHIP","family":"mira_vale_silence","intent":"support","action":"소렌은 설명할 말을 찾지 못하고 헤드셋만 내려놓는다. 미라는 질문하지 않고 물컵을 가까이 둔다.","lines":[["vale","지금은 설명 못 하겠어요."],["mira","네. 그럼 지금은 안 해도 돼요."]],"line_relations":["boundary","accept"],"chapters":MID_CHAPTERS},

    {"id":"053_mira_eli_no_words","speaker":"mira","target":"eli","tag":"pair","category":"RELATIONSHIP","family":"mira_eli_no_words","intent":"care","action":"루칸은 아무 말 없이 출구 방향을 두 번 확인한다. 미라는 이유를 캐묻지 않고 맥박 센서만 건넨다.","lines":[["eli","말 안 해도 돼?"],["mira","네. 대신 이건 해요."]],"line_relations":["question","reply"],"chapters":MID_CHAPTERS},
    {"id":"053_mira_eli_route","speaker":"eli","target":"mira","tag":"pair","category":"WORK","family":"mira_eli_route","intent":"work","action":"루칸은 의료실까지 가장 짧은 길이 아니라 흔들림이 적은 경로를 표시한다.","lines":[["mira","더 멀어요."],["eli","환자 데리고 가면 이쪽이 덜 흔들려."],["mira","그럼 이걸 응급 경로로 남겨요."]],"line_relations":["challenge","explain","accept"],"chapters":MID_CHAPTERS},

    {"id":"053_pair_rho_sena_vote","speaker":"rho","target":"sena","tag":"pair","category":"RELATIONSHIP","family":"rho_sena_vote_memory","intent":"decision","action":"준은 전날 세나가 자신을 찍은 표를 보고도 공구함을 그녀 쪽으로 밀어 둔다.","lines":[["sena","어제는 어제야."],["rho","그래. 오늘 볼트는 오늘 조여야 하고."],["sena","끝나고 다시 얘기해."]],"line_relations":["anchor","accept","followup"],"chapters":LATE_CHAPTERS},
    {"id":"053_pair_noa_dax_changed","speaker":"noa","target":"dax","tag":"pair","category":"MYSTERY","family":"noa_dax_changed_question","intent":"record","action":"노아는 이미 답했다고 표시한 질문 옆에 다시 열린 표시를 붙인다.","lines":[["dax","끝난 질문 아니었어?"],["noa","이번 기록에서는 아니에요."],["dax","그럼 답을 지우진 마. 바뀐 걸 남겨."]],"line_relations":["question","reply","instruction"],"chapters":LATE_CHAPTERS},
    {"id":"053_pair_vale_eli_overheard","speaker":"vale","target":"eli","tag":"pair","category":"PAIR","family":"vale_eli_overheard","intent":"overheard","action":"통신실 문이 열리기 전 두 사람 목소리가 먼저 들린다.","lines":[["eli","그 좌표는 어제 없었어."],["vale","좌표는 없었는데 소리는 있었어요."],["eli","그럼 내가 놓친 건 위치가 아니라 시간인가."]],"line_relations":["anchor","clarify","inference"],"chapters":MID_CHAPTERS,"overheard":true,"interrupt_options":true},
    {"id":"053_trio_mira_rho_sena","speaker":"mira","tag":"trio","participants":["mira","rho","sena"],"category":"CRISIS","family":"trio_mira_rho_sena","intent":"crisis","action":"준이 손을 다친 채 패널을 잡고 있고 세나는 경보 구역을 비우려 한다. 미라가 둘 사이에 선다.","lines":[["sena","준, 나와."],["rho","30초면 돼."],["mira","둘 다 맞아요. 준은 손부터 내밀고, 세나는 30초만 줘요."],["sena","30초."],["rho","충분해."]],"line_relations":["anchor","challenge","mediate","accept","accept"],"chapters":MID_CHAPTERS},
    {"id":"053_trio_mira_noa_dax","speaker":"noa","tag":"trio","participants":["mira","noa","dax"],"category":"MYSTERY","family":"trio_mira_noa_dax","intent":"mystery","action":"노아의 시간표, 다렌의 시스템 로그, 미라의 신체 기록이 같은 19년을 서로 다르게 말한다.","lines":[["noa","도착 기록은 완료됐어요."],["dax","시스템 경과 시간도 맞아."],["mira","그럼 사람 몸은 왜 안 맞죠?"],["dax","그 질문 때문에 앞의 둘도 다시 봐야 해."]],"line_relations":["anchor","support","challenge","inference"],"chapters":["SILENT_ORBIT","LAST_LIGHT"]},
    {"id":"053_trio_mira_lyra_dax","speaker":"lyra","tag":"trio","participants":["mira","lyra","dax"],"category":"DECISION","family":"trio_survival_priority","intent":"decision","action":"생태실 산소와 의료실 산소 요구량이 동시에 한계선을 넘는다.","lines":[["lyra","내일을 살리려면 생태실을 유지해야 해요."],["mira","오늘 밤 환자도 살려야 해요."],["dax","둘 다 전량은 불가능해. 시간으로 나누자."],["lyra","두 시간씩."],["mira","환자 상태 보고 다시 조정해요."]],"line_relations":["anchor","challenge","proposal","accept","condition"],"chapters":["RED_SHIFT","LAST_LIGHT"]}
]

static func _scene_from_pack(npc_id: String, index: int, pack: Array, prefix: String) -> Dictionary:
    var meta: Dictionary = pack[6] if pack.size() > 6 and pack[6] is Dictionary else {}
    var line := str(pack[5])
    var scene := {
        "id":"053_%s_%s_%02d" % [prefix,npc_id,index],
        "speaker":npc_id,
        "mira_group":str(pack[0]) if npc_id == "mira" else "",
        "tag":str(pack[1]),
        "category":str(pack[2]),
        "family":str(pack[3]),
        "intent":str(meta.get("intent",pack[1])),
        "action":str(pack[4]),
        "lines":[] if line == "" else [[npc_id,line]],
        "choices":Array(meta.get("choices",[])).duplicate(true),
        "chapters":Array(meta.get("chapters",MID_CHAPTERS)).duplicate()
    }
    for key in ["requires","forbids","rarity","deviation_reason","source_event","possible_followup",
        "player_specific","agency","tone_lines","tone_actions","role_lines","knowledge_share","promise","target"]:
        if meta.has(key):
            scene[key] = meta[key]
    return scene

static func scenes() -> Array:
    var result: Array = []
    for index in range(MIRA_PACKS.size()):
        result.append(_scene_from_pack("mira",index,MIRA_PACKS[index],"mira"))
    for npc_id in CREW_PACKS:
        var packs: Array = CREW_PACKS[npc_id]
        for index in range(packs.size()):
            result.append(_scene_from_pack(str(npc_id),index,packs[index],"crew"))
    for scene in SOCIAL_SCENES:
        result.append(Dictionary(scene).duplicate(true))
    return result

static func count_by_speaker() -> Dictionary:
    var result := {}
    for scene in scenes():
        var speaker := str(scene.get("speaker",""))
        result[speaker] = int(result.get(speaker,0)) + 1
    return result

static func mira_scenes() -> Array:
    return scenes().filter(func(scene): return str(scene.get("speaker","")) == "mira" or "mira" in scene.get("participants",[]))

static func mira_group_counts() -> Dictionary:
    var result := {}
    for scene in scenes():
        var group := str(scene.get("mira_group",""))
        if group != "":
            result[group] = int(result.get(group,0)) + 1
    return result

static func multi_line_scenes() -> Array:
    return scenes().filter(func(scene): return Array(scene.get("lines",[])).size() >= 2)
