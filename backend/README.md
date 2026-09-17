# ASTRA AI Backend (선택 사항)

Godot 클라이언트에 API 키를 넣지 않기 위한 로컬 서버입니다. **켜지 않아도 게임의 모든 기능이 동작합니다.**
켜면 심문 대사를 모델이 캐릭터 말투로 다시 연기합니다. 계약은 `docs/AI_CONTRACT.md`를 보세요.

## 실행
```bash
cd backend
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
```

`.env.example`을 참고해 `OPENAI_API_KEY`(필요하면 `ASTRA_OPENAI_MODEL`)를 설정한 뒤:
```bash
uvicorn app:app --host 127.0.0.1 --port 8787
```

## 게임에서 켜기
설정 → **AI 연기 사용** 켜기 → 주소가 `http://127.0.0.1:8787/npc/action`인지 확인 → **연결 확인**.

## 보안 원칙
- API 키를 Godot 프로젝트나 GitHub에 커밋하지 않습니다.
- 백엔드는 허용된 단서 id와 대상만 통과시키고, 게임은 문구만 반영합니다.
