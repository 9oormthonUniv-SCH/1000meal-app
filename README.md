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
