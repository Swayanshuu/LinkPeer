import 'package:flutter/material.dart';

class GridLinePainter extends CustomPainter {
  final Color color;

  const GridLinePainter({this.color = const Color(0x0DFFFFFF)}); // default: white 5%

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const spacing = 28.0;

    // Vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridLinePainter oldDelegate) => oldDelegate.color != color;
}
