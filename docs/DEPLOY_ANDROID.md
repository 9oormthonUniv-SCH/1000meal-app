# 오늘순밥 Android (구글 플레이) 배포 가이드

이 문서는 Flutter 프로젝트를 **Google Play Console**에 배포하는 절차를 단계별로 정리한 것입니다.  
(Android Studio는 이미 설치되어 있다고 가정합니다.)

---

## 사전 준비 요약

- [x] 구글 플레이 콘솔에서 **「오늘순밥」** 앱 생성 완료
- [ ] 업로드용 **키스토어(keystore)** 생성
- [ ] **key.properties** 설정
- [ ] **AAB(App Bundle)** 빌드
- [ ] Play Console에서 스토어 정보 입력 후 AAB 업로드

---

## 1단계: 업로드용 키스토어(keystore) 만들기

Play에 올리는 앱은 **릴리스 서명**이 필요합니다. 한 번 만든 키스토어와 비밀번호는 **절대 분실하면 안 됩니다**.  
(분실 시 동일 패키지로 업데이트 불가)

### 1-1. 터미널에서 키스토어 생성

프로젝트 루트에서 실행:

```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- `upload-keystore.jks`: 키스토어 파일 이름 (원하면 변경 가능)
- `upload`: 키 별칭(alias). 나중에 `key.properties`의 `keyAlias`와 동일해야 함
- `-validity 10000`: 약 27년 유효

실행하면 **이름, 조직, 비밀번호** 등을 물어봅니다.  
**store 비밀번호**와 **key 비밀번호**를 반드시 메모해 두세요.

> 키스토어 파일(`.jks`)은 `android/` 폴더에 두고, **절대 Git에 커밋하지 마세요.**  
> 이미 `android/.gitignore`에 `*.jks`, `key.properties`가 포함되어 있습니다.

---

## 2단계: key.properties 설정

`android/` 폴더에 `key.properties` 파일을 **직접 생성**합니다.

1. `android/key.properties.example` 내용을 참고해,
2. `android/key.properties` 파일을 만들고 아래 형식으로 채웁니다.

```properties
storePassword=방금_설정한_키스토어_비밀번호
keyPassword=방금_설정한_키_비밀번호
keyAlias=upload
storeFile=upload-keystore.jks
```

- `storeFile`: `android/` 기준 경로. 키스토어를 `android/upload-keystore.jks`에 뒀다면 `upload-keystore.jks`만 적으면 됩니다.
- `keyAlias`: `keytool`에서 `-alias upload`로 만들었다면 `upload`로 맞추면 됩니다.

이 파일도 **Git에 올리지 마세요** (이미 .gitignore에 있음).

---

## 3단계: AAB(App Bundle) 빌드

Flutter에서 Play 배포용으로는 **APK가 아니라 AAB**를 사용합니다.

프로젝트 루트에서:

```bash
flutter clean
flutter pub get
flutter build appbundle
```

빌드가 성공하면 다음 파일이 생성됩니다.

- **경로:** `build/app/outputs/bundle/release/app-release.aab`

이 `app-release.aab` 파일을 Play Console에 업로드하면 됩니다.

---

## 4단계: Android Studio에서 할 일 (선택)

- **에뮬레이터/실기기**로 릴리스 빌드 동작 확인:
  - `flutter run --release`  
  또는 Android Studio에서 Run → **Release** 모드로 실행
- **키스토어 생성**을 GUI로 하고 싶다면:  
  **Build → Generate Signed Bundle / APK → Android App Bundle** 선택 후  
  **Create new...** 로 새 keystore 생성 가능 (위 1단계 대체)

필수는 아니고, 터미널에서 `keytool`로 만든 경우 추가로 할 일 없습니다.

---

## 5단계: Google Play Console에서 할 일

이미 **「오늘순밥」** 앱을 만들었다고 가정하고, 필요한 설정만 나열합니다.

### 5-1. 앱 액세스 및 광고

- **앱 액세스**: 모든 기능 제한 없이 사용 가능하면 “모든 기능에 앱 액세스 가능” 선택
- **광고**: 앱에 광고가 있으면 “예”, 없으면 “아니오” 선택

### 5-2. 스토어 등록정보 (스토어 리스팅)

- **앱 이름**: 오늘순밥
- **간단한 설명** / **상세 설명**: 앱 소개 문구
- **앱 아이콘** (512x512), **기능 그래픽** (1024x500) 등 요구되는 에셋 업로드
- **연락처 이메일** 등 필수 항목 입력

### 5-3. AAB 업로드 (내부 테스트 / 비공개 테스트 / 프로덕션)

1. Play Console 왼쪽 메뉴에서 **테스트 → 내부 테스트** (또는 **비공개 테스트**, **프로덕션**) 선택
2. **새 버전 만들기** (또는 **출시 만들기**)
3. **App Bundle** 업로드:
   - **업로드** 버튼 클릭 후 위에서 만든  
     `build/app/outputs/bundle/release/app-release.aab` 선택
4. **출시 노트** 입력 (예: “최초 Android 출시”)
5. **검토** 후 **출시** (또는 **검토 단계로 이동**)

첫 업로드 시 **Play App Signing**을 사용하라는 안내가 나오면 **권장 옵션(Google에서 키 관리)** 을 선택하면 됩니다.  
이미 만들어 둔 `upload-keystore.jks`는 **업로드 키**로만 쓰이고, Play가 앱 서명용 키를 따로 관리합니다.

### 5-4. 버전 코드 / 버전 이름

- **versionCode**: `pubspec.yaml`의 `version: 1.0.0+1`에서 `+1` 부분 (정수).  
  이후 업데이트할 때마다 **반드시 증가**시켜야 합니다 (예: 1, 2, 3 …).
- **versionName**: `1.0.0` 부분. 사용자에게 보이는 버전 번호.

변경 시 예:

```yaml
# pubspec.yaml
version: 1.0.0+2   # 다음 업로드
```

---

## 6단계: 이후 업데이트 배포 절차

1. `pubspec.yaml`에서 `version` 올리기 (예: `1.0.0+2` → `1.0.1+3`)
2. `flutter build appbundle` 다시 실행
3. Play Console 해당 트랙(내부/비공개/프로덕션)에서 **새 버전 만들기** 후 새 `app-release.aab` 업로드
4. 출시 노트 작성 후 검토·출시

---

## 트러블슈팅

| 현상 | 확인 사항 |
|------|-----------|
| `key.properties` 관련 에러 | `android/key.properties` 존재 여부, `storeFile` 경로, `keyAlias` 일치 여부 |
| 서명 실패 | 키스토어 비밀번호·alias·경로가 `key.properties`와 동일한지 확인 |
| “이 버전의 버전 코드가 이미 있습니다” | `pubspec.yaml`의 `+숫자`(versionCode)를 이전보다 크게 설정 후 재빌드 |
| 빌드 실패 | `flutter clean` 후 `flutter pub get` → `flutter build appbundle` 다시 시도 |

---

## 정리

1. **키스토어 생성** (`android/`에서 `keytool` 또는 Android Studio)
2. **`android/key.properties`** 작성 (비밀번호·alias·storeFile)
3. **`flutter build appbundle`** 로 `app-release.aab` 생성
4. **Play Console**에서 스토어 정보 입력 후 **AAB 업로드** → 테스트 트랙 또는 프로덕션 출시

여기까지 완료하면 「오늘순밥」 Android 앱을 구글 플레이에 배포·업데이트할 수 있습니다.
