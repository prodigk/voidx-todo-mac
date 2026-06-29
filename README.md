# VoidX Todo Mac

VoidX Todo Mac은 개인용 로컬 macOS Todo 앱입니다. SwiftUI로 작성되어 있으며, Today / Week / Month / Routines / Notes / Completed 흐름을 중심으로 할 일과 반복 일정을 빠르게 관리하는 것을 목표로 합니다.

이 프로젝트는 외부 서버, 로그인, 협업, 클라우드 동기화 없이 로컬 JSON 저장 방식으로 동작합니다.

## 핵심 방향

- 오늘 해야 할 일을 가장 빠르게 확인하고 추가할 수 있어야 합니다.
- 주간 / 월간 화면은 세부 편집보다 업무 밀도 파악을 우선합니다.
- 반복 Todo는 매주 / 매월 규칙부터 단순하고 안정적으로 지원합니다.
- Notes는 Todo와 독립된 가벼운 메모장으로 유지합니다.
- UI는 `DESIGN-cohere.md`의 차분한 Cohere 스타일을 기준으로 개선합니다.

## 프로젝트 구조

```text
Sources/VoidXTodoMac
  Models/      Todo, Note, Recurrence, Category 모델
  Stores/      앱 상태와 Todo/Note 변경 로직
  Services/    저장, 캘린더, 반복 일정 계산
  Theme/       색상, 간격, 공통 스타일
  Views/       SwiftUI 화면과 재사용 컴포넌트

Sources/VoidXTodoWidget
  VoidX Today 위젯

docs/
  MVP-Design.md   앱 MVP 설계
  WIDGET-MVP.md   위젯 MVP 설계와 빌드 참고
```

## 현재 주요 동작

- Today / Week / Month는 완료된 Todo도 숨기지 않고 흐리게 표시합니다.
- 완료된 Todo는 각 날짜 또는 리스트의 하단으로 정렬됩니다.
- Today / Week / Month의 count chip은 완료 항목을 제외한 남은 Todo 개수를 표시합니다.
- Week / Month에서 반복 Todo가 아닌 일반 Todo는 다른 날짜 칸으로 드래그해서 날짜를 변경할 수 있습니다.
- 드래그로 날짜를 바꿀 때 기존 시간은 유지됩니다.
- 반복 Todo는 날짜별 occurrence로 표시되며, 캘린더에서 드래그 이동하지 않습니다.

## 요구 사항

- macOS 14 이상
- Xcode / Command Line Tools
- Swift 5.9 이상
- 위젯 포함 Xcode 프로젝트 재생성이 필요하면 `xcodegen`

`xcodegen`이 없다면 Homebrew로 설치할 수 있습니다.

```sh
brew install xcodegen
```

## 빌드와 실행

프로젝트 루트로 이동합니다.

```sh
cd /Users/ugen/Documents/GitHub/voidx-todo-mac
```

### 빠른 로컬 앱 빌드

`dist/VoidX Todo.app`을 새로 만들고 실행합니다.

```sh
./scripts/run-app.sh
```

이 스크립트는 다음 작업을 수행합니다.

- `swift build`
- 앱 아이콘 생성
- `dist/VoidX Todo.app` 재생성
- `VoidXTodoWidget.appex` 번들 포함
- ad-hoc codesign
- 앱 실행

### SwiftPM 빌드만 확인

앱 번들 생성 없이 컴파일만 확인합니다.

```sh
swift build
```

### Xcode 프로젝트 재생성

`project.yml` 변경 후 Xcode 프로젝트를 다시 생성합니다.

```sh
xcodegen generate
open VoidXTodoMac.xcodeproj
```

### 위젯 포함 설치 빌드

Xcode 빌드 결과물을 `/Applications`에 설치하고 위젯 등록을 시도합니다.

```sh
./scripts/install-widget-app.sh
```

위젯이 macOS 위젯 갤러리에 보이려면 유효한 Apple Developer Team으로 앱과 위젯 extension이 서명되어야 합니다.

## 데이터 저장 위치

앱 데이터는 사용자 Application Support 아래 JSON 파일로 저장됩니다.

```text
~/Library/Application Support/VoidXTodoMac/voidx-todo-data.json
```

데이터 모델을 변경할 때는 기존 JSON을 읽을 수 있도록 `decodeIfPresent` 또는 기본값 처리를 우선 고려합니다.

## 개발 지침

### 1. MVP 범위를 지킵니다

현재 우선순위는 로컬 개인 Todo 앱의 완성도입니다. iCloud sync, 알림, 로그인, 협업, 태그 고도화, 외부 캘린더 연동은 핵심 흐름이 안정된 뒤 검토합니다.

### 2. 화면 목적을 분명히 유지합니다

- Today: 빠른 확인, 빠른 추가, 빠른 완료
- Week: 이번 주 업무 분포 파악
- Month: 한 달 전체의 밀도 파악
- Routines: 반복 Todo 규칙 관리
- Notes: 독립적인 메모 작성
- Completed: 완료 내역 확인과 복구

새 기능을 추가할 때는 어느 화면의 목적을 강화하는지 먼저 확인합니다.
Today / Week / Month에서 완료 항목은 삭제하거나 숨기지 말고, 흐린 비활성 상태로 하단에 남겨 사용자가 하루의 처리 흐름을 볼 수 있게 합니다.

### 3. 디자인은 `DESIGN-cohere.md`를 기준으로 합니다

- 흰 캔버스, near-black 텍스트, deep green 포인트를 기본으로 합니다.
- 장식보다 정보 밀도, 얇은 구분선, 안정적인 간격을 우선합니다.
- 캘린더 화면은 색을 많이 쓰기보다 작은 count chip과 우선순위 표시로 밀도를 표현합니다.
- 새 색상, radius, spacing은 가능하면 `CohereTheme`에 먼저 추가합니다.

### 4. 상태 변경은 `TodoStore`를 통합니다

Todo, Note, Category를 바꾸는 로직은 가능한 한 `TodoStore`에 모읍니다. View는 상태를 직접 조작하기보다 store 메서드를 호출하도록 유지합니다.

### 5. 반복 일정 계산은 분리해서 다룹니다

반복 Todo는 원본 Todo와 특정 날짜의 occurrence가 분리되어 있습니다. 반복 일정 로직을 바꿀 때는 `RecurrenceService`와 `CalendarService`의 책임을 먼저 확인하고, View 내부에 날짜 계산을 늘리지 않습니다.
Week / Month의 드래그 날짜 이동은 일반 Todo에만 적용하고, 반복 Todo는 recurrence rule을 직접 수정하는 별도 흐름으로 다룹니다.

### 6. 저장 호환성을 깨지 않습니다

`TodoItem`, `NoteItem`, `RecurrenceRule`, `TodoCategory`의 Codable 구조를 변경할 때는 기존 사용자의 JSON 파일이 계속 열리도록 기본값과 마이그레이션 경로를 둡니다.

### 7. 작고 검증 가능한 단위로 개선합니다

기능을 추가한 뒤 최소한 다음을 확인합니다.

```sh
swift build
./scripts/run-app.sh
```

위젯, signing, Xcode 설정을 건드렸다면 다음도 확인합니다.

```sh
./scripts/install-widget-app.sh
```

## 개선 아이디어를 다룰 때의 원칙

1. 먼저 관련 문서를 확인합니다: `docs/MVP-Design.md`, `docs/WIDGET-MVP.md`, `DESIGN-cohere.md`.
2. 사용자 흐름을 망가뜨리지 않는 가장 작은 변경부터 적용합니다.
3. 모델 변경이 필요한 경우 저장 호환성부터 설계합니다.
4. UI 변경은 Today / Week / Month의 정보 밀도와 조작 속도를 해치지 않아야 합니다.
5. 빌드 스크립트, Xcode project, SwiftPM 설정 중 하나를 바꾸면 README도 함께 갱신합니다.

## 현재 제외하는 기능

- iCloud 동기화
- 로그인 / 계정
- 협업
- 모바일 앱
- 외부 캘린더 연동
- 복잡한 반복 규칙
- 알림 시스템

필요해지면 별도 설계 문서로 범위와 저장 모델을 먼저 정한 뒤 구현합니다.
