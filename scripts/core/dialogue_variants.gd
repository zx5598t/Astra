class_name AstraDialogueVariants
extends RefCounted

const EXTRA := {
    "mira": {
        "ask_witness": [
            "지나가는 사람은 못 봤어요. 소리만으로 이름을 말할 수는 없고요."
        ],
        "ask_timeline": [
            "진료 준비를 마치고 {pos|ro} 갔어요.",
            "진료표를 닫은 다음 이동했어요. 도착한 곳은 {pos}예요."
        ],
        "ask_trust": [
            "믿으라고 하기보다 같이 확인하고 싶어요.",
            "제 기록부터 봐요. 제가 놓친 것도 있을 수 있으니까요."
        ],
        "deflect": [
            "잠깐만요. 손이 떨려서요.",
            "이 기록을 마저 읽고 답할게요."
        ],
        "alibi_alone": [
            "혼자였어요. {pos} 기록을 열면 확인할 수 있을 거예요."
        ],
        "m_alibi_alone": [
            "확인해 주세요. 그때는 {pos}에 혼자 있었어요."
        ],
        "m_alibi_with": [
            "{mates|eul} 확인해 봐요. 저와 {pos}에 있었어요."
        ],
        "suspect_some": [
            "이야기를 더 들어야겠지만, {target|i} 걸려요. {reason|i} 있어서요."
        ],
        "m_suspect": [
            "{reason|eun} 어떻게 된 건지 들어요. {target}, 말해 줄래요?"
        ],
        "m_react_accused_crew": [
            "잠깐만요. 제 기록을 가져올게요."
        ],
        "m_react_accused_null": [
            "제 얘기를 다 듣고 정해요."
        ],
        "m_agree": [
            "그 말에는 근거가 있어요. 저도 듣고 싶어요."
        ],
        "m_doubt": [
            "아직 연결되지 않은 부분이 있어요."
        ],
        "m_vote": [
            "확인할 때까지 {target|eul} 격리하는 쪽에 표를 낼게요."
        ]
    },
    "rho": {
        "ask_witness": [
            "못 봤어. 고개를 들었을 때는 아무도 없더라."
        ],
        "ask_timeline": [
            "공구를 챙긴 뒤 {pos|ro} 갔어.",
            "작업 마치고 이동했어. {pos}에 도착했고."
        ],
        "ask_trust": [
            "같이 보자. 나 혼자 설명하면 또 빼먹을 거야.",
            "내 공구함도 열어 둬. 필요한 건 봐도 돼."
        ],
        "deflect": [
            "잠깐, 이 나사부터.",
            "물 한 모금만. 다시 얘기하자."
        ],
        "alibi_alone": [
            "잠깐, 시각을 보자. 응, {pos}에 혼자 있었어."
        ],
        "m_alibi_alone": [
            "앞서 말한 대로 {pos}. 나 혼자였어."
        ],
        "m_alibi_with": [
            "{pos}에서 함께 있었어. {mates|wa}."
        ],
        "suspect_some": [
            "{reason|i} 설명 안 됐잖아. 그래서 {target|eul} 보고 있어."
        ],
        "m_suspect": [
            "{reason|i} 아직 남았어. {target}, 이 부분부터."
        ],
        "m_react_accused_crew": [
            "알았어. 내 쪽부터 다 열어 볼게."
        ],
        "m_react_accused_null": [
            "그 결론은 너무 빠르잖아."
        ],
        "m_agree": [
            "나도 같은 쪽이야. 이유는 들었고."
        ],
        "m_doubt": [
            "잠깐, 그 둘이 같은 얘기야?"
        ],
        "m_vote": [
            "내 표는 {target}. 지금은 멈추는 게 맞아 보여."
        ]
    },
    "dax": {
        "ask_witness": [
            "본 사람은 없어. 그 이상은 추측이야."
        ],
        "ask_timeline": [
            "확인을 마치고 {pos|ro} 이동했어.",
            "진단을 끝내고 움직였어. 다음 장소는 {pos}였지."
        ],
        "ask_trust": [
            "내 판단도 틀릴 수 있어. 검증할 기록을 줄게.",
            "나를 믿기 전에 이쪽을 확인해 봐."
        ],
        "deflect": [
            "지금 답하면 추측이 될 것 같아.",
            "그 부분은 다시 확인하고 싶어."
        ],
        "alibi_alone": [
            "그 구간은 {pos}야. 동행은 없었어."
        ],
        "m_alibi_alone": [
            "내 동선도 적어 둬. {pos}, 혼자."
        ],
        "m_alibi_with": [
            "{mates|wa} 함께였지. 장소는 {pos}였어."
        ],
        "suspect_some": [
            "아직 정한 건 아니야. {target|eul} 보는 이유는 {reason|i} 있어서지."
        ],
        "m_suspect": [
            "{reason|eul} 다시 보자. {target}의 설명이 필요해."
        ],
        "m_react_accused_crew": [
            "그렇게 보였겠군. 하나씩 바로잡자."
        ],
        "m_react_accused_null": [
            "결론 전에 원본부터 보자."
        ],
        "m_agree": [
            "그 설명이 지금 기록과 가장 가까워."
        ],
        "m_doubt": [
            "그 사이를 설명할 기록이 없군."
        ],
        "m_vote": [
            "{target|eul} 선택하겠어. 기록을 더 확인할 동안."
        ]
    },
    "noa": {
        "ask_witness": [
            "목격한 사람은 없어요."
        ],
        "ask_timeline": [
            "기록을 저장하고 {pos|ro} 갔어요.",
            "기록 저장, 그 다음 이동이에요. {pos}로요."
        ],
        "ask_trust": [
            "제가 한 말을 남겨 주세요.",
            "지운 문장도 보여 드릴게요."
        ],
        "deflect": [
            "아직 정리가 안 됐어요.",
            "잠깐만요."
        ],
        "alibi_alone": [
            "동행은 없어요. 장소는 {pos}예요."
        ],
        "m_alibi_alone": [
            "기록해 주세요. {pos}에 혼자 있었어요."
        ],
        "m_alibi_with": [
            "{mates|wa} {pos}에 있었어요. 그렇게 적어 주세요."
        ],
        "suspect_some": [
            "{reason|i} 남았어요. {target|eul} 확인하고 싶어요."
        ],
        "m_suspect": [
            "{reason|i} 남았어요. {target}, 확인해 줘요."
        ],
        "m_react_accused_crew": [
            "제 말을 그대로 남겨 주세요. 확인할게요."
        ],
        "m_react_accused_null": [
            "전부 확인한 건 아니잖아요."
        ],
        "m_agree": [
            "저도 그 줄을 봤어요."
        ],
        "m_doubt": [
            "그 연결은 아직 안 보여요."
        ],
        "m_vote": [
            "제 표는 {target}에게요."
        ]
    },
    "sena": {
        "ask_witness": [
            "그쪽에서 사람은 못 봤어."
        ],
        "ask_timeline": [
            "순찰하고 {pos|ro} 갔어.",
            "통로 확인을 마치고 이동했어. {pos}까지."
        ],
        "ask_trust": [
            "내 동선부터 같이 돌자.",
            "내 말도 똑같이 확인해."
        ],
        "deflect": [
            "여기서는 말하기 어렵겠어.",
            "문부터 닫고 얘기하자."
        ],
        "alibi_alone": [
            "같이 있던 사람은 없어. {pos}에서 확인 중이었어."
        ],
        "m_alibi_alone": [
            "내 순서지? {pos}에 혼자 있었어."
        ],
        "m_alibi_with": [
            "{pos}에서 {mates|wa} 함께였어. 따로 확인해 봐."
        ],
        "suspect_some": [
            "{reason|i} 걸려. {target|eul} 확인한 다음에 정하자."
        ],
        "m_suspect": [
            "{reason|eun} 지나칠 수 없어. {target}, 같이 보자."
        ],
        "m_react_accused_crew": [
            "듣고 있어. 나도 설명할 기회를 줘."
        ],
        "m_react_accused_null": [
            "아직 빠진 게 있어. 기다려 줘."
        ],
        "m_agree": [
            "동의해. 더 미루지는 말자."
        ],
        "m_doubt": [
            "멈춰 봐. 놓친 게 있는 것 같아."
        ],
        "m_vote": [
            "{target|eul} 고를게. 내 판단도 기록해 둬."
        ]
    },
    "vale": {
        "ask_witness": [
            "아무도 못 봤어요."
        ],
        "ask_timeline": [
            "채널을 정리한 뒤 {pos|ro} 갔어요.",
            "송신을 마치고 이동했어요. {pos}요."
        ],
        "ask_trust": [
            "녹음 원본을 드릴게요.",
            "같이 들어 봐요."
        ],
        "deflect": [
            "다시 들은 뒤에 말할게요.",
            "지금은 모르겠어요."
        ],
        "alibi_alone": [
            "혼자였어요. {pos}요."
        ],
        "m_alibi_alone": [
            "그 시간은 {pos}예요. 혼자 있었고요."
        ],
        "m_alibi_with": [
            "{mates|wa} 있었어요. {pos}에서요."
        ],
        "suspect_some": [
            "{reason|i} 있어요. 그래서 {target|i} 걸려요."
        ],
        "m_suspect": [
            "{reason|eul} 물어보고 싶어요. {target}에게요."
        ],
        "m_react_accused_crew": [
            "확인할 기록을 드릴게요."
        ],
        "m_react_accused_null": [
            "다시 확인해 주세요."
        ],
        "m_agree": [
            "저도 그렇게 들었어요."
        ],
        "m_doubt": [
            "다르게 들릴 수도 있어요."
        ],
        "m_vote": [
            "{target|eul} 선택할게요."
        ]
    },
    "eli": {
        "ask_witness": [
            "없었어. 내가 본 범위에서는."
        ],
        "ask_timeline": [
            "항로를 보고 {pos|ro} 갔어.",
            "확인이 끝난 뒤 이동했어. {pos}로."
        ],
        "ask_trust": [
            "항로 기록은 열려 있어.",
            "직접 확인해. 기다릴게."
        ],
        "deflect": [
            "그 질문은 잠깐 미루자.",
            "먼저 확인할 게 있어."
        ],
        "alibi_alone": [
            "동행 없이 {pos}에 있었어."
        ],
        "m_alibi_alone": [
            "혼자 {pos}에 있었다."
        ],
        "m_alibi_with": [
            "함께 있던 건 {mates}. 장소는 {pos}다."
        ],
        "suspect_some": [
            "{reason|i} 남았어. {target|eul} 확인해야 해."
        ],
        "m_suspect": [
            "{reason|i} 맞지 않아. {target}, 설명해."
        ],
        "m_react_accused_crew": [
            "내가 본 것부터 말하지."
        ],
        "m_react_accused_null": [
            "그건 받아들이기 어려워."
        ],
        "m_agree": [
            "같은 판단이다."
        ],
        "m_doubt": [
            "아직 확정할 수 없어."
        ],
        "m_vote": [
            "내 표는 {target}이다."
        ]
    },
    "lyra": {
        "ask_witness": [
            "누가 지나가는 건 못 봤어요. 확실한 건 그것뿐이에요."
        ],
        "ask_timeline": [
            "급수를 마치고 {pos|ro} 갔어요.",
            "정리를 마치고 이동했어요. 그다음이 {pos}예요."
        ],
        "ask_trust": [
            "확인할 수 있는 건 전부 꺼내 놓을게요.",
            "제 말과 다른 게 있으면 먼저 알려 줘요."
        ],
        "deflect": [
            "손 씻고 올게요. 기다려 줄래요?",
            "지금은 생각이 잘 안 나요."
        ],
        "alibi_alone": [
            "{pos}에 있었던 건 기억해요. 옆에 사람은 없었고요."
        ],
        "m_alibi_alone": [
            "같이 있던 사람은 없어요. {pos}에서 일했어요."
        ],
        "m_alibi_with": [
            "{pos}에 있었어요. {mates|wa} 같이요."
        ],
        "suspect_some": [
            "{reason|i} 있어서요. {target|eul} 그냥 지나치기는 어려워요."
        ],
        "m_suspect": [
            "{reason|i} 마음에 남아요. {target}, 얘기해 줘요."
        ],
        "m_react_accused_crew": [
            "피하지 않을게요. 어디부터 볼까요?"
        ],
        "m_react_accused_null": [
            "지금 여기서 정해 버리지는 말아요."
        ],
        "m_agree": [
            "저도 그 부분은 같아요. 같이 확인해요."
        ],
        "m_doubt": [
            "다른 경우도 확인하고 정해요."
        ],
        "m_vote": [
            "제 표는 {target}에게 낼게요. 끝까지 확인할 거예요."
        ]
    }
}
const EXTRA_INTENTS := EXTRA
static func extra(npc_id: String, key: String) -> Array:
    return EXTRA.get(npc_id,{}).get(key,[]).duplicate()
static func intent_pool(npc_id: String, key: String) -> Array:
    return extra(npc_id,key)
