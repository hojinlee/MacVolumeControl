# MacVolumeControl

외부 노브가 `F11/F12` 키 입력으로 들어올 때, 이를 `Option + Shift + F11/F12` 입력으로 바꾸는 메뉴 바 앱이다.

## 동작 방식

- 기본값은 `미세 조정 사용` 켜짐
- `F11/F12` 입력을 가로채서 `Option + Shift + F11/F12`로 재전송
- 원하면 메뉴 바에서 `미세 조정 사용`을 끄고 macOS 기본 동작으로 복귀

## 빌드

```bash
swift build
```

앱 번들 생성:

```bash
./scripts/build-app.sh
```

생성 결과:

- `build/MacVolumeControl.app`

## 실행

패키지 실행:

```bash
swift run
```

앱 번들 실행:

```bash
open build/MacVolumeControl.app
```

## 권한

글로벌 볼륨 키 입력을 가로채려면 macOS 손쉬운 사용 권한이 필요할 수 있다.

- 앱 메뉴에서 `권한 설정 열기…` 선택
- 시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용에서 허용
- 허용 후 `입력 감시 다시 시작` 선택

## 메뉴 항목

- `현재 볼륨`: 현재 기본 출력 장치 볼륨 표시
- `입력 감시 상태`: 활성 / 권한 필요 / 꺼짐 표시
- `미세 조정 사용`: 시스템 미세 볼륨 조절 on/off
- `입력 감시 다시 시작`: 권한 허용 뒤 훅 재시작
