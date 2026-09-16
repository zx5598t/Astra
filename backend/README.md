# ASTRA AI Backend — 0.0.6

Godot 클라이언트에 API 키를 넣지 않기 위한 선택형 로컬/서버 백엔드입니다.
백엔드를 실행하지 않아도 게임은 규칙 기반 fallback으로 계속 플레이됩니다.

## 실행
```bash
cd backend
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
```

`.env.example`을 참고해 환경변수 `OPENAI_API_KEY`를 설정한 뒤:
```bash
uvicorn app:app --host 127.0.0.1 --port 8787
```

Godot은 기본적으로 `http://127.0.0.1:8787/npc/action`을 호출합니다.

## 0.0.6
- 개인 심문 AI 연기
- 공개 회의 일부 발언 AI 연기
- 최근 대화와 허용된 canonical fact만 전달
- 공개 회의에서는 기존 규칙 기반 발언의 의도/대상은 유지

## 보안 원칙
- API 키를 Godot 프로젝트나 GitHub에 커밋하지 않습니다.
- 백엔드는 허용된 fact ref와 target만 통과시킵니다.
- 모델 출력은 표현 계층이며 TruthEngine/역할/증거/투표/승패를 수정하지 않습니다.
