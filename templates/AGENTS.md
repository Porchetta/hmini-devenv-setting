# AGENTS.md

Claude Code와 Codex가 함께 읽는 프로젝트 규칙입니다. 프로젝트에 맞게 고쳐 쓰세요.

## 프로젝트 구조

- `backend/`: FastAPI 앱 (Python)
- `frontend/`: Vue 앱
- `STATUS.md`: 진행 상황과 인계 메모

## 명령

| 목적 | 명령 |
|---|---|
| 백엔드 의존성 | `cd backend && uv sync` |
| 백엔드 실행 | `cd backend && uv run fastapi dev app/main.py` |
| 백엔드 테스트 | `cd backend && uv run pytest -q` |
| 프론트 의존성 | `cd frontend && npm ci` |
| 프론트 실행 | `cd frontend && npm run dev` |
| 프론트 테스트 | `cd frontend && npm test -- --run` |
| 린트 | `cd backend && uv run ruff check .`, `cd frontend && npm run lint` |

## 작업 규칙

- 작업은 목표와 완료 조건을 먼저 정하고 시작한다. 완료 조건에는 통과해야 할 테스트 명령을 넣는다.
- 기능 하나당 브랜치 하나. 커밋은 작게 나눈다.
- 백엔드와 프론트를 동시에 바꿀 때는 API 스키마를 먼저 정하고 각자 맡은 폴더만 고친다.
- 새 동작에는 테스트를 같이 추가한다. 테스트를 끄거나 건너뛰어 통과시키지 않는다.
- 비밀이 아닌 설정은 `.env`, API 키 같은 비밀값은 `.env.confidential`에 둔다. 에이전트는 `.env.confidential`을 읽거나 커밋하지 않고, 키 이름은 `.env.confidential.example`에 적는다.
- 배포, 강제 푸시, 데이터 삭제처럼 되돌릴 수 없는 작업은 하지 않고 사람에게 묻는다.

## 인계 (STATUS.md)

작업을 멈추거나 사용 한도에 가까워지면 `STATUS.md`를 갱신한다.
다른 에이전트(Claude 또는 Codex)는 작업을 시작할 때 `STATUS.md`부터 읽는다.

## 리뷰

- PR 전에 리뷰를 한 번 받는다. Claude 세션에서는 `/codex:review`, Codex 세션에서는 reviewer 에이전트.
- 리뷰 지적은 고치거나, 고치지 않는 이유를 PR 설명에 적는다.
