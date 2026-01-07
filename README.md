# 🍚 오늘순밥 (1000meal-app)

순천향대학교 천원의 아침밥 서비스 **오늘순밥**의 모바일 애플리케이션 레포지토리입니다.
<br>기존 웹 프론트엔드(`1000meal-fe`)의 **Next.js App Router 구조를 반영하여, 기능(Feature) 단위로 폴더를 구성**했습니다.

## 🛠️ 기술 스택

### 모바일 앱 환경

* **프레임워크**: Flutter 3.38.5 (Stable)
* **개발 언어**: Dart 3.10.4
* **안드로이드 SDK**: Android API 36 (VanillaIceCream)
* **iOS 도구**: Xcode 16.0, CocoaPods 1.16.2
* **JDK**: OpenJDK 21
* **UI 디자인**: Material Design 3
* **상태 관리**: Provider
* **네트워크**: Dio
* **로컬 저장소**: Flutter Secure Storage
* **아이콘**: Cupertino Icons, Material Icons

### 주요 라이브러리

* **통신 (HTTP)**: Dio (인터셉터, 전역 에러 처리 적용)
* **인증/보안**: Flutter Secure Storage (JWT 토큰 암호화 저장)
* **지도/웹뷰**: webview_flutter (지도 서비스)
* **날짜 처리**: intl (날짜 포맷팅)
* **유틸리티**: flutter_dotenv (환경변수 관리), shared_preferences (기본 설정 저장)

### 개발 도구

* **코드 검사**: flutter_lints
* **빌드 도구**: Gradle 8.14 (Android), CocoaPods 1.16.2 (iOS)* **패키지 매니저**: Pub

## 📂 프로젝트 구조

유지보수와 확장성을 고려하여 **Layered Architecture** 기반의 **Feature-first** 구조를 채택했습니다.

```
lib/
├── 📂 common/                  # 앱 전역에서 재사용되는 공통 리소스
│   ├── 📄 constants/           # 색상(Color), API 엔드포인트, 문자열 상수
│   ├── 📄 dio/                 # Dio 클라이언트 설정 (Header, Interceptor)
│   ├── 📄 utils/               # 날짜 변환, 포맷팅 등 유틸 함수
│   └── 📄 widgets/             # 공통 버튼, 로딩 인디케이터, 에러 위젯
│
├── 📂 features/                # 핵심 도메인별 비즈니스 로직 (Next.js App 폴더와 매칭)
│   ├── 🔐 auth/                # [로그인/회원가입]
│   │   ├── models/             # User 데이터 모델
│   │   ├── providers/          # 로그인 상태 관리 (AuthProvider)
│   │   ├── services/           # 로그인 API 호출
│   │   └── screens/            # 로그인, 회원가입 화면
│   │
│   ├── 🗺 map/                 # [지도/매장찾기]
│   │   ├── models/             # Marker 데이터 모델
│   │   ├── services/           # 지도 데이터 API
│   │   └── screens/            # 네이버 지도/WebView 화면
│   │
│   ├── 🏪 store/               # [매장상세/메뉴]
│   │   ├── models/             # Menu, Store 모델
│   │   ├── services/           # 메뉴 목록 API
│   │   └── screens/            # 식당 상세, 메뉴 주문 화면
│   │
│   └── 👤 mypage/              # [마이페이지]
│       └── screens/            # 내 정보 수정, 식권 내역 확인
│
└── 📄 main.dart                # 앱 진입점 (Provider 등록, 테마 설정)
```

## 🌿 Git 협업 규칙 (Branch / Commit / Issue / PR)

### 1) 브랜치 전략
- 기본 브랜치
  - `main`: **배포/릴리즈용 안정 브랜치**
  - `develop`: **다음 릴리즈 개발 통합 브랜치**
- 작업 브랜치 생성 규칙: **반드시 `develop`에서 분기**
- 머지 규칙
  - 작업 브랜치 → `develop` : PR로 머지
  - `develop` → `main` : 릴리즈 PR로 머지(릴리즈 노트/버전 포함)

### 2) 브랜치 네이밍
- `feat/{issue번호}-{간단설명}`: 기능 추가
- `fix/{issue번호}-{간단설명}`: 버그 수정
- `refactor/{issue번호}-{간단설명}`: 리팩토링(동작 변경 최소)
- `chore/{issue번호}-{간단설명}`: 설정/의존성/빌드/문서
- `docs/{issue번호}-{간단설명}`: 문서
- `test/{issue번호}-{간단설명}`: 테스트

예)
- `feat/123-login-webview`
- `fix/87-token-refresh`

### 3) 커밋 메시지 컨벤션 (Conventional Commits)
형식:
- `type(scope): subject`
- `type: subject` (scope 생략 가능)

type 예시:
- `feat`: 기능
- `fix`: 버그
- `refactor`: 리팩토링
- `chore`: 설정/빌드/의존성
- `docs`: 문서
- `test`: 테스트
- `style`: 포맷/세미콜론 등(로직 변경 없음)

규칙:
- subject는 **현재형/명령문**, 마침표 생략, 50자 내 권장
- 관련 이슈가 있으면 본문/푸터에 `Refs #이슈번호` 또는 `Closes #이슈번호`

예)
- `feat(auth): add login screen`
- `fix(api): handle 401 refresh`
- `docs: add git workflow`
- `refactor(store): split menu model`

### 4) 작업 흐름 (권장)
1. 이슈 생성(기능/버그/리팩토링/문서)
2. `develop` 최신화 후 브랜치 생성
3. 작업 & 커밋(작게, 논리 단위로)
4. 푸시 후 PR 생성 → 리뷰/수정 → 머지

### 5) 이슈 작성 가이드
이슈 제목 예:
- `[FEAT] 로그인 화면 구현`
- `[FIX] iOS에서 WebView 뒤로가기 불가`
- `[REFACTOR] Dio 인터셉터 구조 정리`

이슈 본문 포함 권장:
- 배경/목표
- 요구사항(체크리스트)
- 참고 링크/스크린샷
- 완료 조건(Definition of Done)

### 6) PR(Pull Request) 규칙
- PR은 **가능하면 작게**(리뷰 가능한 크기) 유지
- PR 제목 형식(권장):
  - `[FEAT] ...`, `[FIX] ...`, `[REFACTOR] ...`, `[CHORE] ...`, `[DOCS] ...`
- 머지 방식: **Squash merge 권장**(커밋 히스토리 정리)

#### PR 템플릿(본문에 복붙)
- **요약**:
  - 
- **변경 내용**:
  - 
- **스크린샷/영상(선택)**:
  - 
- **테스트 방법**:
  - `flutter run` / 재현 절차
- **관련 이슈**:
  - Closes #
- **체크리스트**:
  - [ ] `flutter format .` 적용
  - [ ] `flutter analyze` 에러 없음
  - [ ] 주요 플로우 수동 테스트 완료
  - [ ] (해당 시) 테스트 코드 추가/수정

### 7) 푸시/리뷰 원칙
- 본인 PR은 **최소 1명 리뷰 승인 후 머지**(권장)
- 리뷰어가 보기 쉽게:
  - 파일/모듈 단위로 커밋 쪼개기
  - 불필요한 포맷 변경 최소화
  - “왜 바꿨는지”를 PR에 설명

### 8) 릴리즈/태그(선택 운영)
- `main` 머지 시 릴리즈로 간주
- 버전은 `pubspec.yaml`의 `version:`을 기준으로 관리
- 태그 예: `v1.0.0`

### 9) 로컬 체크(권장 명령)
flutter pub get
flutter format .
flutter analyze
flutter test

### 10) 이슈 템플릿

#### A. 기능 요청 / 구현 (Feature)
**Title**: `[FEAT] {기능 요약}`

**배경(Why)**
- (왜 필요한지, 사용자/운영 관점 문제)

**요구사항(What)**
- [ ] 요구사항 1
- [ ] 요구사항 2
- [ ] 요구사항 3

**화면/UX(선택)**
- Figma/스크린샷/레퍼런스 링크:
- 화면 흐름(간단):

**API/데이터(선택)**
- API 엔드포인트:
- 요청/응답 스키마:
- 에러 케이스:

**완료 조건(DoD)**
- [ ] 기능이 요구사항을 충족
- [ ] `flutter analyze` 통과
- [ ] 주요 플로우 수동 테스트 완료
- [ ] (해당 시) 테스트 추가/수정
- [ ] 문서/주석 업데이트(필요 시)

---

#### B. 버그 리포트 (Bug)
**Title**: `[FIX] {버그 요약}`

**환경**
- OS/디바이스: (예: iOS 17 / iPhone 14, Android 14 / Pixel 7)
- 앱 버전: (pubspec.yaml version)
- 재현 빈도: (항상/가끔/1회)

**재현 절차(Steps)**
1.
2.
3.

**현재 결과(Actual)**
- 

**기대 결과(Expected)**
- 

**로그/스크린샷**
- 콘솔/크래시 로그:
- 스크린샷/영상:

**원인 추정(선택)**
- 

**해결 기준(DoD)**
- [ ] 재현 불가 확인
- [ ] 회귀(리그레션) 테스트 완료
- [ ] (해당 시) 테스트로 재현/방지 추가

---

#### C. 리팩토링 (Refactor)
**Title**: `[REFACTOR] {대상/모듈} 구조 개선`

**목표**
- (예: 의존성 역전, 중복 제거, 파일 구조 정리)

**변경 범위**
- 대상 폴더/파일:
- 영향 기능:

**비기능 요구**
- 성능/유지보수/테스트 용이성 등

**완료 조건(DoD)**
- [ ] 기능 동작 동일(동작 변경 시 명시)
- [ ] `flutter analyze` 통과
- [ ] 주요 플로우 확인

---

#### D. 작업/설정/문서 (Chore/Docs)
**Title**: `[CHORE] {작업 요약}` 또는 `[DOCS] {문서 요약}`

**내용**
- 

**완료 조건(DoD)**
- [ ] 빌드/실행에 영향 없음 확인(해당 시)
- [ ] 문서 최신화

### 11) PR 템플릿

**Title 규칙**
- `[FEAT] ...` / `[FIX] ...` / `[REFACTOR] ...` / `[CHORE] ...` / `[DOCS] ...`

---

## 요약(한 줄)
- 

## 변경 사항(What changed)
- 
- 
- 

## 배경/의도(Why)
- 

## 스크린샷/영상(가능하면 첨부)
- Before:
- After:

## 테스트 방법(필수)
- [ ] `flutter pub get`
- [ ] `flutter format .`
- [ ] `flutter analyze`
- [ ] `flutter test` (해당 시)
- [ ] 수동 테스트 시나리오:
  - 1)
  - 2)

## 영향 범위/리스크
- 영향 모듈: (예: auth / map / store / mypage / common)
- 리스크: (예: 로그인 세션, 웹뷰 네비게이션 등)
- 롤백 플랜: (예: revert commit / 기능 플래그 등)

## 관련 이슈
- Closes #이슈번호
- Refs #이슈번호

## 체크리스트
- [ ] 불필요한 파일/디버그 코드 제거
- [ ] 하드코딩/임시 값 정리(필요 시)
- [ ] 에러/예외 처리 확인
- [ ] 네이밍/폴더 위치가 규칙에 맞음
- [ ] 리뷰 포인트(특이사항) PR에 설명함