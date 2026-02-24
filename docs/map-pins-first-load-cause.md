# 지도 첫 진입 시 핀 미표시 원인 분석

## 현상
- 지도 탭 **첫 진입** 시: 매장 맵 핀이 안 보임
- **새로고침** 버튼 클릭 후: 핀이 정상 표시됨

---

## 1. 관련 코드 흐름 요약

### 1.1 MapScreen (우리 코드)
- **지도 탭 진입** → `didChangeDependencies`에서 `addPostFrameCallback`으로 `StoreListViewModel().load()` 예약
- **build**마다:
  - `vm.items`로 매장 목록 사용
  - `_ensureMarkerIcons(vm.items)`로 **캐시에 없는** 매장만 비동기 아이콘 생성 (PictureRecorder → toImage → base64 → MarkerIcon)
  - **아이콘이 캐시에 있는 매장만** `markers` 리스트에 넣어서 `KakaoMap(markers: markers)`에 전달

즉, **마커는 “매장 목록 로드” + “마커 아이콘 빌드 완료” 둘 다 된 뒤에만** non-empty로 넘어감.

### 1.2 KakaoMap (kakao_map_plugin)
- **initState**: `loadHtmlString(_loadMap(), ...)`로 HTML 로드
  - HTML 안에는 `window.onload`에서 `map = new kakao.maps.Map(container, options)` 로 **지도만** 생성
  - **초기 HTML에는 마커를 그리는 코드가 없음** (`let markers = []`만 있고, Flutter에서 넘긴 `widget.markers`를 반영하는 부분 없음)
- **didUpdateWidget**:  
  `_mapController.addMarker(markers: widget.markers)` 호출  
  → WebView 내부에서 `addMarker(...)` JS 함수 실행해 실제로 마커 그림

즉, **플러그인은 “최초 생성 시”가 아니라 “didUpdateWidget으로 markers가 바뀔 때”** 만 지도에 마커를 그린다.

### 1.3 addMarker (플러그인 컨트롤러)
- `markers == null || markers.isEmpty` 이면 **아무것도 하지 않고 return**
- 그 외에는 `clearMarker` 후 `runJavaScript("addMarker(...)")` 로 WebView에 마커 추가

---

## 2. 첫 진입 시 시간순 정리

1. 지도 탭 선택 → MapScreen 최초 build  
   - 이때 `vm.items`는 **아직 비어 있거나** (직전에 홈에서 로드 안 했으면), **이미 있거나** (홈에서 StoreSection이 이미 load 했으면)
2. **첫 build**  
   - `vm.items`가 있어도 `_markerIconCache`는 **항상 비어 있음** (방금 생성된 State)  
   - 따라서 `markers = []` → `KakaoMap(markers: [])` 로 지도만 생성
3. **KakaoMap initState**  
   - `loadHtmlString(_loadMap(), ...)` 호출 → WebView가 **비동기로** HTML 로드 시작  
   - 지도 DOM/스크립트 로드 및 `window.onload` 실행 시점은 **그 이후**
4. **postFrameCallback**  
   - `StoreListViewModel().load()` 실행  
   - 필요 시 `_ensureMarkerIcons(vm.items)`로 아이콘 빌드 시작 (Future.wait, 수십~수백 ms)
5. **아이콘 빌드 완료**  
   - `setState` → MapScreen 재빌드  
   - `_markerIconCache`가 채워진 상태이므로 `markers`가 **이때 처음으로 non-empty**
6. **KakaoMap didUpdateWidget**  
   - `widget.markers`가 이제 N개  
   - `_mapController.addMarker(markers: widget.markers)` 호출  
   - WebView에서 `addMarker(...)` JS 실행 → **이 시점에 `map`이 있어야** 마커가 붙음

---

## 3. 근본 원인: 타이밍 경쟁 (Race)

- **A**: WebView HTML 로드 완료 후 `window.onload` 실행 → `map = new kakao.maps.Map(...)` 까지 끝남  
- **B**: MapScreen에서 아이콘 빌드 완료 → setState → KakaoMap `didUpdateWidget` → `addMarker(markers)` 호출

**첫 진입 시:**

- KakaoMap은 **항상** 처음에 `markers: []` 로 생성됨 (캐시가 비어 있음)
- 마커가 그려지는 **유일한 경로**는 나중에 `markers`가 채워졌을 때의 **didUpdateWidget → addMarker**
- 그런데 그 시점에 **WebView가 아직 로드 중**이면:
  - HTML의 `window.onload`가 아직 안 돌았거나
  - `map`이 아직 null이거나
  - `addMarker` JS가 실행될 때 `map`이 없어서 `marker.setMap(map)`이 제대로 동작하지 않음  
  → **마커가 안 붙은 채로 남음**

**새로고침 시:**

- 사용자가 새로고침을 누를 때쯤에는 **WebView는 이미 한참 전에 로드 완료**된 상태
- `load()`만 다시 불리면서 `notifyListeners()` → build
- 이때 `_markerIconCache`는 **이전 진입에서 이미 채워져 있음**
- 따라서 **같은 build에서부터** `markers`가 non-empty로 넘어가고, didUpdateWidget → addMarker가 **이미 준비된 지도(map)** 에 대해 실행됨  
  → **마커가 정상 표시됨**

정리하면:

- **첫 진입**:  
  “마커 리스트가 채워져서 addMarker가 호출되는 시점”이  
  “WebView에서 지도(map)가 생성되기 전”일 가능성이 큼 → **경쟁에서 지면** → 핀 안 보임
- **새로고침**:  
  지도는 이미 준비된 상태에서 같은 addMarker 경로가 한 번 더 실행됨 → **항상 지도 준비 후** 호출 → 핀 보임

---

## 4. 플러그인 쪽 구조로 보면

- **초기 HTML**에는 `widget.markers`를 반영하는 코드가 없고, `markers`는 **전부 didUpdateWidget → addMarker(JS)** 로만 그려짐
- 따라서 “첫 번째로 non-empty markers를 넘기는 시점”에 **WebView/지도가 준비돼 있지 않으면** 그때 실행된 addMarker는 실패하거나 무시됨
- 플러그인은 **onMapCreated** 등으로 “지도 준비 완료” 시점을 알려주지만, **그 시점에 현재 markers를 다시 그리는 로직은 없음**
- 그래서 “지도가 준비되기 전에 한 번 didUpdateWidget으로 addMarker가 불렸다”면, 그때는 마커가 안 붙고, 이후에 같은 markers로 다시 didUpdateWidget이 호출되지 않으면 (새로고침처럼 rebuild가 한 번 더 일어나지 않으면) 계속 안 보이는 상태가 됨

---

## 5. 결론

| 구분 | 내용 |
|------|------|
| **현상** | 지도 첫 진입 시엔 핀 안 보이고, 새로고침 후엔 보임 |
| **직접 원인** | 마커는 **didUpdateWidget → addMarker** 로만 그려지는데, **첫 번째로 non-empty markers가 넘어갈 때** WebView/지도가 아직 준비되지 않은 경우가 많음 |
| **근본 원인** | **(1) WebView HTML 로드 및 window.onload 완료** 와 **(2) 마커 아이콘 빌드 완료 후 setState → didUpdateWidget → addMarker** 사이의 **비결정적 순서(race)**. (2)가 (1)보다 먼저 일어나면 마커가 표시되지 않음. |
| **새로고침에서 보이는 이유** | 새로고침 시점에는 이미 지도가 로드된 뒤이고, 캐시 덕분에 markers가 처음부터 non-empty로 넘어가서, addMarker가 “지도 준비된 뒤”에 호출됨. |

수정 방향은 “**지도가 준비된 이후에만** (또는 **준비 완료 시점에 한 번**) 현재 `markers`를 addMarker로 그리도록” 맞추면 됨 (예: onMapCreated 이후에 한 번 markers 적용, 또는 지도 준비 플래그 + 재시도/지연 호출).
