# 푸시 알림 설정 상세 가이드 (Apple / Firebase / Xcode)

앱에 FCM 푸시 알림을 넣기 위해 **Apple Developer**, **Xcode**, **Firebase Console**에서 해야 할 작업을 화면 기준으로 단계별로 정리한 문서입니다.

---

## 목차

1. [Apple Developer – APNs 키 생성](#1-apple-developer--apns-키-생성)
2. [Apple Developer – App ID에 푸시 알림 켜기](#2-apple-developer--app-id에-푸시-알림-켜기)
3. [Firebase Console – APNs 키 등록](#3-firebase-console--apns-키-등록)
4. [Xcode – Capabilities 설정](#4-xcode--capabilities-설정)
5. [확인 및 테스트](#5-확인-및-테스트)

---

## 1. Apple Developer – APNs 키 생성

APNs(Apple Push Notification service) 인증 키를 만들고, 이 키를 나중에 Firebase에 등록합니다.

### 1.1 사이트 접속 및 로그인

1. 브라우저에서 **[https://developer.apple.com/account](https://developer.apple.com/account)** 접속
2. Apple ID로 로그인

### 1.2 Keys(키) 메뉴로 이동

1. 메인 화면에서 **「Certificates, IDs & Profiles」(인증서, ID 및 프로파일)** 카드 클릭
2. 왼쪽 사이드바 또는 본문에서 **「Keys」(키)** 클릭  
   - 상단에 **Keys** 탭이 있으면 그걸 선택해도 됨

### 1.3 새 키 생성

1. **「+」** 버튼(또는 "Create a key" / "키 생성") 클릭
2. **Register a New Key** 화면에서:
   - **Key Name**: 예) `FCM APNs Key` 또는 `푸시알림키` (나중에 구분용, 아무 이름 가능)
   - **Key Services**에서 **「Apple Push Notifications service (APNs)」** 만 체크  
     - 다른 서비스는 체크하지 않아도 됨
3. **Continue** 클릭
4. 등록 확인 화면에서 **Register** 클릭

### 1.4 키 다운로드 및 정보 저장

1. **Download** 버튼으로 **.p8 파일** 다운로드  
   - **주의**: 이 파일은 **한 번만** 다운로드 가능합니다. 안전한 곳에 보관하세요.
2. 같은 화면에서 다음 값을 **메모**해 두세요 (Firebase 등록 시 사용):
   - **Key ID**: 10자리 영문+숫자 (예: `AB12CD34EF`)
   - **Team ID**: 상단 계정/팀 정보 또는 [Membership](https://developer.apple.com/account#MembershipDetailsCard)에서 확인
   - **Bundle ID**: 이 앱의 Bundle ID (예: `com.example.mealApp` → 실제 값은 Xcode 또는 `ios/Runner/GoogleService-Info.plist`의 `BUNDLE_ID` 참고)
3. **Done** 클릭 (다시 이 키의 .p8을 받을 수 없으니, 다운로드 완료 확인 후 진행)

---

## 2. Apple Developer – App ID에 푸시 알림 켜기

앱의 App ID(식별자)에 Push Notifications capability가 켜져 있어야 합니다.

### 2.1 Identifiers(식별자)로 이동

1. **Certificates, IDs & Profiles** 영역에서 **「Identifiers」(식별자)** 클릭
2. 목록에서 이 프로젝트의 **App ID** 선택  
   - 이름이나 **Bundle ID**로 찾기 (예: `com.example.mealApp`)
   - 없으면 **「+」** 로 새로 만들고, Bundle ID를 Xcode/GoogleService-Info.plist와 동일하게 설정

### 2.2 Push Notifications 활성화

1. 해당 App ID 상세 화면에서 **Capabilities** 목록 찾기
2. **Push Notifications** 항목이 **체크 해제**되어 있으면 **체크**
3. **Save** (또는 **저장**) 클릭
4. 확인 대화상자가 나오면 **Confirm** 등으로 저장 완료

---

## 3. Firebase Console – APNs 키 등록

Firebase가 iOS 앱으로 푸시를 보내려면, 방금 만든 APNs 키를 Firebase에 등록해야 합니다.

### 3.1 Firebase 프로젝트 열기

1. **[https://console.firebase.google.com](https://console.firebase.google.com)** 접속
2. 사용 중인 Firebase 프로젝트 선택 (예: 이 앱이 연결된 프로젝트)

### 3.2 프로젝트 설정으로 이동

1. 왼쪽 하단 **⚙️ 톱니바퀴** 클릭
2. **「프로젝트 설정」**(Project settings) 클릭

### 3.3 Cloud Messaging 탭에서 iOS 설정

1. 상단 **「Cloud Messaging」** 탭 클릭
2. 아래로 내려서 **「Apple 앱 구성」**(Apple app configuration) 섹션 찾기
3. 등록된 **iOS 앱**이 있으면 해당 행의 **연필(편집)** 아이콘 클릭  
   - iOS 앱이 없으면 먼저 **「iOS 앱 추가」**로 앱 등록 후 `GoogleService-Info.plist` 다운로드해 프로젝트에 넣기

### 3.4 APNs 인증 키 업로드

1. **「APNs 인증 키」**(APNs Authentication Key) 영역 찾기
2. **「키 업로드」**(Upload) 또는 **「.p8 파일 선택」** 클릭
3. 1단계에서 다운로드한 **.p8 파일** 선택
4. 아래 필드 입력:
   - **Key ID**: 1.4에서 메모한 10자리 Key ID
   - **Team ID**: Apple Developer 팀 ID (Membership에서 확인)
   - **Bundle ID**: 이 앱의 Bundle ID (예: `com.example.mealApp`)
5. **업로드** 또는 **저장** 클릭
6. 등록이 완료되면 해당 iOS 앱 옆에 APNs 키가 연결된 것으로 표시됨

---

## 4. Xcode – Capabilities 설정

앱 타겟에 Push Notifications와 Background Modes(Remote notifications)를 켜야 합니다.

### 4.1 Xcode에서 프로젝트 열기

1. 터미널 또는 Finder에서:
   ```bash
   open ios/Runner.xcworkspace
   ```
   또는 Cursor/VS Code에서 `ios/Runner.xcworkspace` 더블클릭  
   - **주의**: `.xcodeproj`가 아니라 **`.xcworkspace`** 를 열어야 CocoaPods 적용됨

### 4.2 Runner 타겟 선택

1. 왼쪽 **Project Navigator**에서 맨 위 **Runner** (파란 프로젝트 아이콘) 클릭
2. 가운데 **TARGETS** 목록에서 **「Runner」** 선택  
   - PROJECT가 아니라 **TARGETS** 아래의 Runner

### 4.3 Signing & Capabilities 탭

1. 상단 탭에서 **「Signing & Capabilities」** 선택
2. **「+ Capability」** 버튼 클릭

### 4.4 Push Notifications 추가

1. 검색창에 **Push** 입력
2. **「Push Notifications」** 더블클릭 또는 선택 후 **추가**
3. Capabilities 목록에 **Push Notifications**가 추가된 것 확인

### 4.5 Background Modes 추가

1. 다시 **「+ Capability」** 클릭
2. **Background Modes** 검색 후 추가
3. 추가된 **Background Modes** 블록을 펼치기
4. **「Remote notifications」** 체크박스 **체크**

### 4.6 저장 및 확인

1. **Cmd + S**로 저장
2. **Runner.entitlements** 파일이 생성/수정되었는지 확인해도 됨 (자동 반영됨)

---

## 5. 확인 및 테스트

### 5.1 앱에서 확인할 것

- **실기기**에서 앱 실행 후 콘솔에 **「FCM Token: …」** 이 출력되는지 확인  
  - 시뮬레이터는 푸시 수신이 제한적일 수 있음
- Firebase 초기화 실패 시 **「Firebase 초기화 실패 (앱은 계속 실행)」** 만 나오면, 위 1~4 단계와 `GoogleService-Info.plist` 위치를 다시 확인

### 5.2 Firebase Console에서 테스트 메시지 보내기 (선택)

1. Firebase Console → **Engage** → **Messaging** (또는 **Cloud Messaging**)
2. **「첫 번째 캠페인 만들기」** 또는 **「새 캠페인」** → **「Firebase 알림 메시지」**
3. 알림 제목/본문 입력 후 **다음**
4. **대상**에서 **「테스트 메시지 보내기」** 선택 후, 앱에서 확인한 **FCM 토큰** 붙여넣기
5. **테스트** 실행 후 실기기에서 알림 수신 여부 확인

---

## 요약 체크리스트

| 순서 | 위치 | 할 일 |
|------|------|--------|
| 1 | Apple Developer → Keys | APNs 키 생성, .p8 다운로드, Key ID·Team ID·Bundle ID 메모 |
| 2 | Apple Developer → Identifiers | 해당 App ID에 **Push Notifications** 체크 후 저장 |
| 3 | Firebase Console → 프로젝트 설정 → Cloud Messaging | iOS 앱에 APNs 키(.p8) 업로드, Key ID·Team ID·Bundle ID 입력 |
| 4 | Xcode → Runner 타겟 → Signing & Capabilities | **Push Notifications**, **Background Modes → Remote notifications** 추가 |
| 5 | 앱 실행 | 실기기에서 FCM 토큰 로그 확인, 필요 시 Firebase Messaging으로 테스트 발송 |

---

## 참고

- **Bundle ID**는 `ios/Runner/GoogleService-Info.plist`의 `BUNDLE_ID` 또는 Xcode에서 Runner 타겟 → **General** → **Bundle Identifier**에서 확인 가능
- **Team ID**는 [Apple Developer – Membership](https://developer.apple.com/account#MembershipDetailsCard)에서 확인
- .p8 파일은 한 번만 다운로드 가능하므로, 백업해 두고 Firebase에만 업로드하고 공개 저장소 등에는 올리지 말 것

이 문서는 `docs/NOTIFICATION_SETUP.md`의 플랫폼별 설정을 보완하는 상세 절차입니다.
