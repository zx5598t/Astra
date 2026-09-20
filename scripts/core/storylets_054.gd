class_name AstraStorylets054
extends RefCounted

# ASTRA 0.5.4 — AFTERMATH
# 64 authored scenes: eight four-beat micro-arcs plus small routine,
# consequence and opinion-change scenes. The point is not volume; each new
# scene either reacts, changes what happens next, or makes a baseline legible.

const MID := ["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]
const LATE := ["SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]

const ARC_PACKS := {
    "mira":[
        [1,"routine","PERSONAL","mira_self_neglect","모두의 검사표는 채워져 있는데 미라 이름 옆 칸만 비어 있다.","마지막 한 명 남았네요. 저니까 나중에 해도 돼요.",{}],
        [2,"player","PLAYER","mira_self_neglect","미라는 자기 센서를 다시 서랍에 넣으려 한다.","지금 꼭 해야 해요?",{"choices":[
            {"label":"센서를 미라에게 건넨다.","effect":"help","memory_tag":"054_mira_checked","consequences":[{"id":"mira-check-delay","timing":"DELAYED","followup_scene":"054_mira_self_neglect_3","delay":2}]},
            {"label":"마렌에게 대신 확인해 달라고 한다.","effect":"share","memory_tag":"054_mira_delegated","consequences":[{"id":"mira-check-day","timing":"NEXT_DAY","note":"마렌이 아침 배급 확인 전에 미라의 상태를 먼저 살폈다."}]},
            {"label":"지금은 미라 판단에 맡긴다.","effect":"wait","memory_tag":"054_mira_unresolved","consequences":[{"id":"mira-check-loop","timing":"NEXT_LOOP","memory_tag":"mira_self_neglect_echo","note":"다음 기록에서도 미라의 자기 검사 순서는 이상하게 늦다."}]}
        ]}],
        [3,"consequence","CONSEQUENCE","mira_self_neglect","약품 라벨을 읽던 미라가 같은 줄을 두 번 확인한다. 손이 느린 건 아니지만 평소보다 한 박자 늦다.","…잠깐. 이건 다시 볼게요.",{"deviation_reason":"RECOVERY","source_event":"self_neglect","possible_followup":"mira_self_neglect_resolution"}],
        [4,"personal","RELATIONSHIP","mira_self_neglect","미라는 자기 검사표를 마지막 칸에 끼워 넣고 파일을 닫는다.","",{"tone_lines":{"WARM":"이번엔 제가 먼저 했어요. 확인해 볼래요?","PROFESSIONAL":"자기 검사까지 끝냈어요. 다음 기록 보죠.","STRAINED":"검사는 했어요. 그 문제로 더 다투진 말아요."}}]
    ],
    "rho":[
        [1,"routine","WORK","rho_mistake","준이 뜯어낸 패널 안쪽에 방향이 반대로 끼워진 작은 커넥터 하나가 보인다.","…이건 내가 했을 가능성이 높아.",{}],
        [2,"secret","PERSONAL","rho_mistake","준은 커넥터를 바로 고치지 않고 작업 기록부터 열어 놓는다.","지금 말하면 다들 이것부터 볼 거야. 먼저 원인을 볼까?",{"choices":[
            {"label":"수정 전 상태를 기록한다.","effect":"record","memory_tag":"054_rho_documented","consequences":[{"id":"rho-mistake-immediate","timing":"IMMEDIATE","note":"준의 실수와 사건 흔적을 분리해서 기록했다."}]},
            {"label":"준이 직접 말하게 둔다.","effect":"wait","memory_tag":"054_rho_owns_mistake","consequences":[{"id":"rho-mistake-day","timing":"NEXT_DAY","note":"준이 회의 전에 자기 실수를 먼저 작업 기록에 남겼다."}]},
            {"label":"회의 전에 공개하자고 한다.","effect":"share","memory_tag":"054_rho_public_mistake","consequences":[{"id":"rho-mistake-delay","timing":"DELAYED","followup_scene":"054_rho_mistake_3","delay":2}]}
        ]}],
        [3,"consequence","CONSEQUENCE","rho_mistake","준은 고친 커넥터 옆에 자기 이름과 시간을 적는다. 사건 흔적과 자기 실수의 위치를 따로 표시했다.","내 실수는 내 실수고, 누가 이 선을 끊은 건 다른 얘기야.",{}],
        [4,"personal","RELATIONSHIP","rho_mistake","작업이 끝난 뒤 준은 공구함을 닫지 않고 커넥터 하나를 위에 올려 둔다.","다음엔 숨기기 전에 사진부터 찍을게. 귀찮아도 그게 낫네.",{}]
    ],
    "dax":[
        [1,"routine","WORK","dax_failed_model","다렌의 계산표는 안전하다고 나오는데 실제 펌프 진동은 기준을 넘는다.","수치는 맞아. 그래서 모델 쪽이 틀렸을 가능성이 커.",{}],
        [2,"conflict","CONFLICT","dax_failed_model","다렌은 같은 식을 다시 계산하다가 손을 멈춘다.","준이 들었다는 진동값이 필요해. 내가 가진 입력만으로는 안 맞아.",{"choices":[
            {"label":"준의 현장값을 먼저 가져온다.","effect":"help","memory_tag":"054_dax_accepts_field","consequences":[{"id":"dax-model-delay","timing":"DELAYED","followup_scene":"054_dax_failed_model_3","delay":2}]},
            {"label":"노아의 원본 로그부터 대조한다.","effect":"record","memory_tag":"054_dax_accepts_record","consequences":[{"id":"dax-model-day","timing":"NEXT_DAY","note":"다렌은 다음 계산부터 원본 로그와 현장값을 같은 입력 표에 넣었다."}]}
        ]}],
        [3,"consequence","CONSEQUENCE","dax_failed_model","다렌은 자기 계산식 옆에 준의 진동값과 노아의 로그 시각을 같은 크기로 적는다.","내 식이 틀렸다는 뜻보다, 입력을 혼자 정하면 안 된다는 뜻에 가깝네.",{}],
        [4,"personal","RELATIONSHIP","dax_failed_model","검증이 끝난 표에서 다렌은 틀린 계산을 지우지 않는다.","남겨 둬. 다음에 맞는 답이 나와도 왜 틀렸는지는 필요하니까.",{}]
    ],
    "noa":[
        [1,"routine","MYSTERY","noa_private_copy","노아가 공식 보관함과 다른 위치에 같은 날짜의 사본 하나를 따로 두고 있다.","아직 원본인지 판단 못 했어요. 그래서 공개본에 섞지 않았어요.",{}],
        [2,"player","PLAYER","noa_private_copy","노아는 사본 봉인을 손으로 누른 채 당신의 대답을 기다린다.","어떻게 할까요?",{"choices":[
            {"label":"확인될 때까지 노아에게 맡긴다.","effect":"promise","memory_tag":"054_noa_trusted_copy","consequences":[{"id":"noa-copy-delay","timing":"DELAYED","followup_scene":"054_noa_private_copy_3","delay":3}]},
            {"label":"지금 모두에게 존재만 공개한다.","effect":"share","memory_tag":"054_noa_copy_exists_public","consequences":[{"id":"noa-copy-day","timing":"NEXT_DAY","note":"사본의 내용이 아니라 존재 사실만 회의 기록에 남았다."}]},
            {"label":"노아가 없는 동안 먼저 확인한다.","effect":"confront","memory_tag":"054_noa_copy_peeked","consequences":[{"id":"noa-copy-loop","timing":"NEXT_LOOP","memory_tag":"noa_boundary_echo","note":"다음 기록에서 노아는 개인 사본을 예전보다 늦게 꺼낸다."}]}
        ]}],
        [3,"consequence","CONSEQUENCE","noa_private_copy","노아는 사본의 문장보다 누가 언제 만졌는지를 먼저 기록해 당신에게 건넨다.","내용은 아직 보류할게요. 대신 경로는 같이 보죠.",{}],
        [4,"personal","RELATIONSHIP","noa_private_copy","확인이 끝난 뒤 노아는 사본을 공식 기록 옆에 두되 다른 색 표식을 붙인다.","같은 기록이라고 부르기엔 아직 모르는 게 많아요.",{}]
    ],
    "sena":[
        [1,"routine","CONFLICT","sena_overprotection","세나는 위험 구역 앞에 임시 차단선을 하나 더 쳐 두었다. 원래 절차보다 한 단계 강하다.","오늘은 여기 안 들어가는 게 맞아.",{}],
        [2,"player","PLAYER","sena_overprotection","세나는 출입카드를 내리지 않은 채 당신을 본다.","그래도 들어갈 거야?",{"choices":[
            {"label":"세나 판단을 따르고 다른 경로를 찾는다.","effect":"wait","memory_tag":"054_sena_obeyed","consequences":[{"id":"sena-safe-delay","timing":"DELAYED","followup_scene":"054_sena_overprotection_3","delay":2}]},
            {"label":"위험을 감수하고 직접 확인한다.","effect":"confront","memory_tag":"054_sena_ignored","consequences":[{"id":"sena-risk-immediate","timing":"IMMEDIATE","note":"세나는 당신을 혼자 보내지 않고 뒤에서 차단 스위치를 잡는다."},{"id":"sena-risk-loop","timing":"NEXT_LOOP","memory_tag":"sena_protection_conflict_echo","note":"다음 기록에서 세나는 당신의 위험 판단을 한 번 더 확인한다."}]}
        ]}],
        [3,"consequence","CONSEQUENCE","sena_overprotection","세나는 차단선을 절반만 걷고 안전 표식을 남긴다.","막는 것만 답은 아니지. 대신 들어갈 사람은 알고 들어가야 해.",{}],
        [4,"personal","RELATIONSHIP","sena_overprotection","순찰표 끝에 세나는 ‘진입 금지’ 대신 ‘동행 확인’이라고 고쳐 쓴다.","다음엔 혼자 결정 안 할게. 너도 그러지 마.",{}]
    ],
    "vale":[
        [1,"routine","PERSONAL","vale_listening_fatigue","소렌은 같은 구간을 네 번째 재생한다. 파형보다 눈을 감고 있는 시간이 길다.","한 번만 더 들으면 구분될 것 같아요.",{}],
        [2,"player","PLAYER","vale_listening_fatigue","헤드셋을 다시 쓰려는 소렌의 손이 아주 조금 늦다.","계속할까요?",{"choices":[
            {"label":"지금은 귀를 쉬게 한다.","effect":"wait","memory_tag":"054_vale_rest","consequences":[{"id":"vale-rest-delay","timing":"DELAYED","followup_scene":"054_vale_listening_fatigue_3","delay":2}]},
            {"label":"이번 한 번만 더 같이 듣는다.","effect":"record","memory_tag":"054_vale_continue","consequences":[{"id":"vale-listen-immediate","timing":"IMMEDIATE","note":"둘이 같은 구간을 들어 소렌 혼자만의 착청인지 먼저 분리했다."},{"id":"vale-listen-day","timing":"NEXT_DAY","note":"소렌은 다음 신호 분석 전에 청각 휴식 시간을 먼저 기록했다."}]}
        ]}],
        [3,"consequence","CONSEQUENCE","vale_listening_fatigue","소렌은 헤드셋 대신 스피커를 아주 작게 켜고 루칸의 좌표표를 옆에 둔다.","소리만 들으면 계속 안으로 들어가요. 이번엔 위치랑 같이 볼게요.",{}],
        [4,"personal","RELATIONSHIP","vale_listening_fatigue","분석을 마친 소렌은 재생 목록 맨 위에 빈 파일 하나를 넣어 둔다.","아무것도 안 듣는 구간도 기록해 두려고요.",{}]
    ],
    "eli":[
        [1,"routine","WORK","eli_risk_route","루칸은 목적지까지 두 경로를 겹쳐 놓았다. 짧은 길은 진동 구역을 지나고, 긴 길은 산소를 더 쓴다.","둘 다 안전하다고 말할 순 없어.",{}],
        [2,"player","PLAYER","eli_risk_route","루칸은 어느 쪽에도 선택 표시를 하지 않는다.","무엇을 아낄지 정해야 해.",{"choices":[
            {"label":"긴 안정 경로를 택한다.","effect":"protect","memory_tag":"054_eli_stable_route","consequences":[{"id":"eli-route-day","timing":"NEXT_DAY","note":"이동은 늦어졌지만 환자와 장비의 진동 기록은 안정적이었다."}]},
            {"label":"짧은 위험 경로를 택한다.","effect":"confront","memory_tag":"054_eli_risk_route","consequences":[{"id":"eli-route-delay","timing":"DELAYED","followup_scene":"054_eli_risk_route_3","delay":2}]},
            {"label":"결정을 루칸에게 맡긴다.","effect":"wait","memory_tag":"054_eli_owns_route","consequences":[{"id":"eli-route-loop","timing":"NEXT_LOOP","memory_tag":"lucan_route_responsibility_echo","note":"다음 기록에서 루칸은 경로 선택 이유를 더 먼저 설명한다."}]}
        ]}],
        [3,"consequence","CONSEQUENCE","eli_risk_route","루칸은 선택한 경로의 손해를 결과표 맨 위에 먼저 적는다.","맞았는지보다 뭘 잃었는지부터 남겨야 해.",{}],
        [4,"personal","RELATIONSHIP","eli_risk_route","항로가 끝난 뒤에도 루칸은 선택하지 않은 경로를 지우지 않는다.","다른 쪽이 틀렸던 건 아니니까.",{}]
    ],
    "lyra":[
        [1,"routine","PERSONAL","lyra_save_sample","폐기 상자 위에 있어야 할 작은 표본 하나가 마렌의 작업대 안쪽에 남아 있다.","이건 아직 버리고 싶지 않아요. 하루만 더 보면 안 될까요?",{}],
        [2,"player","PLAYER","lyra_save_sample","마렌은 표본 옆에 줄어드는 냉각 자원 수치를 함께 띄운다.","살릴 이유도, 버릴 이유도 있어요.",{"choices":[
            {"label":"하루 더 보존한다.","effect":"protect","memory_tag":"054_lyra_saved_sample","consequences":[{"id":"lyra-sample-day","timing":"NEXT_DAY","note":"보존한 표본이 생태 수치를 하나 더 보여 줬지만 냉각 자원을 더 사용했다."},{"id":"lyra-sample-delay","timing":"DELAYED","followup_scene":"054_lyra_save_sample_3","delay":3}]},
            {"label":"지금 폐기한다.","effect":"procedure","memory_tag":"054_lyra_discarded_sample","consequences":[{"id":"lyra-discard-immediate","timing":"IMMEDIATE","note":"자원 부담은 사라졌지만 표본에서 더 얻을 정보도 함께 포기했다."}]}
        ]}],
        [3,"consequence","CONSEQUENCE","lyra_save_sample","마렌은 표본의 변화와 소비한 냉각량을 같은 칸에 적는다.","단서가 됐다고 해서 공짜였던 건 아니에요.",{}],
        [4,"personal","RELATIONSHIP","lyra_save_sample","마렌은 빈 표본 상자를 버리지 않고 날짜만 남겨 둔다.","다음에는 살릴지 말지보다, 무엇을 포기하는지 먼저 적을래요.",{}]
    ]
}

# Four extra scenes each, plus extra depth for Soren/Lucan.
const EXTRA_PACKS := {
    "mira":[
        ["routine","DAILY","mira_routine_break","빈 의자와 펼쳐진 차트만 의료실에 남아 있다. 잠시 뒤 통신실 쪽에서 미라가 돌아온다.","소렌이 너무 오래 듣고 있었어요. 확인만 하고 왔어요.",{"routine_relevance":"CHECKING_CREW"}],
        ["reaction","RELATIONSHIP","mira_people_request","미라는 새 기록을 들고 왔지만 바로 내밀지 않고 당신이 하던 대화를 끝낼 때까지 기다린다.","사람부터 볼 거라고 생각했어요. 이건 끝나면 같이 봐요.",{"requires":{"player_axis":"people_first"}}],
        ["work","WORK","mira_medical_delegate","미라는 준에게 센서 수리를 맡기고 자신은 환자 기록을 계속 본다.","고치는 사람 따로, 보는 사람 따로면 둘 다 덜 놓쳐요.",{}],
        ["opinion","RELATIONSHIP","mira_opinion_softens","미라는 앞서 경계하던 사람의 새 검사표를 확인한 뒤 질문 수를 줄인다.","이 부분은 설명이 맞아요. 다른 문제와 섞지 않을게요.",{"opinion_change":{"reason":"new_evidence"}}]
    ],
    "rho":[
        ["routine","DAILY","rho_tool_return","준은 빌려 준 공구가 돌아오자 숫자를 세지 않고 빠진 자리만 손으로 확인한다.","됐어. 자리가 맞으면 다 온 거야.",{}],
        ["reaction","RELATIONSHIP","rho_evidence_first","준은 작동 중인 장비보다 먼저 오류 로그를 당신 쪽으로 돌린다.","너 어차피 이거부터 볼 거잖아.",{"requires":{"player_axis":"evidence_first"}}],
        ["opinion","RELATIONSHIP","rho_opinion_change","준은 의심하던 사람의 수리 흔적을 직접 확인한 뒤 공구함을 닫는다.","적어도 이건 그 사람이 한 게 아니야. 내가 보면 알아.",{"opinion_change":{"reason":"new_evidence"}}]
    ],
    "dax":[
        ["routine","DAILY","dax_paper_break","다렌은 화면을 끄고 종이 한 장에 중간값만 다시 쓴다.","답보다 어디서 갈렸는지 보는 게 빠를 때가 있어.",{}],
        ["reaction","RELATIONSHIP","dax_skeptical_player","다렌은 재확인을 요청받자 같은 계산을 다른 순서로 보여 준다.","좋아. 의심할 거면 방법도 바꿔 보자.",{"requires":{"player_axis":"skeptical"}}],
        ["opinion","RELATIONSHIP","dax_opinion_change","다렌은 이전 판단 옆에 작은 화살표를 그어 다른 사람의 이름으로 옮긴다.","입력이 바뀌었으면 결론도 바뀌어야지.",{"opinion_change":{"reason":"new_evidence"}}]
    ],
    "noa":[
        ["routine","DAILY","noa_margin_note","노아는 원문에 손대지 않고 별도 종이에 수정 이유만 쓴다.","틀린 기록도 언제 틀렸는지는 남겨야 해요.",{}],
        ["reaction","RELATIONSHIP","noa_secretive_request","노아는 공개 전 사본을 당신에게 먼저 건넨다.","당장 퍼뜨리지 않는 사람한테 먼저 보여 줄 이유도 있어요.",{"requires":{"player_axis":"secretive"}}],
        ["opinion","RELATIONSHIP","noa_vote_recall","노아는 어제 표시했던 이름 위에 선을 긋고 새 근거를 옆에 적는다.","어제는 이 기록이 없었어요. 표가 바뀐 이유는 그거예요.",{"opinion_change":{"reason":"new_evidence"}}]
    ],
    "sena":[
        ["routine","DAILY","sena_food_break","세나는 순찰표를 접고 식판 앞에 정확히 다섯 분만 앉는다.","다 먹을 시간은 없고, 안 먹을 이유도 없지.",{}],
        ["reaction","RELATIONSHIP","sena_protective_player","세나는 다른 사람을 먼저 빼내는 선택을 보고 출구 하나를 더 열어 둔다.","그쪽 맡아. 뒤는 내가 볼게.",{"requires":{"player_axis":"protective"}}],
        ["opinion","RELATIONSHIP","sena_opinion_change","세나는 의심하던 사람의 출입 시간을 다시 본 뒤 차단 목록에서 이름 하나를 지운다.","이 시간은 맞네. 그럼 다른 쪽부터 보자.",{"opinion_change":{"reason":"new_evidence"}}]
    ],
    "vale":[
        ["routine","DAILY","vale_silent_rest","소렌은 헤드셋 없이 통신실에 앉아 있다. 빈 채널조차 꺼 둔 상태다.","지금은 아무것도 안 듣는 게 일인 것 같아요.",{}],
        ["pair","PAIR","vale_eli_direction","소렌이 신호 방향 하나만 말하자 루칸은 지도에서 두 경로를 지운다.","좌표는 아직 몰라도 방향은 줄일 수 있네요.",{"target":"eli"}],
        ["reaction","RELATIONSHIP","vale_patient_player","소렌은 재촉이 없자 파일을 다시 처음부터 틀지 않는다.","기다려 주면 같은 소리를 덜 의심하게 돼요.",{"requires":{"player_axis":"patient"}}],
        ["pair","PAIR","vale_noa_source","소렌은 노아에게 음성 내용보다 파일 생성 시각부터 보여 준다.","제가 들은 말보다 이 시간이 먼저 믿을 만해요.",{"target":"noa"}],
        ["observation","MOOD","vale_window_silence","통신실 밖을 나선 소렌은 기계음이 적은 복도에서 한동안 멈춰 선다.","조용한 데 오면 아까 소리가 더 선명해질 때가 있어요.",{}],
        ["opinion","RELATIONSHIP","vale_opinion_change","소렌은 이전에 의심하던 목소리와 다른 호흡 간격을 찾아 표시를 바꾼다.","같은 사람이라고 생각했는데… 이건 간격이 달라요.",{"opinion_change":{"reason":"new_evidence"}}]
    ],
    "eli":[
        ["routine","DAILY","eli_window_check","루칸은 항법 화면보다 창밖 별의 상대 위치를 먼저 확인한다.","화면이 틀려도 저쪽은 같이 틀리진 않으니까.",{}],
        ["pair","PAIR","eli_vale_silence","루칸은 소렌이 말없이 건넨 시간표를 받고 설명을 요구하지 않는다.","시간이면 충분해. 방향은 내가 볼게.",{"target":"vale"}],
        ["reaction","RELATIONSHIP","eli_protective_player","루칸은 사람을 먼저 빼내는 선택을 보고 가장 덜 흔들리는 경로를 표시한다.","빠른 길 말고 이쪽. 지금은 사람이 먼저잖아.",{"requires":{"player_axis":"protective"}}],
        ["pair","PAIR","eli_dax_risk","루칸은 연료 계산 옆에 실제 진동 구역을 손으로 그린다. 계산은 다렌이 맡았다.","숫자 안에 없는 길도 있어. 이 구간이 그래.",{"target":"dax"}],
        ["observation","MOOD","eli_exit_check","루칸은 대화에 끼지 않은 채 출구 두 곳을 직접 열었다 닫는다.","말보다 문이 먼저 확인될 때가 있어.",{}],
        ["opinion","RELATIONSHIP","eli_opinion_change","루칸은 이전에 피하던 경로의 새 측정값을 보고 선을 다시 연결한다.","조건이 바뀌었네. 그럼 이 길도 다시 후보야.",{"opinion_change":{"reason":"new_evidence"}}]
    ],
    "lyra":[
        ["routine","DAILY","lyra_leaf_sort","마렌은 마른 잎과 살아 있는 잎을 한 번에 버리지 않고 따로 나눈다.","죽은 부분이 있다고 전부 죽은 건 아니니까요.",{}],
        ["reaction","RELATIONSHIP","lyra_people_first","마렌은 배급표보다 먼저 사람 수를 다시 세고 당신에게 고개를 끄덕인다.","당신도 늘 사람부터 세네요.",{"requires":{"player_axis":"people_first"}}],
        ["work","WORK","lyra_resource_trade","마렌은 의료 산소와 생태 순환량을 같은 표에 놓는다.","한쪽만 살리면 결국 둘 다 오래 못 가요.",{}],
        ["opinion","RELATIONSHIP","lyra_opinion_change","마렌은 의심하던 사람의 표본 처리 기록을 다시 읽고 표시 색을 바꾼다.","숨긴 건 맞지만, 망가뜨리려고 한 건 아닌 것 같아요.",{"opinion_change":{"reason":"new_evidence"}}]
    ]
}

static func _scene_from_pack(who: String, pack: Array, arc: bool) -> Dictionary:
    if arc:
        var stage := int(pack[0])
        var tag := str(pack[1])
        var category := str(pack[2])
        var chain_id := str(pack[3])
        var meta: Dictionary = Dictionary(pack[6]).duplicate(true)
        var scene := {
            "id":"054_%s_%d" % [chain_id,stage],
            "speaker":who,"tag":tag,"category":category,
            "family":chain_id,"intent":"micro_arc",
            "action":str(pack[4]),"lines":[[who,str(pack[5])]] if str(pack[5]) != "" else [],
            "choices":Array(meta.get("choices",[])).duplicate(true),
            "chapters":Array(meta.get("chapters",MID)).duplicate(),
            "chain_id":chain_id,"stage":stage,"requires_stage":stage-1,"sets_stage":stage
        }
        for key in meta:
            if key != "choices" and key != "chapters":
                scene[key] = meta[key]
        return scene
    var meta: Dictionary = Dictionary(pack[4]).duplicate(true)
    var scene := {
        "id":"054_%s_%s" % [who,str(pack[2])],
        "speaker":who,"tag":str(pack[0]),"category":str(pack[1]),
        "family":str(pack[2]),"intent":"routine_reaction",
        "action":str(pack[3]),"lines":[[who,str(pack[4].get("line",""))]] if pack[4].has("line") and str(pack[4]["line"]) != "" else [],
        "choices":Array(meta.get("choices",[])).duplicate(true),
        "chapters":Array(meta.get("chapters",MID)).duplicate()
    }
    # EXTRA_PACKS store spoken line as element 4? Support the compact six-item form below.
    return scene

static func _extra_scene(who: String, pack: Array) -> Dictionary:
    var meta: Dictionary = Dictionary(pack[5]).duplicate(true)
    var scene := {
        "id":"054_%s_%s" % [who,str(pack[2])],
        "speaker":who,"tag":str(pack[0]),"category":str(pack[1]),
        "family":str(pack[2]),"intent":"routine_reaction",
        "action":str(pack[3]),"lines":[[who,str(pack[4])]] if str(pack[4]) != "" else [],
        "choices":Array(meta.get("choices",[])).duplicate(true),
        "chapters":Array(meta.get("chapters",MID)).duplicate()
    }
    for key in meta:
        if key != "choices" and key != "chapters":
            scene[key] = meta[key]
    return scene

static func scenes() -> Array:
    var result: Array = []
    for who in ARC_PACKS:
        for pack in ARC_PACKS[who]:
            result.append(_scene_from_pack(str(who),pack,true))
    for who in EXTRA_PACKS:
        for pack in EXTRA_PACKS[who]:
            result.append(_extra_scene(str(who),pack))
    return result

static func arc_ids() -> Array:
    var result: Array = []
    for who in ARC_PACKS:
        result.append(str(ARC_PACKS[who][0][3]))
    return result

static func arc_actor(chain_id: String) -> String:
    for who in ARC_PACKS:
        if str(ARC_PACKS[who][0][3]) == chain_id:
            return str(who)
    return ""

static func select_arcs(seed_value: int, loop_index: int, chapter: String, roster: Array, recent: Array, max_count: int = 3, pity: Dictionary = {}) -> Array:
    if chapter in ["CALIBRATION","DEAD_AIR","GLASS_GARDEN"]:
        return []
    var candidates: Array = []
    for chain_id in arc_ids():
        var actor := arc_actor(str(chain_id))
        if actor in roster:
            candidates.append(str(chain_id))
    candidates.sort_custom(func(a,b):
        var a_pity := int(pity.get(str(a),0))
        var b_pity := int(pity.get(str(b),0))
        if a_pity != b_pity:
            return a_pity > b_pity
        var ap := 1 if str(a) in recent else 0
        var bp := 1 if str(b) in recent else 0
        if ap != bp:
            return ap < bp
        return abs(hash("%d:%d:%s" % [seed_value,loop_index,str(a)])) < abs(hash("%d:%d:%s" % [seed_value,loop_index,str(b)]))
    )
    var wanted := 1 + posmod(abs(hash("%d:%d:%s" % [seed_value,loop_index,chapter])),3)
    wanted = mini(wanted,max_count)
    return candidates.slice(0,mini(wanted,candidates.size()))

static func speaker_counts() -> Dictionary:
    var result := {}
    for scene in scenes():
        var who := str(scene.get("speaker",""))
        result[who] = int(result.get(who,0)) + 1
    return result

static func micro_arc_count() -> int:
    return arc_ids().size()


static func update_arc_pity(previous: Dictionary, roster: Array, selected: Array) -> Dictionary:
    var result := previous.duplicate(true)
    for chain_id in arc_ids():
        var id := str(chain_id)
        if arc_actor(id) not in roster:
            continue
        if id in selected:
            result[id] = 0
        else:
            result[id] = mini(6,int(result.get(id,0)) + 1)
    return result
