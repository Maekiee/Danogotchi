# 배경 이미지 처리 측정 자료

`ImagePipelineMeasurementTests`가 쓰는 픽스처와 측정 조건 기록. 측정일 2026-11-20.

## 이미지 선정

앱 배경 테마 검색 화면의 기본 검색어 `library`(`SearchThemeViewModel`)로 Unsplash Search API를 호출해
1페이지(`per_page=20`, `order_by=relevant`) 상위 5장을 사용했다. Unsplash License.

| # | Photo ID | 작가 | 원본 해상도 | 원본(JPEG) | CDN(HEIC 1206×2622) |
|---|---|---|---|---|---|
| 1 | xrbbXIXAWY0 | Emil Widlund | 4000×5600 | 5,716,225 B | 654,807 B |
| 2 | BEEyeib-am8 | Trnava University | 5613×3742 | 7,444,158 B | 832,977 B |
| 3 | xmeRBPunJR8 | Jason Leung | 4240×5660 | 4,267,576 B | 503,091 B |
| 4 | 2JIvboGLeho | Susan Q Yin | 4395×2933 | 2,357,937 B | 338,688 B |
| 5 | HH4WBGNyltc | Jaredd Craig | 4000×6000 | 4,185,603 B | 454,548 B |

- `pipeline-N-original.jpg`: 전 — 예전 앱(Kingfisher)이 받던 `urls.full`
- `pipeline-N-cdn.heic`: 후 — 지금 앱이 받는 `urls.raw` + `DefaultThemeImageRepository.makeImageURL` 파라미터
  - `w`·`h` = 화면 픽셀(iPhone 17 Pro `nativeBounds` 1206×2622), `fit=crop&crop=center`, `fm=heic`, `q=85`
  - `fm=heic` 요청이 `image/heic`로 성공하므로 WebP 대체 경로는 타지 않는다
- 검색 추적 파라미터(`ixid`·`ixlib`)는 빼고 기록했다 — 빼고 받아도 바이트 수가 같음을 확인

## 파일 용량 측정 (curl)

```sh
for id in 1568667256549-094345857637 1588580000645-4562a6d2c839 1764728671460-34931d8261f5 \
          1524995997946-a1c2e315a42f 1532012197267-da84d127e765; do
  base="https://images.unsplash.com/photo-$id"
  before=$(curl -s -o /dev/null -w '%{size_download}' "$base?crop=entropy&cs=srgb&fm=jpg&q=85")
  after=$(curl -s -o /dev/null -w '%{size_download}' "$base?w=1206&h=2622&fit=crop&crop=center&fm=heic&q=85")
  echo "$id $before $after"
done
```

## 처리 시간·메모리 측정 (XCTest)

- 구간: 메모리에 올라온 `Data` → 화면에 그릴 수 있는 이미지 (네트워크·파일 읽기 제외)
  - 전: `UIImage(data:)` + `preparingForDisplay()` (원본 해상도 디코딩)
  - 후: `ImageDecoder.decode(data:maxPixelSize: 2622)` (앱 `backgroundMaxPixelSize` = 화면 높이 픽셀)
- 1회 = 5장을 차례로 처리, 장마다 `autoreleasepool`로 해제. `XCTClockMetric` + `XCTMemoryMetric`, 10회
- 테스트마다 별도 프로세스로 실행 (순서 영향 제거)

```sh
D='platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'
xcodebuild -project Danogotchi.xcodeproj -scheme Danogotchi-dev -destination "$D" build-for-testing
for t in test_before_originalJPEGDecodedAtFullResolution test_after_cdnHEICDecodedWithImageDecoder test_baseline_emptyBlock; do
  xcodebuild -project Danogotchi.xcodeproj -scheme Danogotchi-dev -destination "$D" \
    -parallel-testing-enabled NO \
    -only-testing:DanogotchiTests/ImagePipelineMeasurementTests/$t test-without-building
done
```
