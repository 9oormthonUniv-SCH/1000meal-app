# 오늘순밥 iOS (App Store) 배포 가이드

TestFlight 배포까지 완료된 상태에서 **App Store 제출·심사 통과**를 위한 설정을 Xcode, 프로젝트, App Store Connect 순으로 정리했습니다.  
심시 기간을 고려해 미리 제출해 두려면 아래를 **순서대로** 확인하세요.

---

## 현재 프로젝트 요약

| 항목 | 값 |
|------|-----|
| 앱 표시 이름 | 오늘순밥 (Xcode에서 설정됨) |
| Bundle ID | `com.soonbob.1000meal` |
| 버전 (표시) | 1.0.0 (`pubspec.yaml` / MARKETING_VERSION) |
| 빌드 번호 | 1 (`pubspec.yaml` 1.0.0**+1**) |
| Development Team | YGXYJUTFLT |
| 최소 iOS | 15.5 |

---

## Part 1. Xcode에서 할 일

### 1-1. 프로젝트 열기

- **반드시** `.xcworkspace` 로 열기  
  - 경로: `ios/Runner.xcworkspace`  
  - `.xcodeproj` 만 열면 CocoaPods 연동이 반영되지 않을 수 있음.

### 1-2. 서명(Signing) 확인

1. 왼쪽에서 **Runner** 프로젝트 클릭 → 상단 **TARGETS**에서 **Runner** 선택.
2. **Signing & Capabilities** 탭에서:
   - **Automatically manage signing**: 체크 유지.
   - **Team**: `YGXYJUTFLT` (또는 사용 중인 Apple Developer 팀) 선택.
   - **Bundle Identifier**: `com.soonbob.1000meal` 인지 확인.
   - **Release** 구성에서도 동일한 Team/Bundle ID인지 확인 (Debug/Release/Profile 모두).

### 1-3. 버전·빌드 번호

- **General** 탭:
  - **Version**: `1.0.0` (또는 원하는 표시 버전).  
    Flutter와 맞추려면 `pubspec.yaml`의 `version:` 앞부분과 동일하게.
  - **Build**: `1` (또는 정수).  
    Flutter와 맞추려면 `pubspec.yaml`의 `version: 1.0.0+1`에서 `+1` 부분.
- App Store에 **새 빌드를 올릴 때마다 Build 번호는 반드시 이전보다 커야** 합니다.  
  (Version은 그대로 두고 Build만 올려도 됨.)

### 1-4. 디스플레이 이름·카테고리

- **Signing & Capabilities** 옆 **General** 탭:
  - **Display Name**: `오늘순밥` (현재 프로젝트에 이미 설정됨).
- **Build Settings**에서 검색:
  - `INFOPLIST_KEY_LSApplicationCategoryType`: `public.app-category.food-and-drink` (이미 설정됨).

### 1-5. 배포 대상(Deployment Target)

- **General** → **Minimum Deployments** (또는 **Build Settings**에서 `IPHONEOS_DEPLOYMENT_TARGET`):
  - 현재 **15.5**로 되어 있으면 유지.  
  - 더 낮추면 지원 기기 늘어나지만, 오래된 OS 지원 부담이 생김.

### 1-6. Capabilities (필요한 것만)

- **Signing & Capabilities**에서 사용하는 기능만 추가:
  - 예: Push Notifications, Sign in with Apple, Associated Domains 등.
- 사용하지 않는 Capability는 제거하는 편이 심사 시 문의 가능성을 줄입니다.

### 1-7. Archive 및 업로드용 스킴

1. 상단 스킴에서 **Runner** 선택, 디바이스를 **Any iOS Device (arm64)** 로.
2. 메뉴 **Product** → **Archive**.
3. Archive가 끝나면 **Organizer** 창에서:
   - 해당 Archive 선택 → **Distribute App**.
   - **App Store Connect** → **Upload** 선택 후 필요한 옵션(next) 진행.
   - 업로드 완료 후 **App Store Connect**에서 빌드가 “처리 중” → “사용 가능”이 될 때까지 대기 (수 분~수십 분).

---

## Part 2. 프로젝트 내 설정 (Flutter / ios 폴더)

### 2-1. 버전 통일

- **`pubspec.yaml`**  
  - 예: `version: 1.0.0+1`  
  - 앞부분 `1.0.0`: CFBundleShortVersionString (사용자에게 보이는 버전).  
  - `+1`: CFBundleVersion (Build 번호).  
  - Xcode에서 Version/Build를 수동으로 바꾸지 않고 Flutter만 쓴다면, 여기만 올리면 됨.

### 2-2. `ios/Runner/Info.plist`

- **CFBundleDisplayName**  
  - 현재 plist에는 `Meal App`으로 되어 있고, Xcode 빌드 설정에서 `오늘순밥`으로 덮어쓰고 있음.  
  - 나중에 Flutter만으로 빌드하는 경로를 쓸 수 있으면, plist도 `오늘순밥`으로 맞춰 두는 것이 좋음.
- **권한 설명 문구** (이미 있음):
  - `NSCameraUsageDescription`: QR 코드용.
  - `NSPhotoLibraryUsageDescription`: 공지 이미지 첨부용.
- **NSAppTransportSecurity**  
  - 현재 `NSAllowsArbitraryLoads` / `NSAllowsArbitraryLoadsInWebContent` 가 `true`입니다.  
  - **심사 시 이유를 물어보거나 거절 사유가 될 수 있으므로**, 실제로 필요한 도메인만 예외 처리하는 방식으로 바꾸는 것을 권장합니다.  
  - 예시는 아래 “심사 시 주의사항” 참고.

### 2-3. ExportOptions (선택)

- CI/스크립트로 업로드할 때만 필요.  
- 로컬에서 Xcode **Distribute App**으로 업로드하면 별도 plist 없이 진행 가능.

---

## Part 3. App Store Connect에서 할 일

### 3-1. 앱이 이미 있는지 확인

- [App Store Connect](https://appstoreconnect.apple.com) → **앱** → **오늘순밥** (또는 해당 앱) 선택.  
- TestFlight까지 했다면 앱은 이미 생성되어 있을 가능성이 큼.

### 3-2. 앱 정보 (일반)

- **앱 정보** 메뉴:
  - **이름**: 오늘순밥.
  - **부제목**: 선택 사항 (30자 이내).
  - **카테고리**: 예: **음식 및 음료** (프로젝트의 food-and-drink와 일치).
  - **2차 카테고리**: 선택 사항.

### 3-3. 가격 및 판매 가능 여부

- **가격 및 판매 가능 여부**:
  - **무료** 또는 **유료** 선택.
  - **판매 가능 국가/지역**: 대한민국 등 출시할 국가 선택.

### 3-4. 스크린샷 (필수)

- **앱 스토어** 탭 → **버전** 또는 **신규 버전**에서:
  - **iPhone 6.7"** (필수): 1290 x 2796 px, 최대 10장.
  - **iPhone 6.5"** (필수): 1242 x 2688 px, 최대 10장.
  - **iPhone 5.5"** (선택): 1242 x 2208 px.
  - iPad 지원 시 iPad Pro 12.9" 등 별도 규격 요구.
- 규격/장수는 Apple 가이드라인 변경 가능하므로, 업로드 화면에 표시되는 “권장 크기”를 최종 기준으로 하세요.

### 3-5. 프로모션 텍스트 (선택)

- 170자 이내, 앱 스토어 상단에 노출. 수정 시 재심사 없이 반영 가능.

### 3-6. 설명·키워드·URL

- **설명**: 앱 소개 (4000자 제한).  
  - 오늘순밥이 무엇을 하는 앱인지, 누구를 위한 것인지 명확히.
- **키워드**: 쉼표 없이 공백으로 구분, 100자 제한.  
  - 검색에 쓰일 단어만 (앱 이름에 들어가는 단어는 중복해도 됨).
- **지원 URL**: 앱 지원/문의 페이지 (필수).
- **마케팅 URL**: 선택.

### 3-7. 개인정보 처리방침 URL (필수)

- **개인정보 처리방침** URL 입력 (앱이 수집하는 데이터가 있다면 필수).  
- 수집하는 데이터가 없다면 “데이터를 수집하지 않음” 등을 명시한 페이지라도 URL이 있으면 좋습니다.

### 3-8. 빌드 선택

- **빌드** 섹션:
  - **+** 또는 **빌드 선택** → 방금 업로드한 빌드(버전 + 빌드 번호) 선택.
  - 빌드가 “처리 중”이면 끝날 때까지 기다린 뒤 다시 선택.

### 3-9. 심사용 정보

- **심사 정보**:
  - **연락처 이메일/전화번호**: 심사 중 문의 시 사용.
  - **로그인 계정** (앱에 로그인이 있는 경우):  
    테스트용 계정/비밀번호를 넣어 주어야 심사원이 앱 기능을 확인할 수 있음.
  - **비고**:  
    테스트 방법, 데모 모드, 특정 메뉴 위치 등 심사원이 꼭 알아야 할 내용을 간단히 적기.

### 3-10. 광고 식별자 (IDFA)

- 앱에 **광고**를 넣거나 **광고 SDK**를 쓰면 “광고 사용”으로 표시하고, 필요 시 **App Tracking Transparency** 등 가이드라인 맞춤.
- 광고가 전혀 없으면 “아니오”로 표시.

### 3-11. 버전 출시 방식

- **수동으로 이 버전 출시**: 심사 통과 후 직접 “출시” 버튼을 눌러야 스토어에 노출.
- **자동으로 이 버전 출시**: 심사 통과 즉시 스토어 노출.  
  심시 기간만 미리 써 두고 싶다면 보통 **수동**이 안전합니다.

### 3-12. 제출

- 모든 필수 항목(스크린샷, 설명, 개인정보처리방침, 빌드, 심사 정보 등) 입력 후 **심사에 제출** 버튼 클릭.

---

## Part 4. 제출 전 최종 체크리스트

- [ ] Xcode: Runner 타겟 **Signing & Capabilities** — Team, Bundle ID 일치.
- [ ] Xcode: **Version** / **Build** (또는 `pubspec.yaml` version) — 이전 제출 빌드보다 Build 번호 증가.
- [ ] **Info.plist**: 카메라/사진 권한 설명 문구 있음.
- [ ] **NSAppTransportSecurity**: 가능하면 `NSAllowsArbitraryLoads` 제거 후 도메인 예외만 사용 (아래 참고).
- [ ] App Store Connect: **스크린샷** (필수 규격) 업로드.
- [ ] App Store Connect: **설명**, **키워드**, **지원 URL**, **개인정보 처리방침 URL** 입력.
- [ ] App Store Connect: **빌드** 선택됨.
- [ ] App Store Connect: **심사 정보** — 연락처, (필요 시) 로그인 계정, 비고.
- [ ] Archive 후 **Distribute App**으로 업로드한 빌드가 “사용 가능” 상태인지 확인.

---

## Part 5. 심사 시 자주 걸리는 것·주의사항

### 5-1. NSAppTransportSecurity (ATS)

- **현재**: `NSAllowsArbitraryLoads` = true → 모든 HTTP 허용.  
  심사 시 “왜 필요한지” 설명 요청 또는 거절 가능.
- **권장**: 실제로 접속하는 API/웹 도메인만 예외로 두기.

예시 (필요한 도메인만 허용):

```xml
<key>NSAppTransportSecurity</key>
<dict>
	<key>NSExceptionDomains</key>
	<dict>
		<key>your-api-domain.com</key>
		<dict>
			<key>NSExceptionAllowsInsecureHTTPLoads</key>
			<true/>
		</dict>
	</dict>
	<key>NSAllowsArbitraryLoadsInWebContent</key>
	<true/>
</dict>
```

- 웹뷰에서 아무 URL이나 열어야 한다면 `NSAllowsArbitraryLoadsInWebContent`만 true로 두고, 상위 `NSAllowsArbitraryLoads`는 제거하는 방식이 더 안전합니다.  
  (실제 사용 패턴에 맞게 조정 필요.)

### 5-2. 로그인/테스트 계정

- 앱에 로그인이 있으면 **심사 정보**에 테스트용 **이메일/비밀번호**를 반드시 넣어 주세요.  
  넣지 않으면 “앱을 검증할 수 없음”으로 반려될 수 있습니다.

### 5-3. 개인정보 처리방침

- 로그인, 프로필, 사진/카메라 등 개인 데이터를 다루면 **개인정보 처리방침 URL**이 필수입니다.

### 5-4. 크래시·흰 화면

- 심사 중 크래시나 흰 화면이 나오면 반려됩니다.  
  **Release** 빌드로 실기기에서 한 번 더 확인하는 것이 좋습니다.

---

## 필요한 정보 정리 (제가 알 수 없는 것들)

아래는 프로젝트/비즈니스에 따라 달라져서, 직접 채워야 합니다.  
스크린샷·텍스트·파일 등으로 현재 상태를 보여주시면, 그에 맞춰 항목별로 더 구체적으로 적어 드릴 수 있습니다.

1. **App Store Connect**
   - 앱이 이미 만들어져 있는지, 앱 이름/Bundle ID가 `com.soonbob.1000meal`과 일치하는지.
   - 현재 “앱 스토어” 탭에 스크린샷/설명/개인정보처리방침이 어디까지 채워져 있는지 (비어 있는 항목 목록).

2. **스크린샷**
   - iPhone 6.7" / 6.5" 등 필수 규격으로 이미 준비했는지.  
     없으면 “어떤 화면을 캡처해야 하는지” 화면 목록을 알려주시면 캡처 순서/구성도 정리해 드릴 수 있습니다.

3. **텍스트**
   - 앱 **설명** (초안 또는 완성본).
   - **키워드** (검색에 넣고 싶은 단어들).
   - **지원 URL**, **개인정보 처리방침 URL** (실제 주소).

4. **로그인/테스트**
   - 앱에 로그인이 있는지.  
     있다면 심사용 **테스트 계정 이메일/비밀번호**를 App Store Connect “심사 정보”에 넣을 수 있는지.

5. **NSAppTransportSecurity**
   - 앱에서 실제로 호출하는 **API 도메인** 또는 웹뷰로 여는 **도메인 목록**.  
     이 목록을 주시면 `Info.plist`용 ATS 예외 설정 예시를 그대로 만들어 드릴 수 있습니다.

6. **버전/빌드**
   - 이번에 스토어에 낼 **버전 번호** (예: 1.0.0)와 **빌드 번호** (예: 1 또는 2).  
     이미 TestFlight로 빌드 1을 썼다면, 스토어 제출용은 보통 Build 2 이상으로 올리는 것이 안전합니다.

---

이 문서를 기준으로 Xcode → 프로젝트 → App Store Connect 순서로 진행하시고,  
“지금 이 화면이 이렇게 보인다”는 스크린샷이나 “이 항목을 이렇게 채웠다”는 텍스트를 주시면, 그 다음 단계나 수정할 문구까지 구체적으로 적어 드리겠습니다.
