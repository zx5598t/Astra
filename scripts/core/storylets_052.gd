class_name AstraStorylets052
extends RefCounted

# Mid/late-game authored library. These scenes expand what can happen without
# increasing the mandatory first-30-minute reading load. RNG only selects among
# already-authored storylets; it never writes dialogue.

const MID_CHAPTERS := ["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]

# [tag, category, family, action, line, optional metadata]
# Counts intentionally differ by speaker. The library is not a quota spreadsheet.
const CHARACTER_PACKS := {
    "rho": [
        ["work","WORK","hands_first","준이 진동이 다른 배관 두 개에 차례로 손을 댄다.","왼쪽이 먼저 떨렸어. 로그는 오른쪽부터 찍혔고."],
        ["everyday","HUMOR","bad_coffee","준이 커피를 한 모금 마시고 공구보다 먼저 컵을 내려놓는다.","이건 누가 고친다고 해결될 맛이 아니다."],
        ["observation","MYSTERY","missing_tool","준이 공구판의 빈 자리에 손가락을 넣어 깊이를 재 본다.","렌치가 없어진 건 맞는데, 가져간 사람은 작은 걸 찾았던 것 같아."],
        ["work","WORK","manual_check","준이 자동 진단을 끄고 차단기를 손으로 한 번씩 눌러 본다.","기계가 자기 검사까지 속이면 손으로 남는 느낌부터 보자."],
        ["personal","PERSONAL","daren_respect","준이 구기려던 계산표를 다시 펴 놓는다. 다렌이 만든 표다.","짜증 나는 건 맞는데, 저 계산 없으면 나도 못 고쳐."],
        ["danger","CRISIS","joke_stops","경보음이 울리자 준의 표정에서 장난기가 바로 사라진다.","뒤로 가. 이건 내가 먼저 볼게.",{"deviation_reason":"FEAR","source_event":"danger_alarm","possible_followup":"rho_after_alarm","rarity":"uncommon"}],
        ["observation","MYSTERY","heat_trace","준이 식은 패널 한쪽에서 아직 남은 열을 손등으로 확인한다.","꺼진 시간하고 식은 시간이 안 맞아."],
        ["everyday","DAILY","shared_food","준이 비상식량을 반으로 부러뜨려 한쪽을 밀어 준다.","맛없을 땐 양이라도 줄여야지."],
        ["work","WORK","repair_order","준이 나사를 풀기 전에 조립 순서를 바닥에 먼저 놓는다.","나중에 누가 손댔는지 보려면 원래 순서부터 남겨야 해."],
        ["personal","PERSONAL","sena_distance","준이 세나 이름이 적힌 점검표를 보다가 펜을 내려놓는다.","이번엔 내가 먼저 물어보면 더 꼬일 것 같네."],
        ["observation","MYSTERY","wrong_screw","준이 같은 모양의 나사 둘을 굴려 소리를 비교한다.","하나는 여기 물건이 아니야. 모양만 맞춘 거야."],
        ["work","WORK","backup_fuse","준이 예비 퓨즈 수량을 두 번 센 뒤 자기 주머니를 뒤집는다.","좋아, 이번 건 내 실수 아니네. 그럼 더 귀찮아졌고."],
        ["personal","RELATIONSHIP","player_tool","준이 작업대 한쪽의 작은 드라이버를 알아본다. 당신이 주워 둔 것이다.","그거 아직 갖고 있었네. 내가 잃어버린 줄 알았는데.",{"choices":[{"label":"드라이버를 건넨다.","effect":"help"},{"label":"“나중에 필요할 것 같아서.”","effect":"record"}]}],
        ["conflict","CONFLICT","daren_method","준이 ‘정상 범위’ 표시 위에 진동 파형을 겹친다. 다렌의 계산과 어긋난다.","정상 범위가 정상 소리를 보장하진 않아."],
        ["echo","ECHO","old_scratch","준이 자신이 냈다고 기억하는 흠집 옆의 낯선 흠집을 오래 본다.","내 실수는 내가 기억해. 저건… 아닌데.",{"requires":{"min_loop":1},"rarity":"rare","deviation_reason":"MEMORY_MISMATCH","source_event":"panel_scratch","possible_followup":"compare_old_panel"}],
        ["silence","MOOD","quiet_jun","준이 열린 패널 앞에서 공구를 든 채 한동안 아무것도 만지지 않는다.","",{"requires":{"min_loop":1},"rarity":"rare","deviation_reason":"RECENT_CONFLICT","source_event":"pair_argument","possible_followup":"rho_explains_pause"}]
    ],
    "lyra": [
        ["everyday","DAILY","herb_smell","마렌이 배급 수프에 말린 허브를 아주 조금 부순다.","맛보다 냄새가 먼저 사람 사는 곳 같아져요."],
        ["work","WORK","root_check","마렌이 잎 대신 투명 배양통 아래의 뿌리를 비춘다.","위가 멀쩡해도 아래가 상하면 늦어요."],
        ["observation","MYSTERY","extra_seed","마렌이 라벨보다 두 알 많은 씨앗을 손바닥에 올린다.","없어진 것보다 생긴 게 더 무서울 때도 있어요."],
        ["personal","PERSONAL","mira_plant","마렌이 작은 화분 하나를 의료실 방향으로 들었다 놓는다.","미라 방에 초록색이 하나쯤 있으면 좋겠어요."],
        ["work","WORK","dark_cycle","마렌이 조명을 예정 시간보다 일찍 끄고 잎의 방향을 본다.","계속 밝으면 망가져요. 깨어 있는 게 늘 좋은 건 아니에요."],
        ["everyday","DAILY","clean_tray","마렌이 빈 재배 트레이를 다 씻고도 물기를 한참 닦는다.","다시 심을지 몰라도 더럽게 비워 두긴 싫어요."],
        ["observation","MYSTERY","old_sample","마렌이 오래된 표본과 새 표본의 색을 나란히 둔다.","같은 종이면 환경이나 시간이 달랐다는 뜻이에요."],
        ["personal","RELATIONSHIP","daren_numbers","마렌이 생존 표에서 수치 대신 샘플 이름에 밑줄을 긋는다. 다렌의 계산표다.","숫자는 다렌이 기억할 거예요. 저는 이게 뭐였는지 기억할게요."],
        ["crisis","CRISIS","cold_choice","마렌이 산소 소비표를 보고 시든 모종 세 개를 한쪽으로 옮긴다.","전부 살릴 수 없으면 먼저 사람 숨 쉴 공기부터 남겨야 해요.",{"deviation_reason":"FEAR","source_event":"resource_shortage","possible_followup":"lyra_after_choice","rarity":"uncommon"}],
        ["work","WORK","humidity_feel","마렌이 습도계를 보기 전에 손등으로 공기를 느낀다.","오늘은 느낌이 틀렸네요. 숫자를 다시 믿어야겠어요."],
        ["everyday","HUMOR","label_names","마렌이 화분 세 개에 승무원 이름을 붙였다가 황급히 떼어 낸다.","성격 닮았다고 붙인 건데… 본인들이 보면 화내겠죠?"],
        ["observation","MYSTERY","red_label","마렌이 빨간 라벨 하나를 위험 표본과 따로 둔다.","이 색은 위험이 아니라 다시 확인이라는 뜻이에요."],
        ["personal","PERSONAL","saved_seed","마렌이 폐기 목록에 있는 씨앗 하나를 주머니에서 꺼낸다.","버려야 하는 건 알아요. 그래도 한 번만 더 보고 싶었어요.",{"choices":[{"label":"“아직 공개하지 않을게요.”","effect":"promise"},{"label":"기록에는 남겨 둔다.","effect":"record"}]}],
        ["echo","ECHO","familiar_soil","마렌이 낯선 흙 봉투를 열기 전에 냄새부터 맡고 멈춘다.","이 냄새… 처음은 아닌 것 같아요.",{"requires":{"min_loop":1},"rarity":"rare","deviation_reason":"MEMORY_MISMATCH","source_event":"old_sample_echo","possible_followup":"compare_soil_origin"}],
        ["silence","MOOD","lost_brightness","마렌이 들어오는 사람마다 인사하던 날과 달리, 오늘은 표본 숫자만 세고 있다.","",{"requires":{"min_loop":1},"rarity":"rare","deviation_reason":"GRIEF_ECHO","source_event":"previous_loss","possible_followup":"lyra_small_kindness"}]
    ],
    "noa": [
        ["observation","MYSTERY","exact_quote","노아가 같은 문장을 두 번 적고 조사 하나만 동그라미 친다.","어제는 ‘봤다’고 했고 오늘은 ‘확인했다’고 했어요."],
        ["work","WORK","margin_note","노아가 원문을 고치지 않고 여백에만 작은 메모를 남긴다.","틀렸다고 지우면 왜 틀렸는지까지 없어져요."],
        ["everyday","DAILY","short_pencil","노아가 거의 끝난 연필에 캡을 끼워 다시 쓴다.","아직 한 줄은 더 쓸 수 있어요."],
        ["observation","MYSTERY","silence_stamp","노아가 회의 녹음의 침묵 구간에도 시간을 찍는다.","아무도 대답하지 않은 것도 발언의 일부예요."],
        ["personal","PERSONAL","private_copy","노아가 기록 한 장을 파일철이 아니라 자기 노트 안에 넣는다.","원본인지 확인될 때까지만 제가 들고 있을게요.",{"choices":[{"label":"“나한테 먼저 보여줘.”","effect":"share"},{"label":"그대로 보관하게 둔다.","effect":"wait"}]}],
        ["work","WORK","two_titles","노아가 같은 체크섬의 파일 두 개에 다른 제목이 붙은 것을 표시한다.","내용은 같은데 이름만 달라요. 누군가 분류를 바꿨어요."],
        ["everyday","HUMOR","meal_record","노아가 배급표 구석의 ‘준 두 번’을 보고 작게 웃는다.","본인이 먼저 인정했으니 사건 기록에서는 뺄게요."],
        ["observation","MYSTERY","folded_page","노아가 접힌 종이를 펴 반대쪽 눌린 글씨를 읽는다.","이 부분만 안 보이게 접었어요. 우연치고는 정확해요."],
        ["personal","RELATIONSHIP","daren_order","노아가 원인순 정렬과 자신의 시간순 정렬을 둘 다 남긴다. 앞쪽은 다렌이 만든 것이다.","어느 쪽이 맞는지보다 둘이 왜 다르게 보이는지가 먼저예요."],
        ["conflict","CONFLICT","cold_reply","노아가 목소리를 높이지 않고 상대가 방금 쓴 단어를 그대로 돌려준다.","‘없었다’고 했어요. ‘기억나지 않는다’가 아니라.",{"deviation_reason":"RECENT_CONFLICT","source_event":"changed_statement","possible_followup":"noa_delayed_question","rarity":"uncommon"}],
        ["work","WORK","cross_index","노아가 사람 이름 대신 사건 시각으로 기록철 색인을 다시 만든다.","사람부터 보면 의심이 기록을 끌고 가요."],
        ["observation","MYSTERY","duplicate_minute","노아가 07:37이 두 번 찍힌 로그를 나란히 놓는다.","같은 분인데 둘 다 다음 문장이 달라요."],
        ["echo","ECHO","unknown_handwriting","노아가 자기 필체와 닮은 메모를 보고도 곧바로 자기 것이라 쓰지 않는다.","닮았다고 같은 사람이 쓴 건 아니에요. 그런데 너무 닮았네요.",{"requires":{"min_loop":1},"rarity":"rare","deviation_reason":"MEMORY_MISMATCH","source_event":"meta_note","possible_followup":"handwriting_compare"}],
        ["silence","MOOD","delete_pause","노아가 삭제 확인 창 위에 손을 올렸다가 당신을 보고 그대로 멈춘다.","",{"rarity":"rare","deviation_reason":"HIDDEN_SECRET","source_event":"private_record","possible_followup":"ask_noa_deleted_record"}]
    ],
    "mira": [
        ["work","WORK","patient_first","미라가 단말 경고보다 옆 사람의 손 떨림을 먼저 확인한다.","로그는 잠깐 기다려도 돼요. 이 사람부터 볼게요."],
        ["everyday","DAILY","warm_room","미라가 실내 온도를 0.5도 올리고 사람들 표정을 살핀다.","같은 온도도 수면 뒤엔 더 춥게 느껴져요."],
        ["observation","MYSTERY","double_pulse","미라가 겹친 맥박 기록 두 줄을 확대한다.","센서는 하나인데 맥박이 두 번 있어요."],
        ["personal","PERSONAL","own_chart","미라가 자기 차트를 다른 사람 기록 옆에 놓는다.","저도 같은 기준으로 봐 주세요. 예외가 되면 더 이상해요."],
        ["work","WORK","medicine_gap","미라가 빈 진통제 칸을 채우지 않고 사용 기록부터 연다.","누가 썼는지보다 먼저 괜찮은지 확인해야 해요."],
        ["everyday","DAILY","quiet_music","미라가 아주 작은 볼륨으로 오래된 피아노 곡을 틀어 둔다.","너무 조용하면 오히려 사람 숨소리가 신경 쓰여서요."],
        ["personal","RELATIONSHIP","sena_bandage","미라가 세나가 두고 간 붕대를 접어 서랍 맨 앞에 둔다.","안 다쳤다면서 꼭 하나씩 쓰고 가요."],
        ["observation","MYSTERY","shoe_order","미라가 출입문 앞의 뒤엉킨 신발 방향을 본다.","급하게 나간 사람은 신발이 먼저 말해 줄 때가 있어요."],
        ["danger","CRISIS","firm_medic","미라가 부드러운 목소리를 거두고 의료실 문을 닫는다.","지금은 토론 안 해요. 산소부터 연결해요.",{"deviation_reason":"INJURY","source_event":"medical_emergency","possible_followup":"mira_checks_self_last","rarity":"uncommon"}],
        ["personal","PERSONAL","empty_bed","미라가 빈 침상에 담요를 펴다가 다시 접는다.","없는 사람 자리까지 준비하는 습관은 잘 안 없어지네요."],
        ["work","WORK","paper_backup","미라가 전자 차트 옆에 종이 메모를 한 장 더 붙인다.","화면과 제 글씨가 둘 다 다르면 그때 진짜 이상한 거죠."],
        ["echo","ECHO","familiar_bandage","미라가 낯선 상처 위치를 보고 이미 붕대를 꺼내 든 자신을 알아차린다.","왜 여기 다칠 거라고 생각했을까요?",{"requires":{"min_loop":1},"rarity":"rare","deviation_reason":"PROTECTION_ECHO","source_event":"prior_protection","possible_followup":"mira_protects_same_person"}],
        ["silence","MOOD","self_neglect","미라가 다른 사람 체온을 모두 기록한 뒤 자기 센서를 켜지 않은 채 의자에 앉는다.","",{"deviation_reason":"FEAR","source_event":"crew_injury","possible_followup":"player_checks_mira","rarity":"rare"}]
    ],
    "sena": [
        ["work","WORK","door_first","세나가 방에 들어오자마자 대화보다 비상문 잠금부터 확인한다.","얘기는 문 확인하고 해. 열려 있으면 다 의미 없어."],
        ["observation","MYSTERY","footprint","세나가 흐릿한 발자국 하나보다 발자국이 끊긴 지점을 본다.","여기서 사라진 게 아니라, 여기서 신발을 바꾼 거야."],
        ["everyday","DAILY","seat_angle","세나가 의자를 출입문이 보이는 각도로 돌려 놓는다.","등지고 앉는 건 취향이 아니야."],
        ["personal","PERSONAL","old_accident","세나가 오래된 사고 보고서의 자기 서명 부분만 접어 둔다.","책임자 이름은 나로 충분해. 나머지는 다시 확인하자."],
        ["work","WORK","patrol_map","세나가 순찰 경로에 가장 짧은 길 대신 사람이 많은 길을 표시한다.","빠른 길보다 누가 있는지 보는 길이 나아."],
        ["conflict","CONFLICT","public_rebuttal","세나가 플레이어 쪽을 보지 않은 채 회의 반박을 먼저 받는다.","지난번 말은 기억해. 이번엔 근거부터 보여 줘."],
        ["danger","CRISIS","body_block","소리가 나자 세나가 질문도 없이 사람들 앞을 막는다.","뒤로. 내가 먼저 간다.",{"deviation_reason":"PROTECTION_ECHO","source_event":"threat_noise","possible_followup":"sena_explains_protection","rarity":"uncommon"}],
        ["everyday","HUMOR","bad_rest","세나가 휴식표에 자기 이름을 쓰고 바로 순찰표를 다시 연다.","썼잖아. 쉬겠다고. 언제인지는 안 썼고."],
        ["observation","MYSTERY","camera_gap","세나가 영상이 없는 12초보다 그 직전 문이 열린 횟수를 센다.","화면이 없을 때 누가 준비했는지가 더 중요해."],
        ["personal","RELATIONSHIP","jun_history","세나가 준의 공구 소리만 듣고 어느 패널인지 맞힌다.","저 소리 아직도 저렇게 내네."],
        ["echo","ECHO","stranger_jun","세나가 준이 건넨 공구를 잠깐 낯선 사람 물건처럼 내려다본다.","…내가 이걸 왜 익숙하게 받았지?",{"requires":{"min_loop":1},"rarity":"rare","deviation_reason":"MEMORY_MISMATCH","source_event":"pair_history_shift","possible_followup":"sena_jun_compare"}],
        ["silence","MOOD","watch_player","세나가 평소처럼 앞장서지 않고 이번에는 당신이 어느 문을 고르는지 먼저 본다.","",{"deviation_reason":"RECENT_CONFLICT","source_event":"player_public_rebuttal","possible_followup":"sena_retests_trust","rarity":"rare"}]
    ],
    "dax": [
        ["work","WORK","blank_cell","다렌이 표의 빈칸 하나를 끝까지 채우지 않는다.","모르면 비워 둬. 억지 숫자가 제일 위험해."],
        ["observation","MYSTERY","two_clocks","다렌이 벽시계와 단말 시계를 같은 화면에 놓는다.","11초 차이. 사건 창에서는 충분히 커."],
        ["everyday","DAILY","dilute_drink","다렌이 너무 진한 음료에 물을 정확히 두 번 나눠 붓는다.","준이 만들면 측정이 없어. 결과는 늘 비슷하고."],
        ["work","WORK","checksum_first","다렌이 파일 제목을 읽기 전에 체크섬부터 대조한다.","문장이 같아도 파일은 다를 수 있어."],
        ["personal","RELATIONSHIP","noa_method","다렌이 노아의 시간순 메모를 자기 원인순 표 옆에 그대로 붙인다.","둘 다 남겨. 차이가 있으면 그게 정보야."],
        ["observation","MYSTERY","sensor_noise","다렌이 작은 흔들림을 확대하지 않고 반복 횟수부터 센다.","한 번이면 잡음. 같은 방향 세 번이면 사건."],
        ["conflict","CONFLICT","admit_wrong","다렌이 자기 계산식 한 줄에 직접 취소선을 긋는다.","내가 틀렸네. 그럼 준이 들었다는 소리부터 다시 보자."],
        ["work","WORK","route_math","다렌이 루칸 항로 위에 연료 소비선을 겹친다.","같은 여행이면 연료도 같은 이야기를 해야 해."],
        ["personal","PERSONAL","old_failure","다렌이 과거 승인 기록에서 자기 이름을 숨기지 않고 화면 중앙에 둔다.","내 판단 때문에 생긴 일이면 그 조건부터 다시 써야 해."],
        ["echo","ECHO","repeated_formula","다렌이 이미 맞은 계산을 세 번째로 처음부터 다시 적는다.","값은 같은데 내가 이걸 왜 계속 확인하지?",{"requires":{"min_loop":1},"rarity":"rare","deviation_reason":"FEAR","source_event":"grief_echo","possible_followup":"dax_accepts_observation"}],
        ["silence","MOOD","listen_first","다렌이 평소라면 계산부터 했을 문제 앞에서 준의 설명이 끝날 때까지 펜을 들지 않는다.","",{"rarity":"rare","deviation_reason":"PAIR_HISTORY","source_event":"professional_conflict_shift","possible_followup":"dax_uses_jun_observation"}]
    ],
    "eli": [
        ["observation","MYSTERY","whole_route","루칸이 현재 좌표를 확대하지 않고 항로 전체를 한 화면에 맞춘다.","한 점은 틀릴 수 있어. 경로 전체가 틀리려면 이유가 필요해."],
        ["work","WORK","fuel_line","루칸이 경로와 연료 소비선을 나란히 놓는다.","둘 중 하나가 다른 여행 얘기를 하고 있어."],
        ["everyday","DAILY","seat_belt","루칸이 앉지도 않으면서 의자 안전벨트를 반듯하게 편다.","쓸 일 없어도 꼬여 있으면 거슬려."],
        ["observation","MYSTERY","fixed_star","루칸이 창밖 별 하나를 기준점으로 잠근다.","기록이 바뀌어도 저 별까지 같이 움직이진 않아."],
        ["personal","PERSONAL","paper_map","루칸이 오래된 종이 별지도를 화면 옆에 붙인다.","업데이트 안 되는 게 장점일 때도 있어."],
        ["work","WORK","route_gap","루칸이 항로의 빈 구간 앞뒤 좌표만 표시한다.","없는 구간을 상상으로 메우지 말자."],
        ["personal","RELATIONSHIP","soren_coordinate","루칸이 소렌이 들은 시각을 좌표에만 표시하고 음성 내용은 적지 않는다.","나는 소리를 못 믿어도 위치는 줄 수 있어."],
        ["echo","ECHO","known_turn","루칸이 낯선 항로의 다음 회전을 화면보다 먼저 손으로 짚는다.","…왜 다음이 여기라고 알고 있었지?",{"requires":{"min_loop":1},"rarity":"rare","deviation_reason":"MEMORY_MISMATCH","source_event":"route_echo","possible_followup":"eli_route_compare"}],
        ["silence","MOOD","door_watch","루칸이 걱정된 사람에게 말을 걸지 않고 그 사람이 나간 문 방향만 오래 본다.","",{"rarity":"uncommon"}]
    ],
    "vale": [
        ["work","WORK","silent_gap","소렌이 소리가 없는 4초 구간을 세 번 재생한다.","없는 것도 반복되면 패턴이에요."],
        ["observation","MYSTERY","room_tone","소렌이 방마다 10초씩 아무 말도 하지 않고 녹음한다.","문이 열리면 사람 목소리보다 방 소리가 먼저 바뀌어요."],
        ["everyday","DAILY","one_ear","소렌이 이어폰 한쪽만 끼고 다른 쪽은 목에 건다.","둘 다 끼면 누가 부르는 걸 놓쳐요."],
        ["personal","PERSONAL","skip_song","소렌이 재생 목록의 한 곡을 이유 없이 건너뛴다.","이건 지금은 못 듣겠어요. 나중에 말할게요."],
        ["echo","ECHO","sleep_voice","소렌이 자기 목소리 파형에서 숨을 들이마시는 부분만 반복한다.","제 목소리인데, 제가 깨어 있을 때보다 숨이 느려요.",{"requires":{"min_loop":1},"rarity":"rare","deviation_reason":"MEMORY_MISMATCH","source_event":"sleep_signal","possible_followup":"vale_compare_breath"}],
        ["silence","MOOD","signal_before_person","누군가 소렌을 부르지만 그는 대답보다 먼저 헤드셋의 작은 잡음을 끝까지 듣는다.","",{"rarity":"uncommon"}]
    ]
}

const SOCIAL_SCENES := [
    {"id":"052_pair_rho_sena_wait","speaker":"rho","target":"sena","tag":"pair","category":"PAIR","family":"rho_sena_work","intent":"relationship","action":"준이 보안실 문턱에 공구함을 내려놓고 세나의 점검이 끝날 때까지 기다린다.","lines":[["rho","끝나면 기관실 한 번만 같이 봐 줘."],["sena","혼자 가기 싫어?"],["rho","네가 보면 내가 놓친 걸 꼭 찾아. 그게 짜증나게 유용해서."]],"choices":[],"chapters":MID_CHAPTERS},
    {"id":"052_pair_rho_sena_overheard","speaker":"sena","target":"rho","tag":"pair","category":"PAIR","family":"rho_sena_conflict","intent":"overheard","action":"문 밖에서 두 사람 목소리가 먼저 들린다.","lines":[["rho","난 분명 그때 거기 없었어."],["sena","그 얘기 어제는 안 했잖아."]],"choices":[{"label":"“무슨 얘기야?”","effect":"confront"},{"label":"말없이 기다린다.","effect":"wait"},{"label":"그냥 지나간다.","effect":"withhold"}],"chapters":MID_CHAPTERS},
    {"id":"052_pair_dax_noa_sort","speaker":"dax","target":"noa","tag":"pair","category":"PAIR","family":"dax_noa_method","intent":"work","action":"다렌과 노아가 같은 로그를 서로 반대 방향으로 정렬한다.","lines":[["dax","원인순이면 이 줄이 먼저야."],["noa","시간순이면 이 문장이 먼저예요."],["dax","둘 다 남겨. 차이가 정보니까."]],"choices":[],"chapters":MID_CHAPTERS},
    {"id":"052_pair_dax_noa_pause","speaker":"noa","target":"dax","tag":"pair","category":"PAIR","family":"dax_noa_trust","intent":"relationship","action":"노아가 다렌 계산 옆에 물음표 하나만 적는다.","lines":[["dax","틀렸다는 뜻이야?"],["noa","아니요. 아직 못 따라갔다는 뜻이에요."]],"choices":[],"chapters":MID_CHAPTERS},
    {"id":"052_pair_mira_lyra_rest","speaker":"lyra","target":"mira","tag":"pair","category":"PAIR","family":"mira_lyra_care","intent":"relationship","action":"마렌이 창가에 작은 화분을 놓고 미라의 손을 본다.","lines":[["lyra","화분은 제가 챙길게요. 미라는 잠을 챙겨요."],["mira","그 말, 제가 더 자주 하는 말인데요."]],"choices":[],"chapters":MID_CHAPTERS},
    {"id":"052_pair_vale_eli_blind","speaker":"vale","target":"eli","tag":"pair","category":"PAIR","family":"vale_eli_signal","intent":"work","action":"소렌이 재생 위치를 가린 채 이어폰 한쪽을 루칸에게 건넨다.","lines":[["vale","시간 안 보고 들어 봐요."],["eli","여기서 바뀌네."],["vale","그 지점 좌표만 주세요."]],"choices":[],"chapters":MID_CHAPTERS},
    {"id":"052_pair_lyra_dax_leaf","speaker":"lyra","target":"dax","tag":"pair","category":"PAIR","family":"lyra_dax_evidence","intent":"work","action":"마렌이 성장표 대신 잎 하나를 다렌 앞에 놓는다.","lines":[["dax","성장률은 정상 범위야."],["lyra","잎 방향은 아니에요."],["dax","좋아. 숫자가 못 잡은 변수 하나 추가."]],"choices":[],"chapters":MID_CHAPTERS},
    {"id":"052_pair_noa_vale_words","speaker":"noa","target":"vale","tag":"pair","category":"PAIR","family":"noa_vale_record","intent":"work","action":"노아가 소렌의 음성을 듣기 전에 자신이 예상한 문장을 가려 둔다.","lines":[["vale","왜 가렸어요?"],["noa","제가 먼저 읽으면 그렇게 들릴까 봐요."]],"choices":[],"chapters":MID_CHAPTERS},
    {"id":"052_pair_sena_mira_door","speaker":"sena","target":"mira","tag":"pair","category":"PAIR","family":"sena_mira_protect","intent":"relationship","action":"세나가 치료 구역 문을 절반만 열어 두고 복도를 확인한다.","lines":[["mira","그냥 닫아도 돼요."],["sena","안 돼. 안에서 무슨 일 생기면 바로 들어와야 해."]],"choices":[],"chapters":MID_CHAPTERS},
    {"id":"052_pair_rho_dax_sound","speaker":"rho","target":"dax","tag":"pair","category":"PAIR","family":"rho_dax_respect","intent":"conflict","action":"준이 정상 판정 옆에 녹음기를 올려놓는다. 판정표는 다렌이 만든 것이다.","lines":[["rho","숫자로는 정상이지?"],["dax","평균은."],["rho","그럼 평균 말고 이 소리도 들어."]],"choices":[],"chapters":MID_CHAPTERS},
    {"id":"052_pair_sena_rho_silent","speaker":"sena","target":"rho","tag":"pair","category":"PAIR","family":"sena_rho_silence","intent":"silence","action":"세나가 준의 작업등 각도만 조용히 바꾼다. 준은 항의하려다 볼트가 더 잘 보이는 걸 확인하고 입을 다문다.","lines":[],"choices":[],"chapters":MID_CHAPTERS},
    {"id":"052_pair_noa_mira_record","speaker":"noa","target":"mira","tag":"pair","category":"PAIR","family":"noa_mira_fact","intent":"record","action":"노아가 미라의 의료 판단을 인용하려다 문장을 지운다.","lines":[["mira","왜 지웠어요?"],["noa","정확히 같은 말인지 자신 없어서요. 뜻과 문장을 나눠 둘게요."]],"choices":[],"chapters":MID_CHAPTERS},
    {"id":"052_trio_rho_sena_mira","speaker":"rho","tag":"trio","participants":["rho","sena","mira"],"category":"PAIR","family":"trio_repair_security","intent":"work","action":"준과 세나의 말이 겹치자 미라가 둘 사이에 물병을 하나씩 내려놓는다.","lines":[["rho","배선은 내가 보면 돼."],["sena","누가 끊었는지가 문제야."],["mira","둘 다 맞아요. 하나씩 보고 다시 모여요."]],"choices":[],"chapters":MID_CHAPTERS},
    {"id":"052_trio_dax_noa_eli","speaker":"dax","tag":"trio","participants":["dax","noa","eli"],"category":"MYSTERY","family":"trio_time_route","intent":"record","action":"다렌, 노아, 루칸이 시간표·기록·항로를 같은 화면에 겹친다.","lines":[["noa","문장은 07:37이에요."],["eli","경로 보정은 07:39."],["dax","센서 재시작은 그 사이. 순서가 문제네."]],"choices":[],"chapters":MID_CHAPTERS},
    {"id":"052_trio_mira_lyra_sena","speaker":"lyra","tag":"trio","participants":["mira","lyra","sena"],"category":"CRISIS","family":"trio_air","intent":"work","action":"마렌이 시든 잎을 들고 오자 세나가 문을 열고 미라는 산소 기록을 띄운다.","lines":[["lyra","물 부족이 아니에요. 공기가 달랐어요."],["sena","환기 구역 출입부터 볼게."],["mira","저는 같은 시간 사람 상태를 확인할게요."]],"choices":[],"chapters":MID_CHAPTERS},
    {"id":"052_trio_noa_vale_eli","speaker":"noa","tag":"trio","participants":["noa","vale","eli"],"category":"MYSTERY","family":"trio_signal_route","intent":"record","action":"노아가 소렌의 파형과 루칸의 좌표를 한 문서에 나란히 붙인다.","lines":[["noa","같은 시각이라고 쓰진 않을게요."],["vale","반복 간격은 제가 줄게요."],["eli","위치는 내가 줄게. 겹치는 곳만 보자."]],"choices":[],"chapters":MID_CHAPTERS}
]

static func _scene_from_pack(npc_id: String, index: int, pack: Array) -> Dictionary:
    var meta: Dictionary = pack[5] if pack.size() > 5 and pack[5] is Dictionary else {}
    var line := str(pack[4])
    var scene := {
        "id":"052_%s_%02d" % [npc_id,index],
        "speaker":npc_id,
        "tag":str(pack[0]),
        "category":str(pack[1]),
        "family":str(pack[2]),
        "intent":str(meta.get("intent",pack[0])),
        "action":str(pack[3]),
        "lines":[] if line == "" else [[npc_id,line]],
        "choices":Array(meta.get("choices",[])).duplicate(true),
        "chapters":Array(meta.get("chapters",MID_CHAPTERS)).duplicate()
    }
    for key in ["requires","forbids","rarity","deviation_reason","source_event","possible_followup"]:
        if meta.has(key):
            scene[key] = meta[key]
    return scene

static func scenes() -> Array:
    var result: Array = []
    for npc_id in CHARACTER_PACKS:
        var packs: Array = CHARACTER_PACKS[npc_id]
        for index in range(packs.size()):
            result.append(_scene_from_pack(str(npc_id),index,packs[index]))
    for scene in SOCIAL_SCENES:
        result.append(Dictionary(scene).duplicate(true))
    return result

static func count_by_speaker() -> Dictionary:
    var result := {}
    for scene in scenes():
        var speaker := str(scene.get("speaker",""))
        result[speaker] = int(result.get(speaker,0)) + 1
    return result

static func private_social_counts() -> Dictionary:
    var pair := 0
    var trio := 0
    for scene in SOCIAL_SCENES:
        if str(scene.get("tag","")) == "pair":
            pair += 1
        elif str(scene.get("tag","")) == "trio":
            trio += 1
    return {"pair":pair,"trio":trio}
