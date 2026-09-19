class_name AstraDialogue
extends RefCounted

# Rule-based lines, written per character so every crew member keeps a
# distinct voice (speech register, rhythm, what they notice).
# Tokens: {key} or {key|particle} -> see AstraJosa.fill.

const REASONS := {
    "slip": "공개되지 않은 실행 시각을 알고 있었던 점",
    "disputed": "진술이 목격자 증언과 어긋난 점",
    "log": "출입 기록과 진술이 맞지 않는 점",
    "clue2": "공개된 단서 두 개에 모두 이름이 걸린 점",
    "clue": "공개된 단서 명단에 이름이 오른 점",
    "victim": "어젯밤 쓰러진 사람이 가장 의심하던 상대라는 점",
    "accused": "탐사요원이 근거를 들어 지목한 점",
    "alone": "알리바이를 증명해 줄 사람이 없는 점",
    "friction": "회의 내내 말이 계속 엇나간 점",
    "gut": "설명하기 어려운 위화감"
}

const LIAR_TELLS := [
    "{name}의 시선이 잠깐 옆으로 비껴갔다.",
    "{name|i} 대답하기 직전, 아주 짧게 숨을 멈췄다.",
    "{name}의 손끝이 소매 끝을 만지작거린다.",
    "대답이 조금 빨랐다. 미리 준비해 둔 문장처럼.",
    "{name|i} 같은 단어를 두 번 반복했다."
]

const NERVOUS_TELLS := [
    "{name}의 목소리가 조금 떨린다. 긴장한 것 같다.",
    "{name|i} 마른침을 삼킨다. 겁을 먹은 듯하다."
]

const LINES := {
    "mira": {
        "alibi_alone": [
            "{pos}에 있었어요. 혼자라서 목격자는 없어요. 기록을 같이 볼까요?"
        ],
        "alibi_with": [
            "{pos}에 있었어요. {mates|wa} 함께였고요. 그쪽에도 물어봐요."
        ],
        "witness_none": [
            "지나가는 사람은 못 봤어요. 소리만으로 이름을 말할 수는 없고요."
        ],
        "witness_some": [
            "{mates|eul} 봤어요. 그건 확실해요."
        ],
        "sighting": [
            "{time}쯤 {room} 쪽에서 {group} 차림의 인물을 봤어요. 얼굴은 못 봤고요."
        ],
        "evidence_self_crew": [
            "제 이름도 있네요. 그 시간에는 {pos}에 있었어요. 그 기록까지 같이 봐요."
        ],
        "evidence_self_null": [
            "이 명단에 제가 있어요. 다른 사람이 있다는 것도 같이 확인해 주세요."
        ],
        "evidence_other": [
            "{members}에게 해당되는군요. 동선과 겹치는지 확인해요."
        ],
        "evidence_context": [
            "사람보다 상태를 알려 주는 기록이에요. 다른 흔적의 시간을 잡는 데 쓰죠."
        ],
        "evidence_log_ok": [
            "제가 말한 {room}이네요. 그 구간은 확인됐어요."
        ],
        "evidence_log_bad": [
            "시간을 다시 볼게요. 제가 말한 것과 다르네요."
        ],
        "evidence_log_other": [
            "기록에도 오류는 있을 수 있어요. 진술과 먼저 대조해요."
        ],
        "suspect_none": [
            "아직 이름을 꺼내기는 어려워요."
        ],
        "suspect_some": [
            "{target|i} 마음에 걸려요. {reason|eun} 확인해야 해요."
        ],
        "contra_confess": [
            "네. 그 부분은 거짓말했어요."
        ],
        "contra_hold": [
            "아직은 말하기 어려워요. 이 사건과는 별개예요."
        ],
        "contra_deny": [
            "이 기록이 정확한지부터 확인해요. 확인하고 다시 말할게요."
        ],
        "contra_honest": [
            "저는 {pos}에 있었어요. 그 말은 바뀌지 않아요."
        ],
        "slip": [
            "{time}에 그게 실행됐을 때는 이미… 잠깐, 방금 말은."
        ],
        "reassure_warm": [
            "잠깐만 앉을게요. 곁에 있어 줘요."
        ],
        "reassure_flat": [
            "마음은 알아요. 지금은 기록부터 볼게요."
        ],
        "pressure_crew": [
            "지금은 목소리를 낮춰요. 제가 아는 것부터 말할게요."
        ],
        "pressure_null": [
            "같은 질문을 반복해도 없는 기억이 생기진 않아요."
        ],
        "confide": [
            "여기서만 말할게요. {target|eul} 보고 있어요. {reason|i} 남았어요."
        ],
        "refuse": [
            "그 얘기는 지금 하기 어렵네요."
        ],
        "m_alibi_alone": [
            "그 시간에는 {pos}에 혼자 있었어요."
        ],
        "m_alibi_with": [
            "저는 {mates|wa} {pos}에 있었어요."
        ],
        "m_dispute_absent": [
            "저도 그때 {pos}에 있었어요. 그런데 {target|eul} 보지는 못했어요."
        ],
        "m_dispute_companion": [
            "{target}, 저와 함께 있었다고요? 그 시각에 같이 있지는 않았어요."
        ],
        "m_suspect": [
            "{target|eul} 다시 확인해요. {reason|i} 아직 남아 있어요."
        ],
        "m_react_accused_crew": [
            "제 얘기부터 들어요. 기록을 같이 펼칠게요."
        ],
        "m_react_accused_null": [
            "기록 한 장으로 여기까지 정해도 될까요?"
        ],
        "m_agree": [
            "저도 그 부분은 확인해야 한다고 생각해요. {target}, 들어 볼게요."
        ],
        "m_doubt": [
            "그 결론까지는 아직 멀어요. 다음 기록도 봐요."
        ],
        "m_defend_agree": [
            "{target|eul} 지금 격리할 근거는 부족해요."
        ],
        "m_clue_self": [
            "제 이름도 있어요. 제 동선까지 함께 확인해요."
        ],
        "m_mourn": [
            "{victim}의 빈자리는 당분간 그대로 둘게요."
        ],
        "m_vote": [
            "{target|eul} 잠시 격리해야겠어요. 다시 확인할 때까지요."
        ],
        "m_secret": [
            "제가 숨긴 건 그 일이에요. 다른 기록도 확인해도 돼요."
        ]
    },
    "rho": {
        "alibi_alone": [
            "{pos}. 혼자 작업했어. 끝나고 손 씻을 틈도 없었고."
        ],
        "alibi_with": [
            "{pos}에서 {mates|wa} 있었어. 내 말만 듣지 말고 확인해 봐."
        ],
        "witness_none": [
            "못 봤어. 고개를 들었을 때는 아무도 없더라."
        ],
        "witness_some": [
            "{mates|eul} 봤어. 이름은 기억해."
        ],
        "sighting": [
            "{time}쯤 {room} 쪽이었어. {group} 차림. 얼굴까지는 못 봤어."
        ],
        "evidence_self_crew": [
            "내 것도 있네. 그때 난 {pos}에 있었어. 시간부터 맞춰 보자."
        ],
        "evidence_self_null": [
            "내 이름만 있는 건 아니잖아. 다음 기록도 보자."
        ],
        "evidence_other": [
            "{members}. 이 사람들이 어디 있었는지도 보자."
        ],
        "evidence_context": [
            "누구 건지는 안 나오네. 그래도 어떤 순서였는지는 보인다."
        ],
        "evidence_log_ok": [
            "{room}, 맞지? 거기 있었어."
        ],
        "evidence_log_bad": [
            "어? 잠깐. 이 시간이 맞아?"
        ],
        "evidence_log_other": [
            "출입 기록부터 맞춰 보자. 누가 빠졌는지도."
        ],
        "suspect_none": [
            "아직 모르겠어. 찍고 싶지는 않아."
        ],
        "suspect_some": [
            "{target}. {reason|i} 계속 걸려."
        ],
        "contra_confess": [
            "맞아. 거짓말했어. 들어 봐 줄래?"
        ],
        "contra_hold": [
            "이건 다른 일이야. 조금만 기다려 줘."
        ],
        "contra_deny": [
            "센서가 틀린 건 아닌지 봐야 해. 나도 같이 볼게."
        ],
        "contra_honest": [
            "{pos}에 있었어. 그건 기억해."
        ],
        "slip": [
            "{time}에는 이미 끝났… 아, 아니. 잠깐만."
        ],
        "reassure_warm": [
            "응. 고마워. 나 지금 좀 정신없었네."
        ],
        "reassure_flat": [
            "달래는 건 나중에. 이거 마저 보자."
        ],
        "pressure_crew": [
            "잠깐. 한 번에 하나씩 물어봐."
        ],
        "pressure_null": [
            "계속 같은 걸 묻네. 다른 기록부터 보면 안 돼?"
        ],
        "confide": [
            "너한테 먼저 얘기할게. {target}. {reason|i} 계속 걸려."
        ],
        "refuse": [
            "지금은 좀. 나중에 다시 얘기하자."
        ],
        "m_alibi_alone": [
            "그땐 {pos}. 혼자였어."
        ],
        "m_alibi_with": [
            "{mates|wa} {pos}에 있었어."
        ],
        "m_dispute_absent": [
            "나도 {pos}에 있었는데 {target|eul} 못 봤어. 시간은 같은 거지?"
        ],
        "m_dispute_companion": [
            "{target}, 나랑? 그때 같이 있지 않았잖아."
        ],
        "m_suspect": [
            "{target}, {reason|eun} 어떻게 된 거야?"
        ],
        "m_react_accused_crew": [
            "나? 알았어. 어디부터 맞춰 볼까."
        ],
        "m_react_accused_null": [
            "그걸로 나라고 정한 거야? 다른 건?"
        ],
        "m_agree": [
            "나도 같은 게 걸렸어. {target}, 얘기해 봐."
        ],
        "m_doubt": [
            "잠깐, 한 칸 건너뛴 것 같은데."
        ],
        "m_defend_agree": [
            "{target|eul} 몰기엔 아직 빈칸이 많아."
        ],
        "m_clue_self": [
            "나도 해당되네. 내 동선도 띄워 줄게."
        ],
        "m_mourn": [
            "{victim} 몫까지 챙겼네. 그냥 둘게."
        ],
        "m_vote": [
            "{target|eul} 멈춰야 할 것 같아."
        ],
        "m_secret": [
            "맞아. 그게 내가 숨긴 일이야."
        ]
    },
    "dax": {
        "alibi_alone": [
            "{pos}에 혼자 있었어. 확인할 사람이 없으니 기록부터 보자."
        ],
        "alibi_with": [
            "{pos}에서 {mates|wa} 함께 있었어. 따로 들어도 돼."
        ],
        "witness_none": [
            "본 사람은 없어. 그 이상은 추측이야."
        ],
        "witness_some": [
            "{mates|eul} 확인했어."
        ],
        "sighting": [
            "{time}, {room} 쪽 통로였어. {group} 차림은 봤지만 누구인지는 몰라."
        ],
        "evidence_self_crew": [
            "나도 포함되는군. 그때는 {pos}에 있었어. 두 기록을 비교해 봐."
        ],
        "evidence_self_null": [
            "여기에는 여러 사람이 해당돼. 시간과 장소도 필요해."
        ],
        "evidence_other": [
            "{members}에게 남을 수 있는 흔적이군. 시간도 맞춰 봐야겠어."
        ],
        "evidence_context": [
            "이건 사건의 조건이야. 특정 사람의 증거와는 나눠서 보자."
        ],
        "evidence_log_ok": [
            "{room}에 남아 있군. 이 부분은 내 기억과 같아."
        ],
        "evidence_log_bad": [
            "내가 말한 위치와 다르군. 기록을 좀 더 보자."
        ],
        "evidence_log_other": [
            "한 기록만 믿지는 말자. 같은 시간의 진술이 있나?"
        ],
        "suspect_none": [
            "지금은 판단할 근거가 부족해."
        ],
        "suspect_some": [
            "{target|eul} 다시 확인하고 싶어. {reason|i} 설명되지 않았어."
        ],
        "contra_confess": [
            "그 부분은 사실이 아니었어. 지금 바로잡을게."
        ],
        "contra_hold": [
            "다른 사람이 걸린 일이야. 지금 여기서는 어렵겠어."
        ],
        "contra_deny": [
            "기록이 맞다면 내 기억이 틀린 거겠지. 아직은 모르겠어."
        ],
        "contra_honest": [
            "{pos}에 있었어. 다른 진술도 같이 확인하지."
        ],
        "slip": [
            "{time}에 실행됐으니… 그 시각은 아직 안 나왔나?"
        ],
        "reassure_warm": [
            "고맙군. 잠깐 쉬고 다시 보자."
        ],
        "reassure_flat": [
            "괜찮아. 확인할 일을 먼저 하지."
        ],
        "pressure_crew": [
            "목소리보다 근거가 필요해. 무엇이 달랐지?"
        ],
        "pressure_null": [
            "같은 답밖에 할 수 없어. 지금은."
        ],
        "confide": [
            "{target|eul} 확인 중이야. {reason|i} 있어서. 아직 공개할 단계는 아니고."
        ],
        "refuse": [
            "아직 공유하기는 어려워."
        ],
        "m_alibi_alone": [
            "나는 {pos}에 혼자 있었어."
        ],
        "m_alibi_with": [
            "{pos}에서 {mates|wa} 함께였어."
        ],
        "m_dispute_absent": [
            "같은 시각의 {pos}라면 내가 있었어. {target|eun} 못 봤고."
        ],
        "m_dispute_companion": [
            "{target}, 그 시각을 다시 보자. 나와 함께 있지는 않았어."
        ],
        "m_suspect": [
            "{target}, {reason|eul} 설명해 줄 수 있나?"
        ],
        "m_react_accused_crew": [
            "내 설명이 필요하겠군. 기록부터 보자."
        ],
        "m_react_accused_null": [
            "추론은 들었어. 아직 빠진 부분이 있어."
        ],
        "m_agree": [
            "그 지점은 맞아. {target}, 설명이 필요해."
        ],
        "m_doubt": [
            "중간 근거가 빠졌어. 다시 보자."
        ],
        "m_defend_agree": [
            "{target|eul} 가리킨다고 보기에는 부족해."
        ],
        "m_clue_self": [
            "내 이름도 포함돼. 그 시각의 기록을 보자."
        ],
        "m_mourn": [
            "{victim}의 화면은 꺼 두자. 기록은 남겨 두고."
        ],
        "m_vote": [
            "{target|eul} 격리하는 쪽에 표를 낼게."
        ],
        "m_secret": [
            "규정을 어긴 건 인정해. 사건과는 따로 확인해 줘."
        ]
    },
    "noa": {
        "alibi_alone": [
            "{pos}요. 같이 있던 사람은 없어요."
        ],
        "alibi_with": [
            "{pos}. {mates|wa} 같이 있었어요."
        ],
        "witness_none": [
            "목격한 사람은 없어요."
        ],
        "witness_some": [
            "{mates|eul} 봤어요. 적어 뒀고요."
        ],
        "sighting": [
            "{time}. {room} 쪽. {group} 차림이었어요."
        ],
        "evidence_self_crew": [
            "제 이름이 있어요. 제 동선은 {pos}예요."
        ],
        "evidence_self_null": [
            "저도 들어가네요. 이것만으로 정해진 건 아니죠."
        ],
        "evidence_other": [
            "{members}. 진술 옆에 놓아 볼게요."
        ],
        "evidence_context": [
            "시간을 맞출 수 있겠어요."
        ],
        "evidence_log_ok": [
            "{room}에 있어요. 제 말과 같아요."
        ],
        "evidence_log_bad": [
            "잠깐만요. 제 말하고 달라요."
        ],
        "evidence_log_other": [
            "말과 나란히 놓아 볼게요."
        ],
        "suspect_none": [
            "아직은요."
        ],
        "suspect_some": [
            "{target|i}요. {reason|i} 남았어요."
        ],
        "contra_confess": [
            "거짓말했어요. 이유가 있어요."
        ],
        "contra_hold": [
            "지금은 못 말해요."
        ],
        "contra_deny": [
            "기록하고 다르네요. 하지만 저는 그렇게 기억해요."
        ],
        "contra_honest": [
            "{pos}예요. 앞서 한 말과 같아요."
        ],
        "slip": [
            "{time}였어요. 아니, 시각은 아직."
        ],
        "reassure_warm": [
            "여기 있어 주세요."
        ],
        "reassure_flat": [
            "네. 그런데 이 줄부터요."
        ],
        "pressure_crew": [
            "질문을 하나씩 해 주세요."
        ],
        "pressure_null": [
            "이미 말했어요."
        ],
        "confide": [
            "{target|i}요. {reason|i} 있어요. 아직 메모에만 남겼어요."
        ],
        "refuse": [
            "지금은 안 할게요."
        ],
        "m_alibi_alone": [
            "{pos}에 혼자 있었어요."
        ],
        "m_alibi_with": [
            "{pos}. {mates|wa} 있었어요."
        ],
        "m_dispute_absent": [
            "{pos}에 있었어요. {target|eun} 없었고요."
        ],
        "m_dispute_companion": [
            "{target}, 저와 같이 있지 않았어요."
        ],
        "m_suspect": [
            "{target|i}요. {reason|i} 설명되지 않았어요."
        ],
        "m_react_accused_crew": [
            "네. 어느 문장인가요?"
        ],
        "m_react_accused_null": [
            "그 결론에는 동의 못 하겠어요."
        ],
        "m_agree": [
            "{target}, 저도 듣고 싶어요."
        ],
        "m_doubt": [
            "그건 아직 추측이에요."
        ],
        "m_defend_agree": [
            "{target|eul} 확정할 수는 없어요."
        ],
        "m_clue_self": [
            "저도 있어요. 확인해 주세요."
        ],
        "m_mourn": [
            "{victim}의 마지막 줄은 비워 뒀어요."
        ],
        "m_vote": [
            "{target|eul} 고를게요."
        ],
        "m_secret": [
            "그게 전부예요. 빠뜨린 말은 없어요."
        ]
    },
    "sena": {
        "alibi_alone": [
            "{pos}에 있었어. 나 혼자였고. 동선은 보여 줄게."
        ],
        "alibi_with": [
            "{mates|wa} {pos}에 있었어. 둘 다 기억할 거야."
        ],
        "witness_none": [
            "그쪽에서 사람은 못 봤어."
        ],
        "witness_some": [
            "{mates|eul} 봤어. 필요하면 같이 얘기하자."
        ],
        "sighting": [
            "{time}쯤 {room} 쪽으로 누가 지나갔어. {group} 차림이었고."
        ],
        "evidence_self_crew": [
            "맞아, 내 이름도 있어. 그 시간의 {pos} 기록은 확인했어?"
        ],
        "evidence_self_null": [
            "명단은 봤어. 그다음 근거가 뭔지 들을게."
        ],
        "evidence_other": [
            "{members}에게 물어보자. 한 사람씩."
        ],
        "evidence_context": [
            "어디부터 확인할지 정하는 데 쓰자."
        ],
        "evidence_log_ok": [
            "{room} 기록이네. 그때 거기 있었어."
        ],
        "evidence_log_bad": [
            "이건 설명해야겠네. 조금만 기다려."
        ],
        "evidence_log_other": [
            "어긋난 사람부터 확인하자."
        ],
        "suspect_none": [
            "누구라고 정하기는 일러."
        ],
        "suspect_some": [
            "{target|eul} 볼 거야. {reason|eul} 그냥 넘길 수는 없어."
        ],
        "contra_confess": [
            "맞아. 숨겼어. 설명할게."
        ],
        "contra_hold": [
            "이 자리에서 꺼낼 얘기는 아니야."
        ],
        "contra_deny": [
            "그 기억은 분명해. 기록 쪽도 확인하자."
        ],
        "contra_honest": [
            "{pos}에 있었어. 확인해도 좋아."
        ],
        "slip": [
            "{time}에 그쪽으로… 잠깐."
        ],
        "reassure_warm": [
            "그래. 조금만 숨 돌릴게."
        ],
        "reassure_flat": [
            "괜찮아. 문 쪽부터 확인하자."
        ],
        "pressure_crew": [
            "몰아붙이지 않아도 대답해. 뭘 확인하고 싶은데?"
        ],
        "pressure_null": [
            "내 얘기는 했어. 다른 쪽도 봐 줘."
        ],
        "confide": [
            "{target|eul} 살펴볼 거야. {reason|i} 마음에 걸려."
        ],
        "refuse": [
            "그건 조금 더 확인하고 말할게."
        ],
        "m_alibi_alone": [
            "{pos}에 나 혼자였어."
        ],
        "m_alibi_with": [
            "{mates|wa} {pos}에 있었어."
        ],
        "m_dispute_absent": [
            "잠깐. 나도 {pos}에 있었어. {target|eul} 본 적은 없어."
        ],
        "m_dispute_companion": [
            "{target}, 그건 아니야. 나랑 있지 않았어."
        ],
        "m_suspect": [
            "{target}, {reason|eul} 먼저 확인하자."
        ],
        "m_react_accused_crew": [
            "좋아. 내 기록도 똑같이 확인해."
        ],
        "m_react_accused_null": [
            "지금 정하기엔 부족해. 더 보자."
        ],
        "m_agree": [
            "{target}, 이번에는 대답해 줘."
        ],
        "m_doubt": [
            "그렇게 바로 정하지는 말자."
        ],
        "m_defend_agree": [
            "{target|eul} 몰아갈 단계는 아니야."
        ],
        "m_clue_self": [
            "내 것도 있네. 피하지 않을게."
        ],
        "m_mourn": [
            "{victim} 쪽은 내가 확인했어. 조금만 쉬었다 갈게."
        ],
        "m_vote": [
            "{target|eul} 격리하자. 더 다치기 전에."
        ],
        "m_secret": [
            "숨긴 건 인정해. 그 일까지 책임질게."
        ]
    },
    "vale": {
        "alibi_alone": [
            "{pos}에 혼자 있었어요."
        ],
        "alibi_with": [
            "{pos}에서 {mates|wa} 있었어요."
        ],
        "witness_none": [
            "아무도 못 봤어요."
        ],
        "witness_some": [
            "{mates|eul} 봤어요."
        ],
        "sighting": [
            "{time}쯤 {room} 쪽에서 봤어요. {group} 차림이었어요."
        ],
        "evidence_self_crew": [
            "저도 해당돼요. 그때는 {pos}에 있었어요."
        ],
        "evidence_self_null": [
            "다른 이름도 있어요. 그쪽은 확인했나요?"
        ],
        "evidence_other": [
            "{members}에게 해당해요."
        ],
        "evidence_context": [
            "여기에는 이름이 없네요."
        ],
        "evidence_log_ok": [
            "{room}이네요. 맞아요."
        ],
        "evidence_log_bad": [
            "그 시간에요? 다시 들여다볼게요."
        ],
        "evidence_log_other": [
            "시각이 맞는지 먼저 볼게요."
        ],
        "suspect_none": [
            "모르겠어요."
        ],
        "suspect_some": [
            "{target|i}요. {reason|i} 걸려요."
        ],
        "contra_confess": [
            "네. 다르게 말했어요."
        ],
        "contra_hold": [
            "그 얘기는 나중에 할게요."
        ],
        "contra_deny": [
            "그렇게 움직인 기억은 없어요."
        ],
        "contra_honest": [
            "{pos}에 있었어요."
        ],
        "slip": [
            "{time}에 들었… 아니에요."
        ],
        "reassure_warm": [
            "고마워요."
        ],
        "reassure_flat": [
            "듣고 있어요."
        ],
        "pressure_crew": [
            "조금만 조용히 말해요."
        ],
        "pressure_null": [
            "다른 대답은 없어요."
        ],
        "confide": [
            "{target|i}요. {reason|i} 걸려서요."
        ],
        "refuse": [
            "아직은요."
        ],
        "m_alibi_alone": [
            "{pos}에 있었어요. 혼자요."
        ],
        "m_alibi_with": [
            "{pos}에서 {mates|wa} 있었어요."
        ],
        "m_dispute_absent": [
            "그때 {pos}에 있었어요. {target|eun} 못 봤어요."
        ],
        "m_dispute_companion": [
            "{target}, 저와 함께였다는 건 맞지 않아요."
        ],
        "m_suspect": [
            "{target|eul} 확인하고 싶어요. {reason|i} 있어요."
        ],
        "m_react_accused_crew": [
            "듣고 있어요. 어떤 부분인가요?"
        ],
        "m_react_accused_null": [
            "그렇게 연결되는지는 모르겠어요."
        ],
        "m_agree": [
            "저도 궁금해요. {target}."
        ],
        "m_doubt": [
            "연결이 잘 안 돼요."
        ],
        "m_defend_agree": [
            "{target|eul} 정하기에는 일러요."
        ],
        "m_clue_self": [
            "제 이름도 있네요."
        ],
        "m_mourn": [
            "{victim}의 목소리는 남아 있어요."
        ],
        "m_vote": [
            "{target|eul} 고르겠어요."
        ],
        "m_secret": [
            "네. 더 숨긴 건 없어요."
        ]
    },
    "eli": {
        "alibi_alone": [
            "{pos}. 다른 사람은 없었다."
        ],
        "alibi_with": [
            "{pos}. {mates|wa} 함께였다."
        ],
        "witness_none": [
            "없었어. 내가 본 범위에서는."
        ],
        "witness_some": [
            "{mates|eul} 봤다."
        ],
        "sighting": [
            "{time}에 {room} 쪽. {group} 차림이었다. 얼굴은 안 보였어."
        ],
        "evidence_self_crew": [
            "내가 포함됐군. {pos}의 동선도 확인해."
        ],
        "evidence_self_null": [
            "내 이름이 있네. 다음 기록을 봐."
        ],
        "evidence_other": [
            "{members}. 이동 경로부터 보자."
        ],
        "evidence_context": [
            "순서를 알 수 있겠군."
        ],
        "evidence_log_ok": [
            "{room}. 기억과 일치해."
        ],
        "evidence_log_bad": [
            "위치가 다르군. 원본을 보여 줘."
        ],
        "evidence_log_other": [
            "동선을 연결해 보자."
        ],
        "suspect_none": [
            "아직 못 정했어."
        ],
        "suspect_some": [
            "{target}. {reason|i} 맞지 않아."
        ],
        "contra_confess": [
            "거짓말이었다. 이유부터 말할게."
        ],
        "contra_hold": [
            "사건과는 달라. 지금은 말하지 않을게."
        ],
        "contra_deny": [
            "내 기억과 맞지 않아. 원본을 봐야겠어."
        ],
        "contra_honest": [
            "{pos}. 내 동선은 그대로야."
        ],
        "slip": [
            "{time}에 실행됐을 때… 방금 말은 멈추지."
        ],
        "reassure_warm": [
            "알았어. 고맙다."
        ],
        "reassure_flat": [
            "괜찮아. 계속하자."
        ],
        "pressure_crew": [
            "그만. 사실부터 확인하자."
        ],
        "pressure_null": [
            "여기서 더 말할 건 없어."
        ],
        "confide": [
            "{target}. {reason|eul} 먼저 확인할 거야."
        ],
        "refuse": [
            "지금은 말하지 않겠어."
        ],
        "m_alibi_alone": [
            "{pos}. 혼자였다."
        ],
        "m_alibi_with": [
            "{pos}. {mates|wa} 함께였다."
        ],
        "m_dispute_absent": [
            "{pos}에 나도 있었어. {target|eun} 없었다."
        ],
        "m_dispute_companion": [
            "{target}. 같이 있지 않았다."
        ],
        "m_suspect": [
            "{target}. {reason|i} 걸린다."
        ],
        "m_react_accused_crew": [
            "내 동선을 보여 줄게."
        ],
        "m_react_accused_null": [
            "그 근거로는 부족해."
        ],
        "m_agree": [
            "{target}. 나도 같은 판단이야."
        ],
        "m_doubt": [
            "근거가 모자라."
        ],
        "m_defend_agree": [
            "{target|eul} 격리할 근거는 없어."
        ],
        "m_clue_self": [
            "나도 해당된다. 확인해."
        ],
        "m_mourn": [
            "{victim}와 보기로 한 곳이 있었어."
        ],
        "m_vote": [
            "{target|eul} 격리해야 해."
        ],
        "m_secret": [
            "그게 숨긴 이유다."
        ]
    },
    "lyra": {
        "alibi_alone": [
            "{pos}에 있었어요. 혼자였어요. 그쪽 기록이 남았을까요?"
        ],
        "alibi_with": [
            "{mates|wa} {pos}에 있었어요. 그때 얘기라면 같이 확인해요."
        ],
        "witness_none": [
            "누가 지나가는 건 못 봤어요. 확실한 건 그것뿐이에요."
        ],
        "witness_some": [
            "{mates|eul} 봤어요. 다른 사람은 기억이 안 나요."
        ],
        "sighting": [
            "{time}쯤 {room} 근처에서 {group} 차림을 봤어요. 사람을 알아볼 만큼 가깝지는 않았어요."
        ],
        "evidence_self_crew": [
            "저도 있네요. 그때 {pos}에 있었던 기록도 찾아 봐요."
        ],
        "evidence_self_null": [
            "저만 해당되는 건 아니에요. 다른 흔적도 함께 확인해요."
        ],
        "evidence_other": [
            "{members}에게 해당하네요. 명단만 보고 몰아가지는 말아요."
        ],
        "evidence_context": [
            "무슨 일이 먼저였는지는 알겠어요. 그걸 적어 둬요."
        ],
        "evidence_log_ok": [
            "{room}에 제 기록이 있네요. 여기까지는 맞아요."
        ],
        "evidence_log_bad": [
            "제가 잘못 말한 걸까요. 앞뒤도 볼 수 있어요?"
        ],
        "evidence_log_other": [
            "말과 다른 부분이 있어요? 그쪽부터 물어봐요."
        ],
        "suspect_none": [
            "지금은 모르겠어요. 괜히 한 사람에게 몰리면 곤란해요."
        ],
        "suspect_some": [
            "{target|i} 신경 쓰여요. {reason|eul} 먼저 확인하고 싶어요."
        ],
        "contra_confess": [
            "맞아요. 숨긴 게 있어요."
        ],
        "contra_hold": [
            "누군가의 사정도 같이 나와요. 지금은 못 해요."
        ],
        "contra_deny": [
            "기억은 그런데, 기록은 다르네요. 어느 쪽부터 봐야 할까요."
        ],
        "contra_honest": [
            "{pos}에 있었어요. 그 부분은 확실해요."
        ],
        "slip": [
            "{time}에 이미 그렇게 됐으니까… 어, 그건 아직 안 봤죠?"
        ],
        "reassure_warm": [
            "조금 진정되네요. 같이 있어 줘서 고마워요."
        ],
        "reassure_flat": [
            "고마워요. 이것만 마치고 쉴게요."
        ],
        "pressure_crew": [
            "잠깐만요. 그렇게 물으면 생각이 더 안 나요."
        ],
        "pressure_null": [
            "말할 수 있는 건 다 했어요. 조금만 기다려 주세요."
        ],
        "confide": [
            "{target|i} 신경 쓰여요. {reason|i} 남아 있거든요. 모두 앞에서는 아직 말 못 하겠어요."
        ],
        "refuse": [
            "조금만 시간을 줘요."
        ],
        "m_alibi_alone": [
            "{pos}에서 혼자 일하고 있었어요."
        ],
        "m_alibi_with": [
            "{mates|wa} 함께 {pos}에 있었어요."
        ],
        "m_dispute_absent": [
            "{pos}에 저도 있었어요. {target|eul} 봤다면 기억했을 거예요."
        ],
        "m_dispute_companion": [
            "{target}, 그때 저랑 있지는 않았어요. 다른 시간이 아닐까요?"
        ],
        "m_suspect": [
            "{target|eul} 다시 봐요. {reason|i} 마음에 걸려요."
        ],
        "m_react_accused_crew": [
            "제 얘기도 들어 주세요. 같이 확인해요."
        ],
        "m_react_accused_null": [
            "잠깐만요. 제 기억과는 너무 달라요."
        ],
        "m_agree": [
            "그 부분은 저도 걸렸어요. {target}, 설명해 줘요."
        ],
        "m_doubt": [
            "잠깐만요. 다른 경우도 있지 않을까요?"
        ],
        "m_defend_agree": [
            "{target|eul} 벌써 몰아가지는 말아요."
        ],
        "m_clue_self": [
            "저도 해당하네요. 제 얘기도 들어요."
        ],
        "m_mourn": [
            "{victim}에게 보여 주려던 잎이 오늘 났어요."
        ],
        "m_vote": [
            "{target|eul} 잠시 격리해야겠어요. 틀렸다면 제가 바로잡을게요."
        ],
        "m_secret": [
            "맞아요. 그 얘기를 못 했어요."
        ]
    }
}

static func has_line(npc_id: String, key: String) -> bool:
    return not pool(npc_id, key).is_empty()

# Every phrasing available for one character saying one thing: the 0.3.1 line
# plus whatever docs/dialogue_variants adds. Order is stable, so a seed replays.
static func pool(npc_id: String, key: String) -> Array:
    var options: Array = LINES.get(npc_id, {}).get(key, []).duplicate()
    options.append_array(AstraDialogueVariants.extra(npc_id, key))
    return options

static func variant_count(npc_id: String, key: String) -> int:
    return pool(npc_id, key).size()

static func line(npc_id: String, key: String, params: Dictionary = {}, variant: int = -1) -> String:
    var options: Array = pool(npc_id, key)
    if options.is_empty():
        return ""
    var index := variant
    if index < 0:
        index = randi() % options.size()
    return AstraJosa.fill(str(options[index % options.size()]), params)

# Preferred entry point from 0.4.0 on: the same line, but steered away from what
# this character has said in the last few exchanges.
static func line_fresh(npc_id: String, key: String, params: Dictionary, recent: Array, roll: float) -> String:
    var options: Array = pool(npc_id, key)
    if options.is_empty():
        return ""
    var index := AstraDialogueMemory.pick(recent, npc_id, key, options.size(), roll)
    return AstraJosa.fill(str(options[index]), params)

static func reason_text(reason_key: String) -> String:
    return str(REASONS.get(reason_key, REASONS["gut"]))

static func tell(liar: bool, name: String, pick: int) -> String:
    var pool: Array = LIAR_TELLS if liar else NERVOUS_TELLS
    return AstraJosa.fill(str(pool[posmod(pick, pool.size())]), {"name": name})
