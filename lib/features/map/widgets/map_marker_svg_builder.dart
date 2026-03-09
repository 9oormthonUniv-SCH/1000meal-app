import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

/// mapMarker_fill.svg(중앙) + mapMarker_stroke.svg(테두리)로 재고별 색상 + 중앙 숫자 생성.
class MapMarkerSvgBuilder {
  static const String _assetPathFill = 'assets/icon/mapMarker_fill.svg';
  static const String _assetPathStroke = 'assets/icon/mapMarker_stroke.svg';
  static const int _width = 56;
  static const int _height = 66;
  /// 고해상도 화면에서 텍스트 선명도를 위해 2배 해상도로 렌더링
  static const int _pixelRatio = 2;

  static ui.Picture? _cachedPictureFill;
  static ui.Picture? _cachedPictureStroke;

  /// 100~51 초록, 50~31 주황, 30~0 빨강
  static Color colorForRemain(int remain) {
    if (remain <= 30) return AppColors.error;
    if (remain <= 50) return AppColors.orange;
    return AppColors.success;
  }

  static Future<ui.Picture?> _loadSvgPicture(String path) async {
    try {
      final svgString = await rootBundle.loadString(path);
      final pictureInfo = await vg.loadPicture(
        SvgStringLoader(svgString),
        null,
      );
      return pictureInfo.picture;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _ensurePictures() async {
    _cachedPictureFill ??= await _loadSvgPicture(_assetPathFill);
    _cachedPictureStroke ??= await _loadSvgPicture(_assetPathStroke);
  }

  /// store.remain 기준 중앙만 색 + 흰색 테두리 + 중앙 숫자로 마커 이미지 생성.
  static Future<MarkerIcon> buildMarkerIcon(int remain) async {
    await _ensurePictures();
    final pictureFill = _cachedPictureFill;
    if (pictureFill == null) {
      return MarkerIcon.fromNetwork(''); // fallback: 플러그인 기본 마커
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(_pixelRatio.toDouble());

    final color = colorForRemain(remain);
    // 1) 그림자: fill 모양을 살짝 아래오른쪽으로 흐리게
    canvas.saveLayer(
      Rect.fromLTWH(-4, -4, _width + 8.0, _height + 8.0),
      Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
    );
    canvas.save();
    canvas.translate(2, 3);
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, _width.toDouble(), _height.toDouble()),
      Paint()..colorFilter = ColorFilter.mode(AppColors.black.withValues(alpha: 0.31), BlendMode.srcIn),
    );
    canvas.drawPicture(pictureFill);
    canvas.restore();
    canvas.restore(); // translate 해제
    canvas.restore(); // blur 레이어
    // 2) 중앙 fill만 재고 색상으로 칠함
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, _width.toDouble(), _height.toDouble()),
      Paint()..colorFilter = ColorFilter.mode(color, BlendMode.srcIn),
    );
    canvas.drawPicture(pictureFill);
    canvas.restore();
    // 3) 테두리는 흰색 유지 (stroke 전용 SVG 그대로 그림)
    final pictureStroke = _cachedPictureStroke;
    if (pictureStroke != null) {
      canvas.drawPicture(pictureStroke);
    }

    // 4) 중앙 숫자 (2배 해상도에 맞춰 폰트도 확대 → 선명하게)
    final textPainter = TextPainter(
      text: TextSpan(
        text: remain.toString(),
        style: TextStyle(
          fontSize: 6.0 * _pixelRatio,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
          fontFamily: AppTypography.fontFamily,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: _width.toDouble());

    const double textOffsetY = -3; // 픽셀 위로
    final centerX = _width / 2.0;
    final centerY = _height / 2.0 + textOffsetY;
    // 픽셀 경계에 맞춰 그려서 텍스트 선명도 확보
    final textX = (centerX - textPainter.width / 2).roundToDouble();
    final textY = (centerY - textPainter.height / 2).roundToDouble();
    textPainter.paint(canvas, Offset(textX, textY));

    final outPicture = recorder.endRecording();
    final image = await outPicture.toImage(
      _width * _pixelRatio,
      _height * _pixelRatio,
    );
    outPicture.dispose();

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    final dataUrl = 'data:image/png;base64,${base64Encode(bytes)}';
    return MarkerIcon.fromNetwork(dataUrl);
  }
}
