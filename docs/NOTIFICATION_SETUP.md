# 앱 알림(푸시) 기능 추가 가이드

앱에 **FCM(Firebase Cloud Messaging)** 으로 푸시 알림을 넣는 절차입니다.  
(코드 주석: "FCM 도입 후 복구" 기준)

**Apple Developer / Xcode / Firebase 화면 기준 세부 절차**는 **[NOTIFICATION_SETUP_DETAILED.md](./NOTIFICATION_SETUP_DETAILED.md)** 를 참고하세요.

---

## 1. Firebase 프로젝트 설정

1. [Firebase Console](https://console.firebase.google.com/) 에서 프로젝트 생성 또는 기존 프로젝트 선택
2. **Android 앱** 등록
   - 패키지명: `pubspec.yaml`의 `name` 또는 `android/app/build.gradle`의 `applicationId`
   - (선택) 디버그/릴리즈 SHA-1 등록
3. **iOS 앱** 등록
   - Bundle ID: `ios/Runner.xcodeproj` 또는 Xcode에서 확인
   - `GoogleService-Info.plist` 다운로드 후 **`ios/Runner/GoogleService-Info.plist`** 에 넣기
   - Xcode에서 **Push Notifications**, **Background Modes > Remote notifications** 켜기
4. **Cloud Messaging** 사용 설정 (프로젝트 설정 > Cloud Messaging)

### Firebase 설정 파일 넣는 위치

| 플랫폼 | 파일명 | 넣을 경로 (프로젝트 루트 기준) |
|--------|--------|-------------------------------|
| **Android** | `google-services.json` | `android/app/google-services.json` |
| **iOS** | `GoogleService-Info.plist` | `ios/Runner/GoogleService-Info.plist` |

- **Android**: Firebase Console에서 Android 앱 추가 후 `google-services.json` 다운로드 → **`android/app/`** 폴더 안에 그대로 두면 됨.
- **iOS**: Firebase Console에서 iOS 앱 추가 후 `GoogleService-Info.plist` 다운로드 → **`ios/Runner/`** 폴더 안에 넣기. (Xcode에서 Runner 타겟에 포함되는지 확인)

---

## 2. Flutter 의존성 추가

`pubspec.yaml` 에 추가:

```yaml
dependencies:
  firebase_core: ^3.8.1
  firebase_messaging: ^15.1.5
  flutter_local_notifications: ^18.0.1   # 포그라운드 알림 표시용
```

- `firebase_core`: Firebase 초기화
- `firebase_messaging`: FCM(토큰 발급, 메시지 수신)
- `flutter_local_notifications`: 앱이 켜져 있을 때 로컬 알림으로 표시

설치:

```bash
flutter pub get
```

---

## 3. 플랫폼별 설정

### Android

- `android/app/build.gradle`:
  - `minSdkVersion` 21 이상 권장
  - (선택) `com.google.gms:google-services` 플러그인 적용
- `AndroidManifest.xml`:
  - 기본 권한 외 추가 필요 시 [FCM Android 문서](https://firebase.google.com/docs/cloud-messaging/android/client) 참고
- **`google-services.json`** → **`android/app/google-services.json`** 에 넣기 (Firebase에서 다운로드)

### iOS

- **`GoogleService-Info.plist`** → **`ios/Runner/GoogleService-Info.plist`** 에 넣기 (Firebase에서 다운로드)
- `ios/Runner/Info.plist`: 백그라운드 모드 등 필요 시 [FCM iOS 문서](https://firebase.google.com/docs/cloud-messaging/ios/client) 참고
- APNs 인증키 또는 인증서를 Firebase Console에 등록

---

## 4. 앱 코드 구조 예시

### 4.1 Firebase 초기화 (main.dart)

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// 백그라운드에서 메시지 수신 시 (top-level 함수 필수)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // 여기서는 UI 불가, 데이터만 처리
}

void main() async {
  WidgetsBinding.flutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}
```

### 4.2 알림 서비스 (토큰·권한·포그라운드 처리)

- **권한 요청**: iOS `requestPermission()`, Android 13+ 알림 권한
- **FCM 토큰 받기**: `FirebaseMessaging.instance.getToken()` → 이 토큰을 백엔드에 보내서 해당 기기로 푸시 발송
- **포그라운드 메시지**: `FirebaseMessaging.onMessage` 에서 수신 시 `flutter_local_notifications` 로 로컬 알림 표시
- **탭 시 이동**: `FirebaseMessaging.onMessageOpenedApp` / `getInitialMessage()` 로 딥링크 또는 화면 이동 처리

### 4.3 백엔드

- 서버에서 FCM Admin API 또는 HTTP v1 API로 `token` 에게 메시지 전송
- 토큰은 로그인 시/갱신 시 API로 서버에 저장해 두고, 공지/이벤트 시 해당 유저의 토큰들에 푸시

---

## 5. 알림 버튼 복구 (UI)

FCM 연동이 끝나면 다음 위치에서 알림 버튼을 다시 노출하면 됩니다.

- **마이페이지 앱바**: `lib/features/mypage/screens/mypage_screen.dart`  
  - 주석: `// 알림 버튼: 미구현으로 숨김 (FCM 도입 후 복구)`  
  - `actions: const []` 대신 알림 아이콘 버튼 추가 → 알림 설정 화면 또는 설정 스위치로 연결
- **홈 앱바**: `lib/widgets/HomePage.dart`  
  - 동일한 주석 위치에 알림 액션 추가

알림 “설정” 화면에서는:

- OS 알림 권한 상태 확인
- FCM 토큰이 서버에 등록됐는지 확인
- (선택) 주제 구독/해제 `FirebaseMessaging.instance.subscribeToTopic('공지')` 등

---

## 6. 체크리스트

| 단계 | 내용 |
|------|------|
| Firebase | 프로젝트 생성, Android/iOS 앱 등록. Android: `android/app/google-services.json`, iOS: `ios/Runner/GoogleService-Info.plist` |
| Flutter | `firebase_core`, `firebase_messaging`, `flutter_local_notifications` 추가 |
| iOS | Push Notifications, Background Modes, APNs 키/인증서 Firebase 등록 |
| 앱 | `main` 에서 초기화, 백그라운드 핸들러, 토큰 발급·전송, 포그라운드 시 로컬 알림 |
| 백엔드 | 토큰 저장 API, FCM으로 메시지 발송 |

이 순서대로 진행하면 앱에 알림 기능을 붙일 수 있습니다.  
실제 구현(서비스 클래스, 마이페이지/홈 알림 버튼 연결)이 필요하면 그 부분만 따로 요청해 주세요.
