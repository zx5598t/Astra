class_name AstraDialogueVariants
extends RefCounted

# Extra phrasings for the lines that fire most often.
#
# In 0.3.1 every meeting key held exactly one sentence per character, so a crew
# member greeted a new accusation with the identical sentence in every meeting
# of every case. The truth model was fine; the voice was a tape loop.
#
# This file only adds phrasings. It never adds a new *claim*: two variants of
# `m_alibi_alone` say the same thing about where the speaker was, in the same
# register, with different words. Anything that changes what a line asserts
# belongs in the session, not here.
#
# `deflect` is new in 0.4.0. It is what a character does instead of answering
# when they are under pressure, and it is written per personality (§5): Noa gets
# shorter, Eli jokes, Sena demands procedure, Rho snaps, Mira turns the question
# around, Vale rewrites it, Lyra names the mood, Dax redefines the term. It is
# not a lie detector — a Null can answer plainly and a frightened crew member
# can deflect all day.

const EXTRA := {
    "mira": {
        "alibi_alone": ["그 시간엔 {pos}에 있었어요. 혼자라 증인은 없어요.", "{pos}요. 저 혼자였어요. 숨길 생각은 없어요."],
        "alibi_with": ["{pos}에 있었어요. {mates|wa} 같이요. 물어보셔도 돼요.", "{mates|wa} {pos}에 있었어요. 서로 확인해 줄 수 있을 거예요."],
        "suspect_some": ["{target|i} 계속 마음에 걸려요. {reason} 때문이에요.", "이름을 말하는 건 조심스럽지만… {target}이요. {reason|eun} 넘기기 어려워요."],
        "suspect_none": ["아직 아무도 지목하지 않을래요. 틀리면 사람이 다쳐요.", "지금 이름을 말하면 그 사람은 오늘 밤이 위험해져요. 조금만 더 봐요."],
        "pressure_crew": ["소리를 높여도 기록은 그대로예요. 근거를 주세요.", "저를 몰아세우는 건 상관없어요. 다만 시간이 줄어들어요."],
        "pressure_null": ["저한테 쓰는 시간만큼 진짜 실행자가 여유를 얻어요.", "이렇게 한 사람만 파면, 나머지는 안심하고 다음을 준비하겠죠."],
        "contra_deny": ["센서 하나로 사람을 정하진 말아요.", "기록은 시간을 말하지 의도를 말하지 않아요."],
        "contra_honest": ["저는 {pos}에 있었어요. 다른 말이 있다면 그쪽을 확인해 주세요.", "제 진술은 그대로예요. 바꿀 이유가 없어요."],
        "deflect": ["…잠깐만요. 지금 다들 괜찮으신 거죠?", "그 얘기 전에, 오늘 아무도 다치지 않았는지부터 확인할게요."],
        "m_alibi_alone": ["{pos}에 있었어요. 혼자였고요.", "저는 {pos}. 같이 있던 사람은 없어요."],
        "m_alibi_with": ["{pos}에서 {mates|wa} 함께 있었어요.", "{mates}, 저랑 {pos}에 있었죠. 맞죠?"],
        "m_suspect": ["{target}. 단정은 아니에요. {reason|i} 걸려요.", "{reason}. 그래서 {target|eul} 보고 있어요."],
        "m_react_accused_crew": ["저요? 좋아요. 기록부터 열어요.", "피하지 않을게요. 무엇을 확인하면 되죠?"],
        "m_react_accused_null": ["제가 했다면 이 자리에 앉아 있었을까요?", "그 논리대로면 여기 절반이 범인이에요."],
        "m_agree": ["같은 생각이에요. {target}, 설명해 주세요.", "저도 거기서 멈췄어요. {target}, 한 번만 더 말해 줄래요?"],
        "m_doubt": ["조금 빨라요. 근거가 하나 더 필요해요.", "그건 추측이지 기록이 아니에요."],
        "m_defend_agree": ["{target|eul} 지금 몰아가는 건 이르다고 봐요.", "한 사람에게 다 쏟지 말아요. {target}만의 문제가 아니에요."],
        "m_vote": ["{target}. 마음이 편하진 않아요.", "저는 {target}. 틀렸다면 제가 책임질게요."],
        "m_dispute_absent": ["저도 {pos}에 있었어요. {target|eul} 보지 못했어요.", "{pos}에 있던 건 저예요. {target}, 언제 들어왔다는 거죠?"]
    },
    "rho": {
        "alibi_alone": ["{pos}. 혼자였어. 증인 없어.", "{pos}에 있었다고. 그거 말고 할 말 없어."],
        "alibi_with": ["{pos}. {mates|wa} 같이 있었어.", "{mates}한테 물어봐. {pos}에 같이 있었으니까."],
        "suspect_some": ["{target}. {reason|i} 걸려. 그게 다야.", "난 {target}. {reason} 그거면 충분하지 않아?"],
        "suspect_none": ["몰라. 아무나 찍으라고? 그건 안 해.", "확실해지면 말할게. 지금은 아니야."],
        "pressure_crew": ["소리 지른다고 없던 게 생기냐.", "할 말 다 했어. 더 파고 싶으면 기록 가져와."],
        "pressure_null": ["나만 붙잡고 있는 사이에 다른 놈은 뭐 하고 있을까.", "이러다 진짜 놓친다. 그래도 계속할래?"],
        "contra_deny": ["센서가 신이야? 여기 배는 낡았어.", "그 기록 몇 번이나 튀는 줄 알아? 나 매일 고쳐."],
        "contra_honest": ["난 {pos}에 있었어. 말 안 바꿔.", "몇 번을 물어도 {pos}야."],
        "deflect": ["…됐고. 지금 그게 중요해?", "그 질문 말고 할 거 없냐. 나 할 일 많아."],
        "m_alibi_alone": ["{pos}. 혼자.", "{pos}에 있었다. 끝."],
        "m_alibi_with": ["{pos}. {mates|wa} 있었어.", "{mates}랑 {pos}. 확인해."],
        "m_suspect": ["{target}. {reason|i} 이상하잖아.", "난 {target} 본다. {reason}. 그게 답이야."],
        "m_react_accused_crew": ["나? 까 봐. 나올 거 없어.", "좋아. 뭘 보면 되는데."],
        "m_react_accused_null": ["증거는 어디 있고? 감으로 사람 가두냐.", "이딴 걸로 몰면 다음은 너야."],
        "m_agree": ["나도 그렇게 봤어. {target}, 말해 봐.", "동의. {target} 설명 들어 보자."],
        "m_doubt": ["약해. 그걸로 사람을 가둬?", "그건 그냥 느낌이잖아."],
        "m_defend_agree": ["{target} 편은 아니지만 지금은 과해.", "한 명한테 다 쏟지 마. 이러면 진짜를 놓쳐."],
        "m_vote": ["{target}. 그냥 찍는 거 아니야.", "{target}으로 간다."],
        "m_dispute_absent": ["헛소리. 그때 {pos}엔 나 있었어. {target} 못 봤다.", "{pos}? 내가 거기 있었는데 {target}은 없었어."]
    },
    "eli": {
        "alibi_alone": ["{pos}. 혼자였어. 알리바이 없는 게 죄는 아니지?", "{pos}에 있었어. 아쉽게도 목격자는 없고."],
        "alibi_with": ["{pos}. {mates|wa} 같이 있었어.", "{mates}랑 {pos}에. 서로 봤으니까 물어봐."],
        "suspect_some": ["{target}. {reason|i} 좀 티 나잖아.", "굳이 고르라면 {target}. {reason} 때문이야."],
        "suspect_none": ["아직 안 골라. 지금 고르면 그냥 분위기에 맞추는 거야.", "패가 덜 깔렸어. 성급하게 던지면 지는 쪽은 우리야."],
        "pressure_crew": ["와, 무섭다. 그래서 뭘 물어보고 싶은데?", "압박 좋아. 근데 그걸로 나오는 건 없을걸."],
        "pressure_null": ["나 하나 잡는다고 끝나면 얼마나 좋겠어.", "이 분위기 만든 사람이 누군지부터 보는 게 낫지 않아?"],
        "contra_deny": ["기록이 항상 맞으면 항법사가 왜 필요해.", "센서는 시간을 찍지, 사람을 찍진 않아."],
        "contra_honest": ["{pos}. 말 안 바꿔. 이건 확실해.", "내 말은 그대로야. 필요하면 몇 번이든."],
        "deflect": ["그 얘기 말고… 오늘 커피 맛 어땠어? 농담이야. 반쯤은.", "질문이 좀 무거운데, 가볍게 갈까?"],
        "m_alibi_alone": ["{pos}. 혼자였어.", "{pos}에 있었어. 증인은 없고."],
        "m_alibi_with": ["{pos}. {mates|wa} 같이.", "{mates}랑 {pos}. 확인해도 돼."],
        "m_suspect": ["{target}. {reason|i} 눈에 밟혀.", "{reason}. 그래서 나는 {target}."],
        "m_react_accused_crew": ["나야? 재밌네. 뭘 보여 주면 될까.", "좋아, 해 보자. 나부터 열지 뭐."],
        "m_react_accused_null": ["이 분위기에서 이름 하나 던지면 끝나는 거 알지?", "몰아가기 참 쉽다. 근거는 어디 갔어?"],
        "m_agree": ["나도 같은 데서 걸렸어. {target}, 설명해 봐.", "동의. {target}, 한 번 더 말해 줄래?"],
        "m_doubt": ["그건 분위기지 근거가 아니야.", "너무 매끄러운데. 그게 더 걸려."],
        "m_defend_agree": ["{target} 하나로 정리하려는 거, 위험해.", "지금 {target}한테 다 몰리는 게 오히려 이상해."],
        "m_vote": ["{target}. 어쩔 수 없지.", "{target}으로 간다. 틀리면 내 탓."],
        "m_dispute_absent": ["어라, 나도 {pos}에 있었는데. {target}은 못 봤어.", "{pos}? 그럼 우리 마주쳤어야지, {target}."]
    },
    "sena": {
        "alibi_alone": ["{pos}에 있었습니다. 단독이었습니다.", "{pos}입니다. 증인은 없습니다. 기록을 확인하십시오."],
        "alibi_with": ["{pos}에 있었습니다. {mates|wa} 함께였습니다.", "{mates}와 동행했습니다. 장소는 {pos}입니다."],
        "suspect_some": ["{target}입니다. {reason|i} 확인되지 않았습니다.", "{reason}. 절차상 {target|eul} 우선 확인해야 합니다."],
        "suspect_none": ["근거 없는 지목은 하지 않습니다.", "확인된 사실이 부족합니다. 지목을 보류합니다."],
        "pressure_crew": ["절차대로 하십시오. 요구 사항을 명확히 말씀해 주십시오.", "질문을 특정해 주십시오. 그러면 답변하겠습니다."],
        "pressure_null": ["압박은 절차가 아닙니다. 근거를 제시하십시오.", "감정으로 진행하면 기록이 남지 않습니다."],
        "contra_deny": ["기록 하나로 결론을 내릴 수는 없습니다.", "해당 기록의 원본 확인을 요청합니다."],
        "contra_honest": ["진술은 변경하지 않습니다. {pos}입니다.", "동일한 답변을 유지합니다."],
        "deflect": ["그 질문 전에 절차를 확인하겠습니다. 이 심문은 기록됩니까?", "순서가 잘못됐습니다. 먼저 확인할 것이 있습니다."],
        "m_alibi_alone": ["{pos}. 단독이었습니다.", "{pos}에 있었습니다. 동행 없음."],
        "m_alibi_with": ["{pos}. {mates|wa} 함께였습니다.", "{mates}와 {pos}에 있었습니다."],
        "m_suspect": ["{target}. {reason|i} 해명되지 않았습니다.", "{reason}. {target}에 대한 확인을 요구합니다."],
        "m_react_accused_crew": ["확인하십시오. 제 기록은 공개합니다.", "이의 없습니다. 절차를 진행하십시오."],
        "m_react_accused_null": ["근거를 제시하십시오. 지목만으로는 부족합니다.", "이 지목의 근거가 기록에 남습니까?"],
        "m_agree": ["동의합니다. {target}, 해명하십시오.", "같은 판단입니다. {target}의 답변을 요구합니다."],
        "m_doubt": ["근거가 불충분합니다.", "그 추론은 기록으로 뒷받침되지 않습니다."],
        "m_defend_agree": ["{target}에 대한 압박이 과합니다. 절차를 지키십시오.", "한 사람에게 집중하는 것은 위험합니다."],
        "m_vote": ["{target}. 책임은 제가 집니다.", "{target}으로 하겠습니다."],
        "m_dispute_absent": ["저도 {pos}에 있었습니다. {target|eul} 보지 못했습니다.", "{pos} 순찰은 제가 했습니다. {target}은 없었습니다."]
    },
    "vale": {
        "alibi_alone": ["{pos}에 있었어요. 혼자였죠.", "{pos}요. 같이 있던 사람은 없었어요."],
        "alibi_with": ["{pos}에서 {mates|wa} 함께였어요.", "{mates}와 {pos}에 있었어요. 확인해 보셔도 돼요."],
        "suspect_some": ["{target}… 이라고 말하긴 조심스럽네요. {reason}이요.", "{reason}. 그 부분이 {target}에게는 설명되지 않아요."],
        "suspect_none": ["이름을 말하면 그게 곧 사실처럼 굳어요. 아직은요.", "판단을 미룰게요. 지금 말하면 되돌릴 수 없어요."],
        "pressure_crew": ["같은 질문을 조금 다르게 물어봐 주시겠어요?", "제가 무엇을 숨긴다고 보시는지, 그것부터 알려 주세요."],
        "pressure_null": ["압박은 답을 만들지 않아요. 원하는 답을 만들 뿐이죠.", "이렇게 물으시면 저는 무엇을 말해도 의심받아요."],
        "contra_deny": ["같은 기록을 다르게 읽을 수도 있어요.", "그건 제 진술과 어긋난 게 아니라, 순서가 다르게 보이는 거예요."],
        "contra_honest": ["제 말은 바뀌지 않았어요. 해석이 바뀐 거죠.", "{pos}. 처음부터 그렇게 말씀드렸어요."],
        "deflect": ["질문을 조금만 바꿔 주시면 더 정확히 답할 수 있어요.", "그 표현이 정확한가요? 저라면 이렇게 물을 것 같은데요."],
        "m_alibi_alone": ["{pos}에 있었어요. 혼자요.", "{pos}. 증인은 없네요."],
        "m_alibi_with": ["{pos}에서 {mates|wa} 함께였어요.", "{mates}와 {pos}에 있었어요."],
        "m_suspect": ["{target}. {reason|i} 설명되지 않아요.", "{reason}. 그래서 {target}을 보고 있어요."],
        "m_react_accused_crew": ["저인가요. 무엇을 보여 드리면 될까요.", "좋아요. 다만 순서대로 확인해요."],
        "m_react_accused_null": ["같은 사실을 그렇게도 읽을 수 있군요.", "그 근거는 저 말고 두 사람에게도 똑같이 적용돼요."],
        "m_agree": ["저도 같은 지점이에요. {target}, 답해 주세요.", "동의해요. {target}의 설명을 듣고 싶어요."],
        "m_doubt": ["결론이 근거보다 앞서 있어요.", "그건 해석이지 기록이 아니에요."],
        "m_defend_agree": ["{target}에게만 몰리는 게 오히려 이상해요.", "지금 {target|eul} 정하면, 확인할 기회를 잃어요."],
        "m_vote": ["{target}. 마음이 무겁네요.", "{target}으로 하겠어요."],
        "m_dispute_absent": ["저도 {pos}에 있었어요. {target|eul} 보지 못했어요.", "{pos}에 있었는데, {target}은 기억에 없어요."]
    },
    "noa": {
        "alibi_alone": ["{pos}. 혼자였어요.", "{pos}에 있었어요. 그게 전부예요."],
        "alibi_with": ["{pos}. {mates|wa} 있었어요.", "{mates}와 {pos}에 있었어요."],
        "suspect_some": ["{target}이요. {reason}.", "{reason}. {target}."],
        "suspect_none": ["확인된 게 없어요. 말하지 않을게요.", "아직이요. 기록이 부족해요."],
        "pressure_crew": ["말한 건 전부 그대로예요.", "바꿀 문장이 없어요."],
        "pressure_null": ["같은 질문을 세 번째 받고 있어요.", "제가 말을 바꾸길 기다리시는 거라면, 안 바꿔요."],
        "contra_deny": ["기록과 제 말이 다르다면, 둘 중 하나는 늦게 저장된 거예요.", "시각이 어긋나는 기록은 전에도 있었어요."],
        "contra_honest": ["{pos}. 처음 말한 그대로예요.", "제 문장은 바뀌지 않았어요. 확인해 보세요."],
        "deflect": ["…", "지금은 말하지 않을래요."],
        "m_alibi_alone": ["{pos}. 혼자.", "{pos}에 있었어요."],
        "m_alibi_with": ["{pos}. {mates|wa}.", "{mates}와 {pos}."],
        "m_suspect": ["{target}. {reason}.", "{reason}. 그래서 {target}이요."],
        "m_react_accused_crew": ["제 기록 전부 공개할게요.", "확인하세요. 숨긴 문장 없어요."],
        "m_react_accused_null": ["근거를 문장으로 말해 주세요.", "그건 기록이 아니라 인상이에요."],
        "m_agree": ["같은 문장에서 걸렸어요. {target}.", "동의해요. {target}, 설명해 주세요."],
        "m_doubt": ["기록에 그런 문장은 없어요.", "근거가 인용되지 않았어요."],
        "m_defend_agree": ["{target}에 대한 근거는 아직 하나예요.", "지금 {target|eul} 정하면 나머지는 확인되지 않아요."],
        "m_vote": ["{target}. 기록해 둘게요.", "{target}이요."],
        "m_dispute_absent": ["저는 {pos}에 있었어요. {target|eul} 못 봤어요.", "{pos}에 있던 사람 중에 {target}은 없었어요."]
    },
    "lyra": {
        "alibi_alone": ["{pos}에 있었어요. 혼자였어요.", "{pos}요… 아무도 없었어요."],
        "alibi_with": ["{pos}에서 {mates|wa} 함께 있었어요.", "{mates}랑 {pos}에 있었어요."],
        "suspect_some": ["{target}… 말하고 싶진 않지만, {reason}이 걸려요.", "{reason}. 그래서 {target}이 마음에 걸려요."],
        "suspect_none": ["누구도 고르고 싶지 않아요. 아직은요.", "지금 이름을 부르면 그 사람은 혼자가 돼요."],
        "pressure_crew": ["그렇게 말씀하시면 제가 더 못 떠올려요.", "천천히 물어봐 주시면 안 될까요."],
        "pressure_null": ["다들 이렇게 서로를 미워하게 되는 게 진짜 무서운 일이에요.", "저를 몰아세워서 편해지는 사람이 누구인지도 생각해 봐요."],
        "contra_deny": ["기록이 틀릴 때도 있잖아요.", "그 시간엔 문이 계속 여닫혔어요. 다 남지는 않았을 거예요."],
        "contra_honest": ["{pos}에 있었어요. 정말이에요.", "말을 바꾸지 않았어요. 믿어 주세요."],
        "deflect": ["…지금 다들 표정이 너무 굳어 있어요.", "그 질문보다, 방금 {target} 표정 보셨어요?"],
        "m_alibi_alone": ["{pos}에 있었어요. 혼자요.", "{pos}. 아무도 없었어요."],
        "m_alibi_with": ["{pos}에서 {mates|wa} 함께요.", "{mates}랑 {pos}에 있었어요."],
        "m_suspect": ["{target}… {reason}이 걸려요.", "{reason}. 미안해요, {target}."],
        "m_react_accused_crew": ["저요…? 무엇을 보여 드리면 될까요.", "괜찮아요. 확인해 주세요."],
        "m_react_accused_null": ["이렇게 한 명씩 정하다 보면 아무도 안 남아요.", "그 근거는 저만의 것이 아니에요."],
        "m_agree": ["저도 거기서 멈췄어요. {target}, 말해 줄래요?", "같은 생각이에요. {target}."],
        "m_doubt": ["조금만 천천히 가요. 근거가 얇아요.", "지금 결론을 내면 되돌릴 수 없어요."],
        "m_defend_agree": ["{target}한테만 다 몰리고 있어요. 이건 아니에요.", "몰아가는 분위기가 먼저 생긴 것 같아요."],
        "m_vote": ["{target}… 죄송해요.", "{target}이요. 제발 제가 틀렸으면 좋겠어요."],
        "m_dispute_absent": ["저도 {pos}에 있었어요. {target|eul} 못 봤어요.", "{pos}에 있었는데… {target}, 정말 거기 있었어요?"]
    },
    "dax": {
        "alibi_alone": ["{pos}. 단독.", "{pos}에 있었다. 관측자는 없다."],
        "alibi_with": ["{pos}. {mates|wa} 동행.", "{mates}와 {pos}에 있었다."],
        "suspect_some": ["{target}. 근거는 {reason}.", "{reason}. 따라서 {target}."],
        "suspect_none": ["입력이 부족하다. 결론을 내지 않는다.", "확률이 고르다. 지목은 무의미하다."],
        "pressure_crew": ["압박은 정보를 만들지 않는다.", "질문을 다시 정의해라. 지금 질문은 답이 여러 개다."],
        "pressure_null": ["나에게 자원을 쓰는 만큼 다른 경로가 열린다.", "이 심문의 기대 이득은 낮다."],
        "contra_deny": ["기록은 시각을 저장한다. 의도는 저장하지 않는다.", "그 로그는 동기화 지연 가능성이 있다."],
        "contra_honest": ["{pos}. 수정 없음.", "진술을 유지한다. 반증을 가져와라."],
        "deflect": ["‘숨겼다’의 정의부터 하자. 보고하지 않은 것과 은폐는 다르다.", "그 질문은 전제가 틀렸다. 전제를 고치면 답이 달라진다."],
        "m_alibi_alone": ["{pos}. 단독.", "{pos}에 있었다."],
        "m_alibi_with": ["{pos}. {mates|wa}.", "{mates}와 {pos}."],
        "m_suspect": ["{target}. 근거 {reason}.", "{reason}. 결론 {target}."],
        "m_react_accused_crew": ["확인해라. 내 로그는 전부 열려 있다.", "반박하지 않는다. 검증해라."],
        "m_react_accused_null": ["그 근거는 세 사람에게 동일하게 적용된다.", "표본 하나로 결론을 내고 있다."],
        "m_agree": ["동의한다. {target}, 설명해라.", "같은 결론이다. {target}."],
        "m_doubt": ["근거가 하나다. 결론이 이르다.", "상관관계를 인과로 읽고 있다."],
        "m_defend_agree": ["{target}에 대한 집중이 과하다. 분산해라.", "지금 {target|eul} 제거하면 검증 경로가 사라진다."],
        "m_vote": ["{target}. 확률 최대.", "{target}으로 한다."],
        "m_dispute_absent": ["나도 {pos}에 있었다. {target}은 없었다.", "{pos}. 관측 결과에 {target}은 포함되지 않는다."]
    }
}

static func extra(npc_id: String, key: String) -> Array:
    var lines: Array = EXTRA.get(npc_id, {}).get(key, []).duplicate()
    lines.append_array(EXTRA_INTENTS.get(npc_id, {}).get(key, []))
    return lines

# Answers to the three question types added in 0.4.0.
#
# The complaint these fix is "내가 똑같은 말을 하고 상대방도 똑같은 말을 한다":
# 0.3.1 gave the player one useful opening question (ALIBI) and everything else
# was a reaction to evidence they might not have yet. These three can be asked
# of anyone at any time, they produce different information, and each character
# answers them in their own register.
#
#   ask_witness  — 그 시간에 누구를 봤나요
#   ask_timeline — 그 직전과 직후에는 무엇을 했나요
#   ask_trust    — 왜 당신을 믿어야 하죠
const EXTRA_INTENTS := {
    "mira": {
        "ask_witness": ["지나가는 사람은 못 봤어요. 제가 있던 쪽은 조용했거든요.", "누가 있었는지 확실하지 않아요. 확실하지 않은 걸 말하면 그 사람이 다쳐요."],
        "ask_timeline": ["그 전엔 의료실 정리를 하고 있었어요. 끝나고는 바로 {pos}으로 갔고요.", "시간 순서대로 말할게요. 정리, 이동, 그리고 소식을 들었어요."],
        "ask_trust": ["믿어 달라고는 안 할게요. 대신 제 기록을 보세요. 전부 열어 둘게요.", "제가 지금까지 누굴 몰아세운 적 있나요? 그게 제 대답이에요."]
    },
    "rho": {
        "ask_witness": ["아무도 못 봤어. 봤으면 말했지.", "거기 사람이 있었으면 내가 기억했을 거다."],
        "ask_timeline": ["전엔 펌프 만지고 있었고, 끝나고 {pos}으로 갔어.", "순서? 일하고, 이동하고, 소식 들었다. 그게 다야."],
        "ask_trust": ["믿든 말든. 난 이 배 고치는 사람이야. 부수는 놈이 아니라.", "내가 뭘 더 해야 믿을 건데. 말해 봐."]
    },
    "eli": {
        "ask_witness": ["사람은 못 봤어. 근데 소리는 들은 것 같기도 하고… 확실친 않아.", "봤다고 하면 믿을 거야? 안 봤어."],
        "ask_timeline": ["전엔 항로 확인, 그다음 {pos}. 특별할 거 없어.", "시간표대로 말해 줄까? 지루할 텐데."],
        "ask_trust": ["안 믿어도 돼. 대신 나 말고 다른 사람도 똑같이 의심해 줘.", "여기서 제일 말 많은 사람이 제일 수상해 보이지. 알아. 그래도 난 아니야."]
    },
    "sena": {
        "ask_witness": ["해당 시간대에 접촉한 인원은 없습니다.", "목격 사항 없음. 순찰 기록으로 확인 가능합니다."],
        "ask_timeline": ["직전: 순찰. 직후: {pos} 이동. 이상입니다.", "시간 순서로 보고하겠습니다. 순찰, 이동, 상황 인지."],
        "ask_trust": ["저를 믿는 것은 조사관의 판단입니다. 저는 기록을 제출할 뿐입니다.", "신뢰를 요구하지 않겠습니다. 검증을 요구합니다."]
    },
    "vale": {
        "ask_witness": ["사람은 못 봤어요. 다만… 아니에요, 확실하지 않은 건 말하지 않을게요.", "본 것과 봤다고 생각하는 건 다르니까요. 저는 못 봤어요."],
        "ask_timeline": ["그 전엔 채널을 정리하고 있었고, 그 뒤에 {pos}으로 갔어요.", "순서대로라면 정리, 이동, 그리고 소식이에요."],
        "ask_trust": ["믿어 달라는 말은 설득이 아니죠. 제 기록을 보여 드릴게요.", "저를 믿을 이유가 없다면, 의심할 이유도 아직 없지 않나요?"]
    },
    "noa": {
        "ask_witness": ["아무도 없었어요.", "못 봤어요. 봤으면 적어 뒀을 거예요."],
        "ask_timeline": ["직전엔 기록 정리. 직후엔 {pos}.", "정리하고, 이동했어요. 그게 전부예요."],
        "ask_trust": ["제 문장은 바뀌지 않았어요. 확인해 보세요.", "믿을 이유요? 제가 한 말을 전부 대조해 보시면 돼요."]
    },
    "lyra": {
        "ask_witness": ["아무도 못 봤어요… 저도 그게 좀 이상해요.", "그 시간엔 정말 조용했어요."],
        "ask_timeline": ["전엔 온실에 있었고, 그다음에 {pos}으로 갔어요.", "천천히 생각해 볼게요… 온실, 이동, 그리고 소식이었어요."],
        "ask_trust": ["저를 믿어 달라고 하면 이기적인 걸까요. 그래도 부탁드려요.", "제가 누굴 해칠 수 있는 사람으로 보이나요… 그래도 확인은 하세요."]
    },
    "dax": {
        "ask_witness": ["관측 없음.", "그 구간에 사람은 없었다. 내 기억이 맞다면."],
        "ask_timeline": ["직전: 진단. 직후: {pos} 이동.", "순서는 진단, 이동, 보고 수신이다."],
        "ask_trust": ["신뢰는 변수다. 검증은 상수다. 검증해라.", "나를 믿을 이유는 없다. 다만 나를 의심할 근거도 아직 없다."]
    }
}

static func intent_pool(npc_id: String, key: String) -> Array:
    return EXTRA_INTENTS.get(npc_id, {}).get(key, [])
