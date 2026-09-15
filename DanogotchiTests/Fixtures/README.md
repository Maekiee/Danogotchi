# 이미지 디코더 테스트 자료

두 파일은 직접 만든 320×160 RGB 색상 패턴을 인코딩한 이미지다. 외부 사진이나 네트워크 요청을 사용하지 않는다.

- 좌상단: RGB(240, 32, 32)
- 우상단: RGB(32, 240, 32)
- 좌하단: RGB(32, 32, 240)
- 우하단: RGB(240, 240, 32)
- `theme-pattern.heic`: macOS `sips`의 HEIC 인코더, 품질 85
- `theme-pattern.webp`: Pillow의 WebP 인코더, lossless=True

`ImageDecoderTests`는 실제 포맷, 80×40 다운샘플링 결과, RGBA로 그린 네 영역의 색상, 저장 파일 바이트가 유지되는지 확인한다. 사진별 용량 감소율이나 처리 시간 측정에 사용하는 자료는 아니다.
