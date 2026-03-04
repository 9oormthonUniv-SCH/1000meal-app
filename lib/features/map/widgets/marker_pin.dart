import 'package:flutter/material.dart';

class MapMarkerPin extends StatelessWidget {
  final int count;
  final Color color;
  final double width;
  final double height;
  final double borderWidth;

  const MapMarkerPin({
    super.key,
    required this.count,
    required this.color,
    this.width = 34.34,
    this.height = 44,
    this.borderWidth = 1.07,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: MarkerPinPainter(
        count: count,
        color: color,
        borderWidth: borderWidth,
      ),
    );
  }
}

class MarkerPinPainter extends CustomPainter {
  final int count;
  final Color color;
  final double borderWidth;

  MarkerPinPainter({
    required this.count,
    required this.color,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final circleDiameter = size.width;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final pinPath = _buildPinPath(size);
    canvas.drawShadow(pinPath, const Color(0x4D000000), 10.73, true);
    canvas.drawPath(pinPath, fillPaint);
    canvas.drawPath(pinPath, strokePaint);

    // 중앙(원 부분)에 흰색으로 재고 숫자 표시
    final textPainter = TextPainter(
      text: TextSpan(
        text: count.toString(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: circleDiameter);

    final centerX = size.width / 2;
    final centerY = size.width / 2;
    final textOffset = Offset(
      centerX - textPainter.width / 2,
      centerY - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  Path _buildPinPath(Size size) {
    final width = size.width;
    final height = size.height;
    final radius = width / 2;
    final circlePath = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
      );

    final overlap = width * 0.2;
    final tailTopY = (radius * 2) - overlap;
    final tailHalfWidth = width * 0.3;
    final tailControlY = tailTopY + (height - tailTopY) * 0.55;

    final tailPath = Path()
      ..moveTo(width / 2, height)
      ..quadraticBezierTo(
        width / 2 - tailHalfWidth * 0.6,
        tailControlY,
        width / 2 - tailHalfWidth,
        tailTopY,
      )
      ..lineTo(width / 2 + tailHalfWidth, tailTopY)
      ..quadraticBezierTo(
        width / 2 + tailHalfWidth * 0.6,
        tailControlY,
        width / 2,
        height,
      )
      ..close();

    return Path.combine(PathOperation.union, circlePath, tailPath);
  }

  @override
  bool shouldRepaint(covariant MarkerPinPainter oldDelegate) {
    return oldDelegate.count != count ||
        oldDelegate.color != color ||
        oldDelegate.borderWidth != borderWidth;
  }
}
